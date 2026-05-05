## LEFT NAV — 5-tab side navigation bar.
##
## Attached to the LeftNav PanelContainer inside RootViewport.Shell.
## Manages 5 tab buttons: 修炼/战斗/资源/存档/离线.
## Supports expand (192px) / collapse (48px) via Tween animation.
## Highlights the active tab with left 4px burst_gold strip.
class_name LeftNavControl
extends PanelContainer


const TAB_DEFINITIONS: Array[Dictionary] = [
	{"id": "cultivation",        "label": "修炼", "shortcut": "ui_screen_1", "icon_fallback": "res://assets/ui/icons/stances/meditate.png"},
	{"id": "combat",             "label": "战斗", "shortcut": "ui_screen_2", "icon_fallback": "res://assets/ui/icons/status/combat_active.png"},
	{"id": "resources",          "label": "资源", "shortcut": "ui_screen_3", "icon_fallback": "res://assets/ui/icons/resources/lingshi.png"},
	{"id": "save",               "label": "存档", "shortcut": "ui_screen_4", "icon_fallback": "res://assets/ui/icons/realm/mortal.png"},
	{"id": "offline_settlement", "label": "离线", "shortcut": "ui_screen_5", "icon_fallback": "res://assets/ui/icons/status/offline_pending.png"},
]

const EXPANDED_WIDTH: int = 192
const COLLAPSED_WIDTH: int = 48
const TAB_HEIGHT: int = 48
const ICON_SIZE: int = 24
const TOGGLE_DURATION: float = 0.15

var _tab_buttons: Array[PanelContainer] = []
var _tab_labels: Array[Label] = []
var _nav_expanded: bool = true
var _nav_tween: Tween = null
var _active_screen_id: String = "cultivation"


func _ready() -> void:
	_build_tabs()
	_connect_signals()
	_apply_active_highlight()


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


## Get the VBoxContainer child of this PanelContainer.
func _get_content_vbox() -> VBoxContainer:
	for child in get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


## Connect UIManager screen_changed signal for highlight tracking.
## Also subscribe to keyboard shortcut actions.
func _connect_signals() -> void:
	# Listen for screen changes to update active highlight.
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("ui.screen_opened", _on_screen_opened)


## Handle click/enter on a tab wrapper.
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


## Navigate to a screen via UIManager.
func _navigate_to(screen_id: String) -> void:
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
	style.bg_color = Color(0.18, 0.18, 0.235)  # ~panel_bg_elevated
	style.set_border_width_all(0)
	style.border_width_left = 4
	style.border_color = Color(0.961, 0.784, 0.259)  # burst_gold #F5C842
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
