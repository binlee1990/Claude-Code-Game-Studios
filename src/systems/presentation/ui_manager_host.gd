## UIManagerHost — autoload Node that bridges UIManager (RefCounted service)
## to the RootViewport scene tree.
##
## Owns screen instantiation (load().instantiate(), add_child(), show/hide),
## modal display, keyboard shortcut routing, and lifecycle event emission.
## The UIManager service handles metadata, unlock logic, and modal depth.
class_name UIManagerHost
extends Node


static var instance: UIManagerHost

var service := UIManager.new()
var ui_scale_settings: UIScaleSettings = null

# Reference to RootViewport (set after main scene loads).
var _root_viewport: RootViewport = null

# Cache of loaded PackedScene resources.
var _scene_cache: Dictionary = {}

# Track current screen node for show/hide switching.
var _current_screen_node: BaseScreen = null

# Track if post-initialization has run.
var _post_init_done: bool = false
var _post_init_attempts: int = 0
const MAX_POST_INIT_ATTEMPTS := 30


func _ready() -> void:
	if instance == null:
		instance = self

	_ensure_ui_scale_settings()

	# Register all 5 MVP screens with FTUE-aware unlock conditions.
	# Cultivation and save are always available; combat/resources/offline
	# unlock progressively per screen-flow.md §3.
	service.register_screen("cultivation",        "res://src/ui/screens/cultivation_screen.tscn", true)
	service.register_screen("combat",             "res://src/ui/screens/combat_screen.tscn", _ftue_unlocked(1))
	service.register_screen("resources",          "res://src/ui/screens/resources_screen.tscn", _ftue_unlocked(2))
	service.register_screen("save",               "res://src/ui/screens/save_screen.tscn", true)
	service.register_screen("offline_settlement", "res://src/ui/screens/offline_settlement_screen.tscn", _ftue_unlocked(5))
	service.register_screen("settings",           "res://src/ui/modals/settings_modal.tscn", true)
	service.register_screen("confirm_critical",   "res://src/ui/modals/confirm_critical_modal.tscn", true)
	service.register_screen("stance_select",      "res://src/ui/modals/stance_select_modal.tscn", _ftue_unlocked(4))

	# Defer post-init until main scene is loaded.
	_schedule_post_initialize()


func _ensure_ui_scale_settings() -> void:
	var existing := UIScaleSettings.get_instance()
	if existing != null:
		ui_scale_settings = existing
		return
	ui_scale_settings = UIScaleSettings.new()
	ui_scale_settings.name = "UIScaleSettings"
	add_child(ui_scale_settings)


func _schedule_post_initialize() -> void:
	var tree := get_tree()
	if tree == null:
		call_deferred("_post_initialize")
		return
	var callback := Callable(self, "_post_initialize")
	if not tree.process_frame.is_connected(callback):
		tree.process_frame.connect(callback, CONNECT_ONE_SHOT)


## Called deferred after main scene is in the tree.
func _post_initialize() -> void:
	if _post_init_done:
		return

	_root_viewport = _find_root_viewport()
	if _root_viewport == null:
		_post_init_attempts += 1
		if _post_init_attempts >= MAX_POST_INIT_ATTEMPTS:
			push_warning("UIManagerHost: RootViewport not found after deferred retries. UI will be degraded.")
		else:
			_schedule_post_initialize()
		return

	_post_init_done = true
	_setup_input_handling()

	# Open the default first screen (cultivation per spec).
	open_screen("cultivation")


func _find_root_viewport() -> RootViewport:
	# Search the main scene for RootViewport.
	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node == null:
		# Fallback: search entire tree.
		for child in get_tree().root.get_children():
			if child is RootViewport:
				return child as RootViewport
		return null

	for child in main_node.get_children():
		if child is RootViewport:
			return child as RootViewport
	return null


static func get_instance() -> UIManagerHost:
	return instance


static func find_root_viewport() -> RootViewport:
	if instance == null:
		return null
	return instance._find_root_viewport()


static func has_open_modal() -> bool:
	return instance != null and instance.service.has_open_modal()


## Returns a Callable that checks if FTUE stage >= required_stage.
func _ftue_unlocked(required_stage: int) -> Callable:
	return func() -> bool:
		var ftue_host := FTUEStateMachineHost.get_instance()
		if ftue_host == null:
			return true  # fallback: allow if FTUE system not ready
		return ftue_host.get_service().get_stage() >= required_stage


func get_service() -> UIManager:
	return service


# ---------------------------------------------------------------------------
# Screen navigation (scene-tree aware)
# ---------------------------------------------------------------------------

## Open a registered screen. Handles validation, scene loading,
## instantiation, and show/hide lifecycle.
func open_screen(screen_id: String) -> void:
	if _root_viewport == null:
		push_warning("UIManagerHost: RootViewport not available")
		return

	# Validate via service (backward-compatible dict path).
	var result: Dictionary = service.open_screen(screen_id)
	if not bool(result.get("ok", false)):
		push_warning("UIManagerHost: cannot open screen '%s': %s" % [screen_id, result.get("reason", "unknown")])
		return

	# Deactivate current screen.
	if _current_screen_node != null:
		_current_screen_node.on_deactivated()
		_current_screen_node.hide()
		_current_screen_node.process_mode = PROCESS_MODE_DISABLED

	# Ensure target screen is loaded and instantiated.
	var target := _ensure_screen_loaded(screen_id)
	if target == null:
		push_warning("UIManagerHost: failed to load screen '%s'" % screen_id)
		return

	# Activate target.
	target.show()
	target.process_mode = PROCESS_MODE_INHERIT
	target.on_activated()
	_current_screen_node = target

	# Emit event.
	_emit_event("ui.screen_opened", {"screen_id": screen_id})


