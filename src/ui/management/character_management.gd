class_name CharacterManagement
extends Control

## Character Management screen - party organization and character details.
## Provides roster view, party adjustment (up to 4 deployed), and character detail panel.

signal closed()
signal party_changed(new_party: Array)
signal equipment_changed(unit: Unit, slot: int, old_item_id: StringName, new_item_id: StringName)

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const CharacterTabBar := preload("res://src/ui/management/character_tab_bar.gd")

enum Tab { CHARACTER, PARTY, EQUIPMENT, SKILLS }
const TAB_KEYS: Array[String] = ["character", "party", "equipment", "skills"]
const DETAIL_ATTRIBUTE_KEYS: Array[String] = ["STR", "AGI", "CON", "INT", "CHA", "LUK"]
const SLOT_LABELS: Dictionary = {
	EquipmentDefinitions.Slot.WEAPON: "武器",
	EquipmentDefinitions.Slot.ARMOR: "护甲",
	EquipmentDefinitions.Slot.HELMET: "头盔",
	EquipmentDefinitions.Slot.LEGS: "腿甲",
	EquipmentDefinitions.Slot.BOOTS: "靴子",
	EquipmentDefinitions.Slot.ACCESSORY: "饰品",
}
const SLOT_ORDER: Array[int] = [
	EquipmentDefinitions.Slot.WEAPON,
	EquipmentDefinitions.Slot.ARMOR,
	EquipmentDefinitions.Slot.HELMET,
	EquipmentDefinitions.Slot.LEGS,
	EquipmentDefinitions.Slot.BOOTS,
	EquipmentDefinitions.Slot.ACCESSORY,
]

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
var _ui_scale: float = 1.0

# Pending party changes before confirm
var _pending_party: Array = []

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_all()

## Initialize with an existing CharacterRoster instance.
func initialize(roster: CharacterRoster) -> void:
	_roster = roster
	_pending_party = _roster.get_party().duplicate() if _roster != null else []
	if _is_ui_ready():
		_refresh_all()

func set_ui_scale(scale: float) -> void:
	_ui_scale = clampf(scale, 1.0, 1.3)
	if _is_ui_ready():
		_rebuild_ui()

func _scaled(value: float) -> float:
	return SRPGTheme.scale_size(value, _ui_scale)

func _scaled_vec2(width: float, height: float) -> Vector2:
	return Vector2(_scaled(width), _scaled(height))

func _rebuild_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_tab_bar = null
	_left_panel = null
	_right_panel = null
	_roster_list = null
	_party_slots = null
	_detail_container = null
	_detail_name_label = null
	_detail_class_label = null
	_detail_hp_label = null
	_detail_attr_labels.clear()
	_detail_skill_list = null
	_detail_equip_list = null
	_party_labels.clear()
	_slot_buttons.clear()
	_hint_bar = null
	_close_button = null
	_action_bar = null
	_confirm_button = null
	_build_ui()
	_refresh_all()

func _is_ui_ready() -> bool:
	return _roster_list != null and _detail_container != null and not _party_labels.is_empty()

func _build_ui() -> void:
	# Blocker / backdrop
	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	# Main container
	var root := HBoxContainer.new()
	root.name = "ManagementMainHBox"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = _scaled(12.0)
	root.offset_top = _scaled(12.0)
	root.offset_right = -_scaled(12.0)
	root.offset_bottom = -_scaled(38.0)
	root.add_theme_constant_override("separation", int(_scaled(12.0)))
	add_child(root)

	# Left panel: tab bar + roster list + party slots (helper attaches to parent)
	_left_panel = _create_left_panel(root)

	# Right panel: character detail (helper attaches to parent)
	_right_panel = _create_right_panel(root)

	# Hint bar at bottom
	_build_hint_bar()

