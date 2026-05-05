## RootViewport — top-level UI container with 3 CanvasLayers.
##
## Layer 0 (UILayer): Shell (MarginContainer with theme) containing
##   TOP_STRIP, LEFT_NAV, CENTER_CONTENT/ScreenContainer, RIGHT_PANEL,
##   and BOTTOM_ACTION_BAR.
## Layer 1 (ToastLayer): P-FBK-01 toast stack.
## Layer 2 (DrawerLayer): P-NAV-04 offline settlement drawer.
## Layer 3 (ModalLayer): semi-transparent input blocker + modal container.
##
## UIManagerHost holds a reference to this node and uses its containers
## to manage screen instantiation and modal display.
class_name RootViewport
extends Control


const NAV_COLLAPSE_EFFECTIVE_WIDTH := 1600.0
const CHROME_BG := Color(0.075, 0.075, 0.078, 1.0)
const PANEL_BG := Color(0.118, 0.118, 0.125, 1.0)
const PANEL_BG_ELEVATED := Color(0.165, 0.165, 0.175, 1.0)
const PANEL_STROKE := Color(0.245, 0.245, 0.255, 1.0)
const ACCENT_GOLD := Color(0.961, 0.659, 0.078, 1.0)
const ACCENT_BLUE := Color(0.118, 0.569, 0.925, 1.0)
const SUCCESS_GREEN := Color(0.282, 0.690, 0.314, 1.0)

# --- Layer 0: UILayer children ---
@onready var shell: VBoxContainer = %Shell
@onready var top_strip: TopStripControl = %TopStrip
@onready var left_nav: PanelContainer = %LeftNav
@onready var center_content: Control = %CenterContent
@onready var screen_container: Control = %ScreenContainer
@onready var right_panel: RightPanelControl = %RightPanel
@onready var bottom_action_bar: PanelContainer = %BottomActionBar

# --- Layer 1: ToastLayer children ---
@onready var toast_stack: ToastStack = %ToastStack

# --- Layer 2: DrawerLayer children ---
@onready var offline_drawer: PanelContainer = %OfflineDrawer

# --- Layer 3: ModalLayer children ---
@onready var modal_blocker: ColorRect = %ModalBlocker
@onready var modal_container: Control = %ModalContainer

var _feedback_layer: CanvasLayer = null


func _ready() -> void:
	_configure_modal_blocker()
	_apply_shell_visual_style()
	_install_global_feedback()
	_apply_responsive_layout()
	_subscribe_events()


func _apply_shell_visual_style() -> void:
	if shell != null:
		shell.add_theme_constant_override("separation", 1)
		shell.modulate = Color.WHITE
	if top_strip != null:
		top_strip.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_STROKE, 0, 0, 0, 1))
	if left_nav != null:
		left_nav.add_theme_stylebox_override("panel", _make_panel_style(CHROME_BG, PANEL_STROKE, 0, 0, 1, 0))
	if right_panel != null:
		right_panel.add_theme_stylebox_override("panel", _make_panel_style(CHROME_BG, PANEL_STROKE, 1, 0, 0, 0))
	if bottom_action_bar != null:
		bottom_action_bar.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_STROKE, 0, 1, 0, 0))


func _make_panel_style(bg: Color, stroke: Color, left: int = 1, top: int = 1, right: int = 1, bottom: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = stroke
	style.border_width_left = left
	style.border_width_top = top
	style.border_width_right = right
	style.border_width_bottom = bottom
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _install_global_feedback() -> void:
	_feedback_layer = CanvasLayer.new()
	_feedback_layer.name = "FeedbackLayer"
	_feedback_layer.layer = 4
	add_child(_feedback_layer)
	_connect_feedback_recursive(self)
	child_entered_tree.connect(_on_child_entered_tree)


func _on_child_entered_tree(node: Node) -> void:
	_connect_feedback_recursive(node)


func _connect_feedback_recursive(node: Node) -> void:
	if node is Button:
		_connect_button_feedback(node as Button)
	for child in node.get_children():
		_connect_feedback_recursive(child)


func _connect_button_feedback(button: Button) -> void:
	if bool(button.get_meta("omx_feedback_connected", false)):
		return
	button.set_meta("omx_feedback_connected", true)
	button.pressed.connect(_on_global_button_pressed.bind(button))
	button.mouse_entered.connect(_on_global_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_global_button_hovered.bind(button, false))


func _on_global_button_pressed(button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2(0.96, 0.96)
	button.modulate = Color(1.10, 1.08, 0.96, 1.0)
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.14).set_ease(Tween.EASE_OUT)


func _on_global_button_hovered(button: Button, hovered: bool) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var target := Vector2(1.015, 1.015) if hovered else Vector2.ONE
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target, 0.08).set_ease(Tween.EASE_OUT)


## Configure the modal blocker ColorRect: semi-transparent black
## that captures all input when a modal is open.
func _configure_modal_blocker() -> void:
	modal_blocker.color = Color(0, 0, 0, 0.35)
	modal_blocker.hide()
	modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_blocker.gui_input.connect(_on_modal_blocker_input)