## Close a screen (hide it). If it's the current screen, fall back to default.
func close_screen(screen_id: String = "") -> void:
	var target_id := screen_id
	if target_id.is_empty():
		target_id = service.active_screen_id

	var node := service.get_screen_instance(target_id) as BaseScreen
	if node != null:
		node.on_deactivated()
		node.hide()
		node.process_mode = PROCESS_MODE_DISABLED

	if target_id == service.active_screen_id:
		# Fall back to cultivation as default.
		open_screen("cultivation")

	_emit_event("ui.screen_closed", {"screen_id": target_id})


## Replace the current screen entirely (removes from tree).
func replace_screen(screen_id: String) -> void:
	var old_id := service.active_screen_id
	var old_node := _current_screen_node

	# Remove old screen.
	if old_node != null:
		old_node.on_removed()
		old_node.queue_free()
		service.clear_screen_instance(old_id)
		_current_screen_node = null

	open_screen(screen_id)


# ---------------------------------------------------------------------------
# Modal management (scene-tree aware)
# ---------------------------------------------------------------------------

## Open a registered modal by screen_id. Instantiates into ModalContainer.
func open_modal(screen_id: String, payload: Dictionary = {}) -> void:
	if _root_viewport == null:
		return

	# Check depth limit.
	if not service.open_modal(screen_id):
		return

	var modal_container := _root_viewport.get_modal_container()
	if modal_container == null:
		_rollback_modal_open()
		return

	var scene_path := service.get_screen_path(screen_id)
	if scene_path.is_empty():
		_rollback_modal_open()
		return

	var modal_scene := _load_scene(scene_path)
	if modal_scene == null:
		_rollback_modal_open()
		return

	var modal := modal_scene.instantiate()
	if not modal is BaseModal:
		push_warning("UIManagerHost: modal '%s' does not extend BaseModal" % screen_id)
		modal.queue_free()
		_rollback_modal_open()
		return

	_configure_modal(modal as BaseModal, payload)
	modal_container.add_child(modal)
	service.set_modal_node(screen_id, modal)

	_root_viewport.show_modal_blocker()
	(modal as BaseModal).open(payload)


## Close the topmost modal.
func close_modal() -> void:
	var closed_id := service.close_modal()
	if closed_id.is_empty():
		return

	if _root_viewport == null:
		return

	var modal_container := _root_viewport.get_modal_container()
	if modal_container == null:
		return

	for child in modal_container.get_children():
		if child is BaseModal:
			(child as BaseModal).close()
			child.queue_free()

	if not service.has_open_modal():
		_root_viewport.hide_modal_blocker()


func go_back() -> void:
	open_screen("cultivation")


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Ensure a screen scene is loaded, instantiated, and added to the ScreenContainer.
func _ensure_screen_loaded(screen_id: String) -> BaseScreen:
	# Check cache first.
	var existing := service.get_screen_instance(screen_id) as BaseScreen
	if existing != null:
		return existing

	var scene_path := service.get_screen_path(screen_id)
	if scene_path.is_empty():
		return null

	var packed := _load_scene(scene_path)
	if packed == null:
		return null

	var screen_container := _root_viewport.get_screen_container()
	if screen_container == null:
		return null

	var instance := packed.instantiate()
	if not instance is BaseScreen:
		push_warning("UIManagerHost: screen '%s' does not extend BaseScreen" % screen_id)
		instance.queue_free()
		return null

	screen_container.add_child(instance)
	instance.hide()
	instance.process_mode = PROCESS_MODE_DISABLED
	service.set_screen_instance(screen_id, instance)

	return instance as BaseScreen


## Load a PackedScene from path, using cache.
func _load_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene

	if not ResourceLoader.exists(path):
		push_warning("UIManagerHost: scene not found: %s" % path)
		return null

	var res := load(path) as PackedScene
	if res != null:
		_scene_cache[path] = res
	return res


func _rollback_modal_open() -> void:
	service.close_modal()
	if _root_viewport != null and not service.has_open_modal():
		_root_viewport.hide_modal_blocker()


## Configure modal blocker and focus.
func _configure_modal(modal: BaseModal, payload: Dictionary) -> void:
	modal.payload = payload


## Emit a UI event through EventBus.
func _emit_event(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)


## Set up global input handling (ESC key, keyboard shortcuts 1-5).
func _setup_input_handling() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	# ESC: close topmost modal, or open settings if no modal.
	if _is_action_pressed(event, "ui_cancel"):
		if service.has_open_modal():
			close_modal()
		else:
			open_modal("settings")
		get_viewport().set_input_as_handled()
		return

	# Keyboard shortcuts 1-5 for screens.
	if _is_action_pressed(event, "ui_screen_1"):
		open_screen("cultivation")
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, "ui_screen_2"):
		open_screen("combat")
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, "ui_screen_3"):
		open_screen("resources")
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, "ui_screen_4"):
		open_screen("save")
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, "ui_screen_5"):
		open_screen("offline_settlement")
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, "ui_toggle_nav"):
		if _root_viewport != null:
			_root_viewport.toggle_nav()
		get_viewport().set_input_as_handled()


func _is_action_pressed(event: InputEvent, action_name: String) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)
