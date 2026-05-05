class_name UIScaleSettings
extends Node

signal ui_scale_changed(multiplier: float)
signal resolution_changed(resolution: Vector2i)

const DESIGN_SIZE := Vector2i(1280, 720)
const SUPPORTED_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
const DEFAULT_UI_SCALE := 1.0
const MIN_UI_SCALE := 1.0
const MAX_UI_SCALE := 1.5
const UI_SCALE_STEP := 0.05
const CONFIG_PATH := "user://ui_settings.cfg"
const CONFIG_SECTION := "presentation"
const CONFIG_KEY_UI_SCALE := "ui_scale_multiplier"
const CONFIG_KEY_WINDOW_WIDTH := "window_width"
const CONFIG_KEY_WINDOW_HEIGHT := "window_height"
const MAX_WINDOW_MODE_RETRIES := 10

static var instance: UIScaleSettings

var _ui_scale_multiplier := DEFAULT_UI_SCALE
var _window_size := Vector2i.ZERO
var _has_saved_window_size := false
var _persistence_enabled := true


func _ready() -> void:
	var existing := get_instance()
	if existing != null and existing != self:
		queue_free()
		return
	instance = self
	_load_settings()
	if _has_saved_window_size:
		apply_window_size(false)
	apply_ui_scale()


func _exit_tree() -> void:
	if instance == self:
		instance = null


static func get_instance() -> UIScaleSettings:
	if instance != null and not is_instance_valid(instance):
		instance = null
	return instance


func get_ui_scale_multiplier() -> float:
	return _ui_scale_multiplier


func get_window_size() -> Vector2i:
	if _window_size != Vector2i.ZERO:
		return _window_size
	var window := get_window()
	if window == null:
		return SUPPORTED_RESOLUTIONS[1]
	return window.size


func get_resolution_index() -> int:
	var current := _normalize_resolution(get_window_size())
	for i in range(SUPPORTED_RESOLUTIONS.size()):
		if SUPPORTED_RESOLUTIONS[i] == current:
			return i
	return 1


func is_persistence_enabled() -> bool:
	return _persistence_enabled


func set_persistence_enabled(enabled: bool) -> void:
	_persistence_enabled = enabled


func set_ui_scale_multiplier(value: float, persist: bool = true) -> void:
	var normalized := _normalize_scale(value)
	if is_equal_approx(_ui_scale_multiplier, normalized):
		apply_ui_scale()
		return

	_ui_scale_multiplier = normalized
	apply_ui_scale()
	if persist:
		_save_settings()
	ui_scale_changed.emit(_ui_scale_multiplier)
	_emit_scale_event()


func set_window_size(size: Vector2i, persist: bool = true) -> void:
	var normalized := _normalize_resolution(size)
	if _window_size == normalized and _has_saved_window_size:
		apply_window_size()
		return

	_window_size = normalized
	_has_saved_window_size = true
	apply_window_size()
	apply_ui_scale()
	if persist:
		_save_settings()
	resolution_changed.emit(_window_size)
	_emit_resolution_event()


func reset_ui_scale(persist: bool = true) -> void:
	set_ui_scale_multiplier(DEFAULT_UI_SCALE, persist)


func apply_window_size(center_window: bool = true) -> void:
	var window := get_window()
	if window == null or _window_size == Vector2i.ZERO:
		return
	if _is_headless_display():
		window.size = _window_size
		return
	var window_id := window.get_window_id()
	if DisplayServer.window_get_mode(window_id) != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
		_defer_window_size_apply(center_window, 1)
		return
	_apply_window_size_now(center_window)


func _apply_window_size_deferred(center_window: bool = true, attempt: int = 0) -> void:
	var window := get_window()
	if window == null or _window_size == Vector2i.ZERO:
		return
	if _is_headless_display():
		window.size = _window_size
		return
	var window_id := window.get_window_id()
	if DisplayServer.window_get_mode(window_id) != DisplayServer.WINDOW_MODE_WINDOWED:
		if attempt >= MAX_WINDOW_MODE_RETRIES:
			push_warning("UIScaleSettings: timed out waiting for windowed mode before resizing to %s" % str(_window_size))
			return
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
		_defer_window_size_apply(center_window, attempt + 1)
		return
	_apply_window_size_now(center_window)