## When the modal blocker is clicked (not on a modal child), do nothing.
## The ESC/B keybinding in BaseModal handles dismiss — clicking the
## backdrop is intentionally a no-op per P-INP-02 spec.
func _on_modal_blocker_input(event: InputEvent) -> void:
	# Accept the event to prevent it reaching lower layers,
	# but do NOT close the modal — only ESC/B dismisses.
	pass


## Toggle the LEFT NAV collapse/expand via F key or Gamepad RT.
## Listens for ui_toggle_nav action and delegates to left_nav.gd.
func _apply_responsive_layout() -> void:
	# Apply responsive layout adjustments based on effective window width.
	# UI scale > 100% reduces the useful content width even on 1080p panels.
	if _effective_window_width() < NAV_COLLAPSE_EFFECTIVE_WIDTH:
		_try_collapse_nav()


func _effective_window_width() -> float:
	var window_size := get_window().size
	if window_size.x <= 0:
		window_size = Vector2i(get_viewport().get_visible_rect().size)
	var scale := 1.0
	var scale_settings := UIScaleSettings.get_instance()
	if scale_settings != null:
		scale = maxf(1.0, scale_settings.get_ui_scale_multiplier())
	return float(window_size.x) / scale


func _try_collapse_nav() -> void:
	if left_nav != null and left_nav.has_method("collapse"):
		left_nav.collapse()


## --- Public API for UIManagerHost ---

## Returns the ScreenContainer where screen scenes are added.
func get_screen_container() -> Control:
	return screen_container


## Returns the ModalContainer where modal popups are added.
func get_modal_container() -> Control:
	return modal_container


## Show the modal blocker overlay.
func show_modal_blocker() -> void:
	modal_blocker.show()


## Hide the modal blocker overlay.
func hide_modal_blocker() -> void:
	modal_blocker.hide()


## Returns the ToastStack container for toast messages.
func get_toast_stack() -> VBoxContainer:
	return toast_stack


## Show a toast message via P-FBK-01 toast stack.
func show_toast(message: String, duration: float = 4.0) -> void:
	if toast_stack != null and toast_stack.has_method("push_toast"):
		toast_stack.push_toast(message, duration)


func show_typed_toast(kind: String, message: String, payload: Dictionary = {}, duration: float = 4.0) -> void:
	if toast_stack != null and toast_stack.has_method("push_typed_toast"):
		toast_stack.push_typed_toast(kind, message, payload, duration)


## Returns the LEFT NAV panel for width toggling.
func get_left_nav() -> PanelContainer:
	return left_nav


## Returns the TOP STRIP for resource display.
func get_top_strip() -> PanelContainer:
	return top_strip


## Returns the RIGHT PANEL for battle log.
func get_right_panel() -> PanelContainer:
	return right_panel


func get_offline_drawer() -> PanelContainer:
	return offline_drawer


func show_offline_drawer(summary: Dictionary = {}) -> void:
	if offline_drawer == null:
		return
	if not summary.is_empty():
		offline_drawer.call("apply_summary", summary)
	offline_drawer.call("show_drawer")


func toggle_offline_drawer() -> void:
	if offline_drawer != null:
		offline_drawer.call("toggle_drawer")


## Toggle LEFT NAV expanded/collapsed state.
func toggle_nav() -> void:
	if left_nav != null and left_nav.has_method("toggle"):
		left_nav.toggle()


func _subscribe_events() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.subscribe("offline.settled", _on_offline_settled)
	bus.subscribe("ui.scale_changed", _on_presentation_layout_changed)
	bus.subscribe("ui.resolution_changed", _on_presentation_layout_changed)
	bus.subscribe("level.changed", _on_level_feedback)
	bus.subscribe("realm.advanced", _on_realm_feedback)


func _on_offline_settled(payload: Dictionary) -> void:
	show_offline_drawer(payload)
	show_typed_toast("offline", tr("离线收益已结算"), payload, 4.0)


func _on_presentation_layout_changed(_payload: Dictionary) -> void:
	_apply_responsive_layout()


func _on_level_feedback(payload: Dictionary) -> void:
	var new_level := int(payload.get("new_level", payload.get("level", 1)))
	_show_milestone_feedback(tr("等级提升"), "Lv.%d" % new_level, ACCENT_BLUE)


func _on_realm_feedback(payload: Dictionary) -> void:
	var new_realm := tr(str(payload.get("new_realm", "")))
	if new_realm.is_empty():
		new_realm = tr("新境界")
	_show_milestone_feedback(tr("境界突破"), new_realm, ACCENT_GOLD)


func _show_milestone_feedback(title: String, subtitle: String, accent: Color) -> void:
	if _feedback_layer == null:
		return
	var panel := PanelContainer.new()
	panel.name = "MilestoneFeedback"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_top = 0.22
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.22
	panel.offset_left = -180.0
	panel.offset_top = -54.0
	panel.offset_right = 180.0
	panel.offset_bottom = 54.0
	panel.scale = Vector2(0.86, 0.86)
	panel.modulate = Color(1, 1, 1, 0)

	var style := _make_panel_style(PANEL_BG_ELEVATED, accent, 2, 2, 2, 2)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.89, 0.88, 0.84))
	box.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 34)
	subtitle_label.add_theme_color_override("font_color", accent)
	box.add_child(subtitle_label)

	_feedback_layer.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.12).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.05)
	tween.tween_property(panel, "offset_top", -82.0, 0.25).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(panel.queue_free)