func _create_left_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(_scaled(440.0), 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.34
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.GOLD)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(12.0)
	vbox.offset_top = _scaled(12.0)
	vbox.offset_right = -_scaled(12.0)
	vbox.offset_bottom = -_scaled(12.0)
	vbox.add_theme_constant_override("separation", int(_scaled(8.0)))
	panel.add_child(vbox)

	# Tab bar
	_tab_bar = CharacterTabBar.new()
	_tab_bar.set_ui_scale(_ui_scale)
	_tab_bar.initialize(TAB_KEYS)
	_tab_bar.tab_selected.connect(_on_tab_selected)
	vbox.add_child(_tab_bar)

	# Roster list (scrollable)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = _scaled_vec2(420.0, 260.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_roster_list = VBoxContainer.new()
	_roster_list.add_theme_constant_override("separation", int(_scaled(4.0)))
	scroll.add_child(_roster_list)

	# Party slots label
	var party_title := Label.new()
	party_title.text = "编队 (最多4人)"
	SRPGTheme.apply_label_scaled(party_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(party_title)

	# Party slots row
	_party_slots = HBoxContainer.new()
	_party_slots.add_theme_constant_override("separation", int(_scaled(6.0)))
	for i in range(4):
		var slot := _create_party_slot(i)
		_party_slots.add_child(slot)
	vbox.add_child(_party_slots)

	# Action bar
	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", int(_scaled(8.0)))
	_action_bar.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(_action_bar)

	_confirm_button = Button.new()
	_confirm_button.text = "确认编队"
	_confirm_button.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button_scaled(_confirm_button, _ui_scale, false, false, true)
	_confirm_button.pressed.connect(_on_confirm_party_pressed)
	_action_bar.add_child(_confirm_button)

	return panel

func _create_party_slot(index: int) -> Panel:
	var slot_panel := Panel.new()
	slot_panel.custom_minimum_size = _scaled_vec2(112.0, 78.0)
	SRPGTheme.apply_panel(slot_panel, SRPGTheme.INK_SOFT, SRPGTheme.JADE)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label_scaled(label, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
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
	panel.custom_minimum_size = Vector2(_scaled(440.0), 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.66
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(12.0)
	vbox.offset_top = _scaled(12.0)
	vbox.offset_right = -_scaled(12.0)
	vbox.offset_bottom = -_scaled(12.0)
	vbox.add_theme_constant_override("separation", int(_scaled(10.0)))
	panel.add_child(vbox)

	# Close button
	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button_scaled(_close_button, _ui_scale, false, false, true)
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

	# Detail container
	_detail_container = VBoxContainer.new()
	_detail_container.add_theme_constant_override("separation", int(_scaled(8.0)))
	_detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_detail_container)

	_detail_name_label = Label.new()
	SRPGTheme.apply_label_scaled(_detail_name_label, _ui_scale, SRPGTheme.WHITE, 22, true)
	_detail_container.add_child(_detail_name_label)

	_detail_class_label = Label.new()
	SRPGTheme.apply_label_scaled(_detail_class_label, _ui_scale, SRPGTheme.GOLD, 16)
	_detail_container.add_child(_detail_class_label)

	_detail_hp_label = Label.new()
	SRPGTheme.apply_label_scaled(_detail_hp_label, _ui_scale, SRPGTheme.JADE, 16)
	_detail_container.add_child(_detail_hp_label)

	# Attributes
	var attr_title := Label.new()
	attr_title.text = "属性"
	SRPGTheme.apply_label_scaled(attr_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(attr_title)

	var attr_grid := GridContainer.new()
	attr_grid.columns = 2
	attr_grid.add_theme_constant_override("h_separation", int(_scaled(12.0)))
	attr_grid.add_theme_constant_override("v_separation", int(_scaled(4.0)))
	_detail_container.add_child(attr_grid)

	for attr_name in DETAIL_ATTRIBUTE_KEYS:
		var lbl := Label.new()
		lbl.text = attr_name + ": --"
		SRPGTheme.apply_label_scaled(lbl, _ui_scale, SRPGTheme.PAPER, 14)
		attr_grid.add_child(lbl)
		_detail_attr_labels[attr_name] = lbl

	# Skills
	var skill_title := Label.new()
	skill_title.text = "技能"
	SRPGTheme.apply_label_scaled(skill_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(skill_title)

	_detail_skill_list = VBoxContainer.new()
	_detail_container.add_child(_detail_skill_list)

	# Equipment
	var equip_title := Label.new()
	equip_title.text = "装备"
	SRPGTheme.apply_label_scaled(equip_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	_detail_container.add_child(equip_title)

	_detail_equip_list = VBoxContainer.new()
	_detail_container.add_child(_detail_equip_list)

	_set_detail_visible(false)
	return panel

func _set_detail_visible(visible: bool) -> void:
	if _detail_container == null:
		return
	_detail_container.visible = visible

func _build_hint_bar() -> void:
	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -_scaled(30.0)
	bar.offset_bottom = 0
	bar.custom_minimum_size = Vector2(0, _scaled(30.0))
	SRPGTheme.apply_panel(bar, Color(0.04, 0.04, 0.04, 0.95), SRPGTheme.GOLD)
	add_child(bar)

	var hint_label := Label.new()
	hint_label.text = "点击角色查看详情 | 点击编队槽位添加/移除角色 | Enter 确认 | Esc 关闭"
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label_scaled(hint_label, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
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

	var deployable := _get_ordered_deployable_ids()
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
		SRPGTheme.apply_label_scaled(info, _ui_scale, SRPGTheme.VERMILION, 12)
		_roster_list.add_child(info)

func _get_ordered_deployable_ids() -> Array[StringName]:
	var ordered: Array[StringName] = []
	if _roster == null:
		return ordered

	var deployable: Array = _roster.get_deployable_ids()
	var deployable_lookup: Dictionary = {}
	for unit_id_variant in deployable:
		deployable_lookup[StringName(unit_id_variant)] = true

	for unit_id_variant in _pending_party:
		var unit_id := StringName(unit_id_variant)
		if deployable_lookup.has(unit_id) and not ordered.has(unit_id):
			ordered.append(unit_id)

	for unit_id_variant in deployable:
		var unit_id := StringName(unit_id_variant)
		if not ordered.has(unit_id):
			ordered.append(unit_id)

	return ordered

func _create_roster_item(unit: Unit) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = _scaled_vec2(420.0, 58.0)
	btn.focus_mode = Control.FOCUS_ALL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	btn.add_child(hbox)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = unit.display_name
	SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.PAPER, 15)
	name_lbl.custom_minimum_size = Vector2(_scaled(120.0), 0)
	hbox.add_child(name_lbl)

	# Class
	var class_lbl := Label.new()
	var class_name_str: String = ClassNames.ClassID.keys()[unit.class_component.get_class_id()]
	class_lbl.text = class_name_str
	SRPGTheme.apply_label_scaled(class_lbl, _ui_scale, SRPGTheme.GOLD, 13)
	hbox.add_child(class_lbl)

	# Status badge
	var status := _roster.get_status(unit.unit_id)
	var status_lbl := Label.new()
	match status:
		CharacterRoster.Status.DEPLOYED:
			status_lbl.text = "[上场]"
			SRPGTheme.apply_label_scaled(status_lbl, _ui_scale, SRPGTheme.JADE, 12)
		CharacterRoster.Status.AVAILABLE:
			status_lbl.text = "[备用]"
			SRPGTheme.apply_label_scaled(status_lbl, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
		_:
			status_lbl.text = "[退场]"
			SRPGTheme.apply_label_scaled(status_lbl, _ui_scale, SRPGTheme.VERMILION, 12)
	hbox.add_child(status_lbl)

	# HP (derived via HpFormula; units are full HP outside combat)
	var hp_lbl := Label.new()
	var max_hp: int = unit.get_max_hp()
	hp_lbl.text = "HP %d/%d" % [max_hp, max_hp]
	SRPGTheme.apply_label_scaled(hp_lbl, _ui_scale, SRPGTheme.PAPER, 13)
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
				SRPGTheme.apply_label_scaled(label, _ui_scale, SRPGTheme.WHITE, 14)
				continue
		label.text = "(空)"
		SRPGTheme.apply_label_scaled(label, _ui_scale, SRPGTheme.PAPER_MUTED, 13)

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
	for attr_name in DETAIL_ATTRIBUTE_KEYS:
		var attr_val: int = unit.get_effective_attribute(AttributeNames.Attribute[attr_name])
		if _detail_attr_labels.has(attr_name):
			_detail_attr_labels[attr_name].text = "%s: %d" % [attr_name, attr_val]

	# Refresh skills
	for child in _detail_skill_list.get_children():
		child.queue_free()
	var skills: Array = unit.skill_component.get_all_skills()
	for skill in skills:
		var lbl := Label.new()
		lbl.text = _get_skill_display_name(skill)
		SRPGTheme.apply_label_scaled(lbl, _ui_scale, SRPGTheme.PAPER, 13)
		_detail_skill_list.add_child(lbl)

	# Refresh equipment
	for child in _detail_equip_list.get_children():
		child.queue_free()
	_refresh_equipment_actions(unit)

func _refresh_equipment_actions(unit: Unit) -> void:
	if unit == null or unit.equipment_component == null:
		return

	var equipped_title := Label.new()
	equipped_title.text = "当前装备"
	SRPGTheme.apply_label_scaled(equipped_title, _ui_scale, SRPGTheme.GOLD, 13, true)
	_detail_equip_list.add_child(equipped_title)

	for slot in SLOT_ORDER:
		_detail_equip_list.add_child(_create_equipped_slot_row(unit, slot))

	var inventory_title := Label.new()
	inventory_title.text = "可装备物品"
	SRPGTheme.apply_label_scaled(inventory_title, _ui_scale, SRPGTheme.GOLD, 13, true)
	_detail_equip_list.add_child(inventory_title)

	var equipped_ids := _get_equipped_item_ids(unit)
	var available_count := 0
	for item in unit.equipment_component.get_all_items():
		if not (item is EquipmentItem):
			continue
		var equipment_item := item as EquipmentItem
		if equipped_ids.has(equipment_item.item_id):
			continue
		_detail_equip_list.add_child(_create_inventory_item_row(unit, equipment_item))
		available_count += 1

	if available_count == 0:
		var empty_label := Label.new()
		empty_label.text = "没有可装备物品"
		SRPGTheme.apply_label_scaled(empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 13)
		_detail_equip_list.add_child(empty_label)

func _create_equipped_slot_row(unit: Unit, slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(_scaled(8.0)))

	var slot_lbl := Label.new()
	slot_lbl.text = SLOT_LABELS.get(slot, "装备")
	slot_lbl.custom_minimum_size = Vector2(_scaled(58.0), 0.0)
	SRPGTheme.apply_label_scaled(slot_lbl, _ui_scale, SRPGTheme.PAPER_MUTED, 13)
	row.add_child(slot_lbl)

	var item := unit.equipment_component.get_equipped_item(slot)
	var item_lbl := Label.new()
	item_lbl.text = _format_equipment_name(item) if item != null else "(空)"
	item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label_scaled(item_lbl, _ui_scale, SRPGTheme.PAPER, 13)
	row.add_child(item_lbl)

	var off_btn := Button.new()
	off_btn.text = "卸下"
	off_btn.disabled = item == null
	off_btn.focus_mode = Control.FOCUS_ALL
	off_btn.custom_minimum_size = _scaled_vec2(64.0, 28.0)
	off_btn.pressed.connect(_on_unequip_slot_pressed.bind(unit.unit_id, slot))
	SRPGTheme.apply_button_scaled(off_btn, _ui_scale, false, false, true)
	row.add_child(off_btn)

	return row

func _create_inventory_item_row(unit: Unit, item: EquipmentItem) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(_scaled(8.0)))

	var name_lbl := Label.new()
	name_lbl.text = "%s  [%s]" % [_format_equipment_name(item), SLOT_LABELS.get(item.slot, "装备")]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.PAPER, 13)
	row.add_child(name_lbl)

	var equip_btn := Button.new()
	equip_btn.text = "装备"
	equip_btn.focus_mode = Control.FOCUS_ALL
	equip_btn.custom_minimum_size = _scaled_vec2(64.0, 28.0)
	equip_btn.pressed.connect(_on_equip_item_pressed.bind(unit.unit_id, item.item_id))
	SRPGTheme.apply_button_scaled(equip_btn, _ui_scale, false, false, true)
	row.add_child(equip_btn)

	return row

func _get_equipped_item_ids(unit: Unit) -> Dictionary:
	var ids: Dictionary = {}
	if unit == null or unit.equipment_component == null:
		return ids
	for slot in unit.equipment_component.get_loadout():
		var item_id := StringName(unit.equipment_component.get_loadout()[slot])
		if item_id != &"":
			ids[item_id] = true
	return ids

func _format_equipment_name(item: EquipmentItem) -> String:
	if item == null:
		return "(空)"
	if item.name != "":
		return item.name
	return String(item.item_id)

func _get_skill_display_name(skill: SkillData) -> String:
	if skill == null:
		return "Unknown Skill"
	if skill.name != "":
		return skill.name
	return String(skill.skill_id)

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
	if _roster.set_party(_pending_party):
		_pending_party = _roster.get_party().duplicate()
		party_changed.emit(_pending_party)
		_refresh_roster_list()
		_refresh_party_slots()

func _on_unequip_slot_pressed(unit_id: StringName, slot: int) -> void:
	if _roster == null:
		return
	var unit: Unit = _roster.get_character(unit_id)
	if unit == null or unit.equipment_component == null:
		return
	var old_item_id: StringName = unit.equipment_component.unequip_slot(slot)
	if old_item_id == &"":
		return
	equipment_changed.emit(unit, slot, old_item_id, &"")
	_refresh_detail()

func _on_equip_item_pressed(unit_id: StringName, item_id: StringName) -> void:
	if _roster == null:
		return
	var unit: Unit = _roster.get_character(unit_id)
	if unit == null or unit.equipment_component == null:
		return
	var item: EquipmentItem = unit.equipment_component.get_item(item_id)
	if item == null:
		return
	var result: Dictionary = unit.equipment_component.equip_item(item_id)
	if not result.get("success", false):
		return
	var old_item_id := StringName(result.get("replaced_item_id", ""))
	equipment_changed.emit(unit, item.slot, old_item_id, item_id)
	_refresh_detail()

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