func _apply_window_size_now(center_window: bool = true) -> void:
	var window := get_window()
	if window == null or _window_size == Vector2i.ZERO:
		return
	if _is_headless_display():
		window.size = _window_size
		return
	var window_id := window.get_window_id()
	DisplayServer.window_set_size(_window_size, window_id)
	window.size = _window_size
	if center_window and DisplayServer.get_name().to_lower() != "headless" and window.has_method("move_to_center"):
		window.call_deferred("move_to_center")


func _defer_window_size_apply(center_window: bool, attempt: int) -> void:
	var tree := get_tree()
	if tree == null:
		call_deferred("_apply_window_size_deferred", center_window, attempt)
		return
	var callback := Callable(self, "_apply_window_size_deferred").bind(center_window, attempt)
	if not tree.process_frame.is_connected(callback):
		tree.process_frame.connect(callback, CONNECT_ONE_SHOT)


func apply_ui_scale() -> void:
	var window := get_window()
	if window == null:
		return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = DESIGN_SIZE
	window.content_scale_factor = _ui_scale_multiplier
	call_deferred("_refresh_ui_layout")


func get_logical_size() -> Vector2i:
	return DESIGN_SIZE


func _normalize_scale(value: float) -> float:
	var clamped := clampf(value, MIN_UI_SCALE, MAX_UI_SCALE)
	return snappedf(clamped, UI_SCALE_STEP)


func _normalize_resolution(size: Vector2i) -> Vector2i:
	if size.x <= 0 or size.y <= 0:
		return SUPPORTED_RESOLUTIONS[1]
	for resolution in SUPPORTED_RESOLUTIONS:
		if resolution == size:
			return resolution

	var best: Vector2i = SUPPORTED_RESOLUTIONS[0]
	var best_distance := INF
	for resolution in SUPPORTED_RESOLUTIONS:
		var distance := absf(float(resolution.x - size.x)) + absf(float(resolution.y - size.y))
		if distance < best_distance:
			best = resolution
			best_distance = distance
	return best


func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		_ui_scale_multiplier = DEFAULT_UI_SCALE
		return
	_ui_scale_multiplier = _normalize_scale(float(config.get_value(CONFIG_SECTION, CONFIG_KEY_UI_SCALE, DEFAULT_UI_SCALE)))
	if config.has_section_key(CONFIG_SECTION, CONFIG_KEY_WINDOW_WIDTH) and config.has_section_key(CONFIG_SECTION, CONFIG_KEY_WINDOW_HEIGHT):
		_window_size = _normalize_resolution(Vector2i(
			int(config.get_value(CONFIG_SECTION, CONFIG_KEY_WINDOW_WIDTH, SUPPORTED_RESOLUTIONS[1].x)),
			int(config.get_value(CONFIG_SECTION, CONFIG_KEY_WINDOW_HEIGHT, SUPPORTED_RESOLUTIONS[1].y))
		))
		_has_saved_window_size = true


func _save_settings() -> void:
	if not _persistence_enabled:
		return
	var config := ConfigFile.new()
	var _load_err := config.load(CONFIG_PATH)
	config.set_value(CONFIG_SECTION, CONFIG_KEY_UI_SCALE, _ui_scale_multiplier)
	if _has_saved_window_size:
		config.set_value(CONFIG_SECTION, CONFIG_KEY_WINDOW_WIDTH, _window_size.x)
		config.set_value(CONFIG_SECTION, CONFIG_KEY_WINDOW_HEIGHT, _window_size.y)
	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_warning("UIScaleSettings: failed to save %s, error %d" % [CONFIG_PATH, err])


func _emit_scale_event() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.emit("ui.scale_changed", {
		"multiplier": _ui_scale_multiplier,
		"logical_size": get_logical_size(),
	})


func _emit_resolution_event() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.emit("ui.resolution_changed", {
		"resolution": _window_size,
	})


func _refresh_ui_layout() -> void:
	var root_viewport := UIManagerHost.find_root_viewport()
	if root_viewport == null:
		return
	root_viewport.minimum_size_changed.emit()
	root_viewport.queue_redraw()


func _is_headless_display() -> bool:
	return DisplayServer.get_name().to_lower() == "headless"
