## LEFT NAV — 5-tab side navigation bar with progressive unlock.
##
## Attached to the LeftNav PanelContainer inside RootViewport.Shell.
## Manages 5 tab buttons: 修炼/战斗/资源/存档/离线.
## Supports expand (192px) / collapse (48px) via Tween animation.
## Highlights the active tab with left 4px burst_gold strip.
##
## Tab visibility follows screen-flow.md §4 state machine:
##   VISIBLE_ACTIVE — tab is shown and clickable
##   VISIBLE_LOCKED  — tab is shown but greyed out; hover shows unlock condition
##   HIDDEN          — tab is not rendered, waiting for FTUE stage unlock

class_name LeftNavControl
extends PanelContainer


enum TabState { VISIBLE_ACTIVE, VISIBLE_LOCKED, HIDDEN }

const TAB_DEFINITIONS: Array[Dictionary] = [
	{"id": "cultivation",        "label": "修炼", "shortcut": "ui_screen_1", "icon_fallback": "res://assets/ui/icons/stances/meditate.png",      "unlock_stage": 0, "unlock_hint": ""},
	{"id": "combat",             "label": "战斗", "shortcut": "ui_screen_2", "icon_fallback": "res://assets/ui/icons/status/combat_active.png",    "unlock_stage": 1, "unlock_hint": "灵气感知到山中有异动"},
	{"id": "resources",          "label": "资源", "shortcut": "ui_screen_3", "icon_fallback": "res://assets/ui/icons/resources/lingshi.png",        "unlock_stage": 2, "unlock_hint": "捡到第一片灵草后解锁"},
	{"id": "save",               "label": "存档", "shortcut": "ui_screen_4", "icon_fallback": "res://assets/ui/icons/realm/mortal.png",            "unlock_stage": 0, "unlock_hint": ""},
	{"id": "offline_settlement", "label": "离线", "shortcut": "ui_screen_5", "icon_fallback": "res://assets/ui/icons/status/offline_pending.png",  "unlock_stage": 5, "unlock_hint": "闭关归来后解锁"},
]

const EXPANDED_WIDTH: int = 192
const COLLAPSED_WIDTH: int = 48
const TAB_HEIGHT: int = 48
const ICON_SIZE: int = 24
const LOCK_ICON_SIZE: int = 16
const TOGGLE_DURATION: float = 0.15

var _tab_buttons: Array[PanelContainer] = []
var _tab_labels: Array[Label] = []
var _tab_states: Array[int] = []  # TabState per tab index
var _nav_expanded: bool = true
var _nav_tween: Tween = null
var _active_screen_id: String = "cultivation"
var _ftue_stage: int = 0


func _ready() -> void:
	_build_tabs()
	_connect_signals()
	_apply_active_highlight()
	_subscribe_ftue()
	_update_all_tab_states()


## Build all 5 tab rows programmatically inside our VBoxContainer.
func _build_tabs() -> void:
	var vbox := _get_content_vbox()
	if vbox == null:
		return
	# Clear placeholder label.
	for child in vbox.get_children():
		child.queue_free()

	for tab_def in TAB_DEFINITIONS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, TAB_HEIGHT)
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		# Icon
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = tab_def.get("icon_fallback", "")
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path) as Texture2D
		row.add_child(icon)

		# Text label
		var label := Label.new()
		label.name = "Label"
		label.text = tr(tab_def.get("label", ""))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)

		# Use a reference container so the button fills the row.
		# We wrap the row in a Control that handles click.
		var wrapper := PanelContainer.new()
		wrapper.name = "TabWrapper"
		wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		wrapper.focus_mode = Control.FOCUS_ALL
		wrapper.custom_minimum_size = Vector2(0, TAB_HEIGHT)
		wrapper.add_child(row)

		var screen_id: String = tab_def.get("id", "")
		wrapper.gui_input.connect(_on_tab_input.bind(screen_id))
		wrapper.focus_entered.connect(_on_tab_focus.bind(wrapper, true))
		wrapper.focus_exited.connect(_on_tab_focus.bind(wrapper, false))

		vbox.add_child(wrapper)
		_tab_buttons.append(wrapper)
		_tab_labels.append(label)
		_tab_states.append(TabState.HIDDEN)


## Get the VBoxContainer child of this PanelContainer.
func _get_content_vbox() -> VBoxContainer:
	for child in get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


func _connect_signals() -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("ui.screen_opened", _on_screen_opened)


## Subscribe to FTUE stage changes for progressive tab unlock.
func _subscribe_ftue() -> void:
	var ftue_host := FTUEStateMachineHost.get_instance()
	if ftue_host != null and ftue_host.get_service() != null:
		_ftue_stage = ftue_host.get_service().get_stage()
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("ftue.stage_changed", _on_ftue_stage_changed)


func _on_ftue_stage_changed(payload: Dictionary) -> void:
	_ftue_stage = payload.get("new_stage", _ftue_stage)
	_update_all_tab_states()


