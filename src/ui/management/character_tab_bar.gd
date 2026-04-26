class_name CharacterTabBar
extends HBoxContainer

## Reusable tab bar component for character management screens.
## Supports tabs: character / party / equipment / skills
## MGMT-003 will extend this pattern for unified tab navigation.

signal tab_selected(tab_key: String)

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")

var _tab_buttons: Dictionary = {}
var _active_tab: String = ""
var _tab_keys: Array[String] = []
var _ui_scale: float = 1.0

func set_ui_scale(scale: float) -> void:
	_ui_scale = clampf(scale, 1.0, 1.3)
	for key in _tab_buttons:
		var btn: Button = _tab_buttons[key]
		SRPGTheme.apply_button_scaled(btn, _ui_scale, key == _active_tab, false, true)

func initialize(tab_keys: Array[String]) -> void:
	_tab_keys = tab_keys
	for key in tab_keys:
		var btn := Button.new()
		btn.text = _get_tab_label(key)
		btn.focus_mode = Control.FOCUS_ALL
		SRPGTheme.apply_button_scaled(btn, _ui_scale, false, false, true)
		btn.pressed.connect(_on_tab_pressed.bind(key))
		add_child(btn)
		_tab_buttons[key] = btn
	if not tab_keys.is_empty():
		set_active_tab(tab_keys[0])

func set_active_tab(tab_key: String, emit_selected: bool = false) -> void:
	if not _tab_buttons.has(tab_key):
		return
	if _active_tab == tab_key and not emit_selected:
		return
	_active_tab = tab_key
	for key in _tab_buttons:
		var btn: Button = _tab_buttons[key]
		SRPGTheme.apply_button_scaled(btn, _ui_scale, key == tab_key, false, true)
	if emit_selected:
		tab_selected.emit(tab_key)

func get_active_tab() -> String:
	return _active_tab

func _get_tab_label(key: String) -> String:
	match key:
		"character":
			return "角色"
		"party":
			return "编队"
		"equipment":
			return "装备"
		"skills":
			return "技能"
		_:
			return key

func _on_tab_pressed(tab_key: String) -> void:
	set_active_tab(tab_key, true)
