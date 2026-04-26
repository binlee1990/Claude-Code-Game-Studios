class_name CharacterManagement
extends Control

## Character Management screen - party organization and character details.
## Provides roster view, party adjustment (up to 4 deployed), and character detail panel.

signal closed()
signal party_changed(new_party: Array)

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const CharacterTabBar := preload("res://src/ui/management/character_tab_bar.gd")

enum Tab { CHARACTER, PARTY, EQUIPMENT, SKILLS }
const TAB_KEYS: Array[String] = ["character", "party", "equipment", "skills"]

var _roster: CharacterRoster
var _selected_unit_id: StringName = &""
var _active_tab: int = Tab.CHARACTER

# UI references
var _tab_bar: CharacterTabBar
var _left_panel: Panel
var _right_panel: Panel
var _roster_list: VBoxContainer
var _party_slots: HBoxContainer
var _detail_container: VBoxContainer
var _detail_name_label: Label
var _detail_class_label: Label
var _detail_hp_label: Label
var _detail_attr_labels: Dictionary
var _detail_skill_list: VBoxContainer
var _detail_equip_list: VBoxContainer
var _party_labels: Array[Label] = []
var _slot_buttons: Array[Button] = []
var _hint_bar: Control
var _close_button: Button
var _action_bar: HBoxContainer
var _confirm_button: Button

# Pending party changes before confirm
var _pending_party: Array = []

func _ready() -> void:
	_build_ui()
	_connect_signals()

## Initialize with an existing CharacterRoster instance.
func initialize(roster: CharacterRoster) -> void:
	_roster = roster
	_pending_party = _roster.get_party().duplicate()
	_refresh_all()

func _build_ui() -> void:
	# Blocker / backdrop
	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	# Main container
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.custom_minimum_size = Vector2(960, 540)
	root.position = Vector2(-480, -270)
	add_child(root)

	# Left panel: tab bar + roster list + party slots (helper attaches to parent)
	_left_panel = _create_left_panel(root)

	# Right panel: character detail (helper attaches to parent)
	_right_panel = _create_right_panel(root)

	# Hint bar at bottom
	_build_hint_bar()