## Compute TabState for a tab index based on current FTUE stage.
func _compute_tab_state(tab_index: int) -> int:
	var required_stage: int = TAB_DEFINITIONS[tab_index].get("unlock_stage", 0)
	if _ftue_stage >= required_stage:
		return TabState.VISIBLE_ACTIVE
	return TabState.VISIBLE_LOCKED


func _update_all_tab_states() -> void:
	for i in range(TAB_DEFINITIONS.size()):
		var new_state := _compute_tab_state(i)
		_tab_states[i] = new_state
		_apply_tab_state_visual(i, new_state)


## Apply visual treatment for a tab's current state.
func _apply_tab_state_visual(tab_index: int, state: int) -> void:
	var wrapper := _tab_buttons[tab_index] as PanelContainer
	if wrapper == null:
		return
	match state:
		TabState.VISIBLE_LOCKED:
			wrapper.modulate = Color(0.4, 0.4, 0.4, 0.6)
			wrapper.tooltip_text = tr(TAB_DEFINITIONS[tab_index].get("unlock_hint", ""))
			wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
			wrapper.visible = true
		TabState.HIDDEN:
			wrapper.visible = false
		_:
			wrapper.visible = true
			wrapper.modulate = Color.WHITE
			wrapper.tooltip_text = ""
			wrapper.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_tab_input(event: InputEvent, screen_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		_navigate_to(screen_id)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_navigate_to(screen_id)


func _on_tab_focus(wrapper: PanelContainer, has_focus: bool) -> void:
	if has_focus:
		_apply_focus_style(wrapper)
	else:
		_remove_focus_style(wrapper)


## Navigate to a screen via UIManager. Respects tab lock state.
func _navigate_to(screen_id: String) -> void:
	for i in range(TAB_DEFINITIONS.size()):
		if TAB_DEFINITIONS[i].get("id", "") == screen_id:
			if _tab_states[i] == TabState.VISIBLE_LOCKED:
				_show_locked_feedback(TAB_DEFINITIONS[i].get("unlock_hint", ""))
				return
			break
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_screen(screen_id)


## Called by EventBus when a screen is opened.
func _on_screen_opened(payload: Dictionary) -> void:
	var screen_id := str(payload.get("screen_id", ""))
	if screen_id.is_empty():
		return
	_active_screen_id = screen_id
	_apply_active_highlight()


## Apply active highlight: left 4px burst_gold strip + panel_bg_elevated.
func _apply_active_highlight() -> void:
	for i in range(TAB_DEFINITIONS.size()):
		var wrapper := _tab_buttons[i]
		if wrapper == null:
			continue
		var tab_id: String = TAB_DEFINITIONS[i].get("id", "")
		if tab_id == _active_screen_id:
			var style := _make_active_stylebox()
			wrapper.add_theme_stylebox_override("panel", style)
		else:
			wrapper.remove_theme_stylebox_override("panel")


func _make_active_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.155, 0.155, 0.165)
	style.border_color = Color(0.118, 0.569, 0.925)
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _apply_focus_style(wrapper: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.border_color = Color(0.961, 0.784, 0.259)  # burst_gold
	style.bg_color = Color(0, 0, 0, 0)
	wrapper.add_theme_stylebox_override("focus", style)


func _remove_focus_style(wrapper: PanelContainer) -> void:
	wrapper.remove_theme_stylebox_override("focus")


## Toggle between expanded (192px) and collapsed (48px).
func toggle() -> void:
	_nav_expanded = not _nav_expanded
	var target_width: int = EXPANDED_WIDTH if _nav_expanded else COLLAPSED_WIDTH
	_animate_width(target_width)
	_set_labels_visible(_nav_expanded)


## Collapse the nav (e.g. for small screens).
func collapse() -> void:
	if not _nav_expanded:
		return
	_nav_expanded = false
	_animate_width(COLLAPSED_WIDTH)
	_set_labels_visible(false)


## Expand the nav.
func expand() -> void:
	if _nav_expanded:
		return
	_nav_expanded = true
	_animate_width(EXPANDED_WIDTH)
	_set_labels_visible(true)


## Check reduced motion and animate width.
func _animate_width(target: int) -> void:
	if _nav_tween != null:
		_nav_tween.kill()
	if _is_reduced_motion():
		custom_minimum_size.x = target
		return
	_nav_tween = create_tween()
	_nav_tween.tween_property(self, "custom_minimum_size:x", float(target), TOGGLE_DURATION).set_ease(Tween.EASE_OUT)


func _set_labels_visible(visible_state: bool) -> void:
	for label in _tab_labels:
		label.visible = visible_state


func _is_reduced_motion() -> bool:
	return false


func _show_locked_feedback(hint: String) -> void:
	var rv := UIManagerHost.find_root_viewport()
	if rv == null or not rv.has_method("show_typed_toast"):
		return
	var text := tr("尚未解锁")
	if not str(hint).is_empty():
		text = "%s：%s" % [text, tr(str(hint))]
	rv.show_typed_toast("locked", text, {}, 3.0)