func _create_left_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(460, 540)
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.GOLD)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Tab bar
	_tab_bar = CharacterTabBar.new()
	_tab_bar.initialize(TAB_KEYS)
	_tab_bar.tab_selected.connect(_on_tab_selected)
	vbox.add_child(_tab_bar)

	# Roster list (scrollable)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_roster_list = VBoxContainer.new()
	_roster_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_roster_list)

	# Party slots label
	var party_title := Label.new()
	party_title.text = "编队 (最多4人)"
	SRPGTheme.apply_label(party_title, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(party_title)

	# Party slots row
	_party_slots = HBoxContainer.new()
	_party_slots.add_theme_constant_override("separation", 6)
	for i in range(4):
		var slot := _create_party_slot(i)
		_party_slots.add_child(slot)
	vbox.add_child(_party_slots)

	# Action bar
	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", 8)
	_action_bar.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(_action_bar)

	_confirm_button = Button.new()
	_confirm_button.text = "确认编队"
	_confirm_button.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(_confirm_button, false, false, true)
	_confirm_button.pressed.connect(_on_confirm_party_pressed)
	_action_bar.add_child(_confirm_button)

	return panel

func _create_party_slot(index: int) -> Panel:
	var slot_panel := Panel.new()
	slot_panel.custom_minimum_size = Vector2(100, 70)
	SRPGTheme.apply_panel(slot_panel, SRPGTheme.INK_SOFT, SRPGTheme.JADE)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(label, SRPGTheme.PAPER_MUTED, 12)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_panel.add_child(label)
	_party_labels.append(label)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.pressed.connect(_on_party_slot_pressed.bind(index))
	slot_panel.add_child(btn)
	_slot_buttons.append(btn)

	return slot_panel

func _create_right_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(460, 540)
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Close button
	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(_close_button, false, false, true)
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

	# Detail container
	_detail_container = VBoxContainer.new()
	_detail_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_detail_container)

	_detail_name_label = Label.new()
	SRPGTheme.apply_label(_detail_name_label, SRPGTheme.WHITE, 22, true)
	_detail_container.add_child(_detail_name_label)

	_detail_class_label = Label.new()
	SRPGTheme.apply_label(_detail_class_label, SRPGTheme.GOLD, 16)
	_detail_container.add_child(_detail_class_label)

	_detail_hp_label = Label.new()
	SRPGTheme.apply_label(_detail_hp_label, SRPGTheme.JADE, 16)
	_detail_container.add_child(_detail_hp_label)

	# Attributes
	var attr_title := Label.new()
	attr_title.text = "属性"
	SRPGTheme.apply_label(attr_title, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(attr_title)

	var attr_grid := GridContainer.new()
	attr_grid.columns = 2
	attr_grid.add_theme_constant_override("h_separation", 12)
	attr_grid.add_theme_constant_override("v_separation", 4)
	_detail_container.add_child(attr_grid)

	for attr_name in ["STR", "AGI", "INT", "CHA", "CON", "LCK"]:
		var lbl := Label.new()
		lbl.text = attr_name + ": --"
		SRPGTheme.apply_label(lbl, SRPGTheme.PAPER, 14)
		attr_grid.add_child(lbl)
		_detail_attr_labels[attr_name] = lbl

	# Skills
	var skill_title := Label.new()
	skill_title.text = "技能"
	SRPGTheme.apply_label(skill_title, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(skill_title)

	_detail_skill_list = VBoxContainer.new()
	_detail_container.add_child(_detail_skill_list)

	# Equipment
	var equip_title := Label.new()
	equip_title.text = "装备"
	SRPGTheme.apply_label(equip_title, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(equip_title)

	_detail_equip_list = VBoxContainer.new()
	_detail_container.add_child(_detail_equip_list)

	_set_detail_visible(false)
	return panel

func _set_detail_visible(visible: bool) -> void:
	_detail_container.visible = visible

func _build_hint_bar() -> void:
	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = 510
	bar.custom_minimum_size = Vector2(960, 30)
	SRPGTheme.apply_panel(bar, Color(0.04, 0.04, 0.04, 0.95), SRPGTheme.GOLD)
	add_child(bar)

	var hint_label := Label.new()
	hint_label.text = "点击角色查看详情 | 点击编队槽位添加/移除角色 | Enter 确认 | Esc 关闭"
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label(hint_label, SRPGTheme.PAPER_MUTED, 12)
	bar.add_child(hint_label)
	_hint_bar = bar

func _connect_signals() -> void:
	GameEvents.party_composition_changed.connect(_on_roster_party_changed)

func _refresh_all() -> void:
	if _roster == null:
		return
	_refresh_roster_list()
	_refresh_party_slots()
	_refresh_detail()

## Rebuild the roster character list.
func _refresh_roster_list() -> void:
	if _roster == null or _roster_list == null:
		return
	for child in _roster_list.get_children():
		child.queue_free()

	var deployable := _roster.get_deployable_ids()
	for unit_id_variant in deployable:
		var unit_id := StringName(unit_id_variant)
		var unit: Unit = _roster.get_character(unit_id)
		if unit == null:
			continue
		var btn := _create_roster_item(unit)
		_roster_list.add_child(btn)

	# Show departed / defeated info
	var departed := _roster.get_departed_ids()
	if not departed.is_empty():
		var info := Label.new()
		info.text = "已退场: %d 人" % departed.size()
		SRPGTheme.apply_label(info, SRPGTheme.VERMILION, 12)
		_roster_list.add_child(info)

func _create_roster_item(unit: Unit) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(420, 52)
	btn.focus_mode = Control.FOCUS_ALL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = unit.display_name
	SRPGTheme.apply_label(name_lbl, SRPGTheme.PAPER, 15)
	name_lbl.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_lbl)

	# Class
	var class_lbl := Label.new()
	var class_name_str: String = ClassNames.ClassID.keys()[unit.class_component.get_class_id()]
	class_lbl.text = class_name_str
	SRPGTheme.apply_label(class_lbl, SRPGTheme.GOLD, 13)
	hbox.add_child(class_lbl)

	# Status badge
	var status := _roster.get_status(unit.unit_id)
	var status_lbl := Label.new()
	match status:
		CharacterRoster.Status.DEPLOYED:
			status_lbl.text = "[上场]"
			SRPGTheme.apply_label(status_lbl, SRPGTheme.JADE, 12)
		CharacterRoster.Status.AVAILABLE:
			status_lbl.text = "[备用]"
			SRPGTheme.apply_label(status_lbl, SRPGTheme.PAPER_MUTED, 12)
		_:
			status_lbl.text = "[退场]"
			SRPGTheme.apply_label(status_lbl, SRPGTheme.VERMILION, 12)
	hbox.add_child(status_lbl)

	# HP (derived via HpFormula; units are full HP outside combat)
	var hp_lbl := Label.new()
	var max_hp: int = unit.get_max_hp()
	hp_lbl.text = "HP %d/%d" % [max_hp, max_hp]
	SRPGTheme.apply_label(hp_lbl, SRPGTheme.PAPER, 13)
	hbox.add_child(hp_lbl)

	btn.pressed.connect(_on_roster_item_selected.bind(unit.unit_id))
	return btn

func _refresh_party_slots() -> void:
	if _roster == null or _party_labels.is_empty():
		return
	for i in range(4):
		var label: Label = _party_labels[i]
		var btn: Button = _slot_buttons[i]
		if i < _pending_party.size():
			var unit_id: StringName = StringName(_pending_party[i])
			var unit: Unit = _roster.get_character(unit_id)
			if unit != null:
				label.text = unit.display_name
				SRPGTheme.apply_label(label, SRPGTheme.WHITE, 14)
				continue
		label.text = "(空)"
		SRPGTheme.apply_label(label, SRPGTheme.PAPER_MUTED, 13)

func _refresh_detail() -> void:
	if _roster == null or _selected_unit_id == &"":
		_set_detail_visible(false)
		return

	var unit: Unit = _roster.get_character(_selected_unit_id)
	if unit == null:
		_set_detail_visible(false)
		return

	_set_detail_visible(true)
	_detail_name_label.text = unit.display_name
	_detail_class_label.text = ClassNames.ClassID.keys()[unit.class_component.get_class_id()]

	var max_hp: int = unit.get_max_hp()
	_detail_hp_label.text = "HP: %d / %d" % [max_hp, max_hp]

	# Refresh attributes
	for attr_name in ["STR", "AGI", "INT", "CHA", "CON", "LCK"]:
		var attr_val: int = unit.get_effective_attribute(AttributeNames.Attribute[attr_name])
		if _detail_attr_labels.has(attr_name):
			_detail_attr_labels[attr_name].text = "%s: %d" % [attr_name, attr_val]

	# Refresh skills
	for child in _detail_skill_list.get_children():
		child.queue_free()
	var skills: Array = unit.skill_component.get_learned_skills()
	for skill in skills:
		var lbl := Label.new()
		lbl.text = skill.display_name if skill != null else "Unknown Skill"
		SRPGTheme.apply_label(lbl, SRPGTheme.PAPER, 13)
		_detail_skill_list.add_child(lbl)

	# Refresh equipment
	for child in _detail_equip_list.get_children():
		child.queue_free()
	var equips: Array = _get_equipped_item_names(unit)
	for equip in equips:
		var lbl := Label.new()
		lbl.text = equip
		SRPGTheme.apply_label(lbl, SRPGTheme.PAPER, 13)
		_detail_equip_list.add_child(lbl)

func _get_equipped_item_names(unit: Unit) -> Array:
	var names: Array = []
	if unit == null or unit.equipment_component == null:
		return names
	for slot in unit.equipment_component.get_loadout():
		var item: EquipmentItem = unit.equipment_component.get_equipped_item(slot)
		if item == null:
			continue
		names.append(item.name if item.name != "" else String(item.item_id))
	if names.is_empty():
		names.append("Empty")
	return names

## Tab selection handler.
func _on_tab_selected(tab_key: String) -> void:
	var idx: int = TAB_KEYS.find(tab_key)
	if idx >= 0:
		_active_tab = idx
	_refresh_all()

## Roster item click -> show detail.
func _on_roster_item_selected(unit_id: StringName) -> void:
	_selected_unit_id = unit_id
	_refresh_detail()

## Party slot click -> toggle add/remove.
func _on_party_slot_pressed(slot_index: int) -> void:
	var current_id: StringName = _pending_party[slot_index] if slot_index < _pending_party.size() else &""
	if current_id != &"":
		# Remove from party
		_pending_party.remove_at(slot_index)
	else:
		# Add selected unit to party if not full and not already in
		if _selected_unit_id == &"":
			return
		if _pending_party.size() >= CharacterRoster.MAX_DEPLOYED:
			return
		if _pending_party.has(_selected_unit_id):
			return
		_pending_party.append(_selected_unit_id)
	_refresh_party_slots()

## Confirm party changes.
func _on_confirm_party_pressed() -> void:
	if _roster == null:
		return
	var old_party := _roster.get_party()
	if _roster.set_party(_pending_party):
		party_changed.emit(_pending_party)
		_refresh_roster_list()
		_refresh_party_slots()

## Close button handler.
func _on_close_pressed() -> void:
	closed.emit()

## Roster party changed externally (e.g. battle end).
func _on_roster_party_changed(old_party: Array, new_party: Array) -> void:
	_pending_party = new_party.duplicate()
	_refresh_party_slots()
	_refresh_roster_list()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			closed.emit()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_confirm_party_pressed()
			get_viewport().set_input_as_handled()
