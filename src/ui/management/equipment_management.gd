class_name EquipmentManagement
extends Control

## Equipment management UI controller.
## Manages character equipment viewing and swapping through a two-panel layout:
## - Left: current unit's equipment slots with stats
## - Right: inventory grid with filterable equipment items

signal equipment_changed(unit: Node, slot: int, old_item_id: StringName, new_item_id: StringName)

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const EquipmentDefinitions := preload("res://src/core/equipment/equipment_definitions.gd")
const EquipmentItem := preload("res://src/core/equipment/equipment_item.gd")

const SLOT_LABELS: Dictionary = {
	EquipmentDefinitions.Slot.WEAPON: "Weapon",
	EquipmentDefinitions.Slot.ARMOR: "Armor",
	EquipmentDefinitions.Slot.HELMET: "Helmet",
	EquipmentDefinitions.Slot.LEGS: "Legs",
	EquipmentDefinitions.Slot.BOOTS: "Boots",
	EquipmentDefinitions.Slot.ACCESSORY: "Accessory",
}

const QUALITY_COLORS: Dictionary = {
	EquipmentDefinitions.Quality.WHITE: Color(0.88, 0.88, 0.88),
	EquipmentDefinitions.Quality.GREEN: Color(0.28, 0.82, 0.28),
	EquipmentDefinitions.Quality.BLUE: Color(0.20, 0.50, 0.90),
	EquipmentDefinitions.Quality.PURPLE: Color(0.65, 0.20, 0.85),
	EquipmentDefinitions.Quality.GOLD: Color(0.90, 0.70, 0.20),
}

const SLOT_ORDER: Array[int] = [
	EquipmentDefinitions.Slot.WEAPON,
	EquipmentDefinitions.Slot.ARMOR,
	EquipmentDefinitions.Slot.HELMET,
	EquipmentDefinitions.Slot.LEGS,
	EquipmentDefinitions.Slot.BOOTS,
	EquipmentDefinitions.Slot.ACCESSORY,
]

var _unit: Node = null
var _equipment_component = null
var _all_items: Array = []
var _current_filter_slot: int = -1  # -1 means all slots

var _slot_container: VBoxContainer
var _inventory_grid: GridContainer
var _stat_labels: Dictionary = {}  # slot -> Label
var _slot_item_labels: Dictionary = {}  # slot -> Label
var _slot_buttons: Dictionary = {}  # slot -> Button
var _inventory_buttons: Dictionary = {}  # item_id -> Button
var _filter_buttons: Dictionary = {}  # slot -> Button

func _ready() -> void:
	visible = false

## Open equipment management for a specific unit.
func open_for_unit(unit: Node) -> void:
	_unit = unit
	if _unit == null:
		return
	_equipment_component = (_unit as Unit).equipment_component if _unit is Unit else null
	_refresh_all()
	visible = true

## Close and deselect.
func close() -> void:
	visible = false
	_current_filter_slot = -1
	_unit = null
	_equipment_component = null

## Refresh all UI elements.
func _refresh_all() -> void:
	_refresh_stat_panel()
	_refresh_inventory_grid()

## Build the left stat panel (equipment slots + character stats).
func build_left_panel(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	# Filter buttons row
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	content.add_child(filter_row)

	var all_btn := Button.new()
	all_btn.text = "All"
	all_btn.custom_minimum_size = Vector2(60, 28)
	all_btn.pressed.connect(func() -> void: _set_filter(-1))
	SRPGTheme.apply_button(all_btn, false, false, true)
	filter_row.add_child(all_btn)

	for slot in SLOT_ORDER:
		var btn := Button.new()
		btn.text = SLOT_LABELS[slot]
		btn.custom_minimum_size = Vector2(72, 28)
		btn.pressed.connect(func(s=slot) -> void: _set_filter(s))
		SRPGTheme.apply_button(btn, false, false, true)
		filter_row.add_child(btn)
		_filter_buttons[slot] = btn

	# Character name header
	var name_label := Label.new()
	name_label.text = _unit.display_name if _unit != null else ""
	SRPGTheme.apply_label(name_label, SRPGTheme.WHITE, 18, true)
	content.add_child(name_label)

	# Stats summary
	var stats_label := Label.new()
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(stats_label, SRPGTheme.PAPER, 14)
	content.add_child(stats_label)
	_stat_labels[0] = stats_label

	# Divider
	var divider := Label.new()
	divider.text = "--- Equipment ---"
	SRPGTheme.apply_label(divider, SRPGTheme.GOLD, 13)
	content.add_child(divider)

	# Equipment slots
	_slot_container = VBoxContainer.new()
	_slot_container.add_theme_constant_override("separation", 6)
	content.add_child(_slot_container)

	for slot in SLOT_ORDER:
		var row := _build_slot_row(slot)
		_slot_container.add_child(row)

## Build a single equipment slot row with unequip + item info.
func _build_slot_row(slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Slot name label
	var slot_label := Label.new()
	slot_label.text = SLOT_LABELS[slot]
	slot_label.custom_minimum_size = Vector2(80, 0)
	SRPGTheme.apply_label(slot_label, SRPGTheme.PAPER_MUTED, 13)
	row.add_child(slot_label)

	# Item info label
	var item_label := Label.new()
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(item_label, SRPGTheme.PAPER, 13)
	row.add_child(item_label)
	_slot_item_labels[slot] = item_label

	# Unequip button
	var unequip_btn := Button.new()
	unequip_btn.text = "Off"
	unequip_btn.custom_minimum_size = Vector2(40, 28)
	unequip_btn.focus_mode = Control.FOCUS_ALL
	unequip_btn.pressed.connect(func() -> void: _unequip_slot(slot))
	SRPGTheme.apply_button(unequip_btn, false, false, true)
	row.add_child(unequip_btn)
	_slot_buttons[slot] = unequip_btn

	return row

## Build the right inventory panel.
func build_right_panel(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	parent.add_child(vbox)

	var inv_label := Label.new()
	inv_label.text = "Inventory"
	SRPGTheme.apply_label(inv_label, SRPGTheme.WHITE, 16, true)
	vbox.add_child(inv_label)

	var hint_label := Label.new()
	hint_label.text = "Click item to equip"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(hint_label, SRPGTheme.PAPER_MUTED, 12)
	vbox.add_child(hint_label)

	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 3
	_inventory_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inventory_grid.add_theme_constant_override("h_separation", 4)
	_inventory_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_inventory_grid)

## Unequip an item from a slot.
func _unequip_slot(slot: int) -> void:
	if _equipment_component == null:
		return
	var old_item_id: StringName = _equipment_component.unequip_slot(slot)
	if old_item_id != &"":
		equipment_changed.emit(_unit, slot, old_item_id, &"")
	_refresh_all()

## Equip an item from inventory.
func _equip_item(item: EquipmentItem) -> void:
	if _equipment_component == null or item == null:
		return
	var result: Dictionary = _equipment_component.equip_item(item.item_id)
	if result.get("success", false):
		var old_id: StringName = StringName(result.get("replaced_item_id", ""))
		equipment_changed.emit(_unit, item.slot, old_id, item.item_id)
	_refresh_all()

## Set the inventory filter by slot (-1 = all slots).
func _set_filter(slot: int) -> void:
	_current_filter_slot = slot
	for slot_i in _filter_buttons:
		var btn: Button = _filter_buttons[slot_i]
		SRPGTheme.apply_button(btn, slot_i == slot, false, true)
	_refresh_inventory_grid()

## Refresh the stat panel with current equipment data.
func _refresh_stat_panel() -> void:
	if _equipment_component == null or _unit == null:
		return

	# Stats label
	var stats_text := ""
	if _stat_labels.has(0):
		var eq = _equipment_component
		var str_bonus: int = eq.get_equipment_bonus(1)  # AttributeNames.Attribute.STR
		var agi_bonus: int = eq.get_equipment_bonus(2)  # AttributeNames.Attribute.AGI
		var con_bonus: int = eq.get_equipment_bonus(3)  # AttributeNames.Attribute.CON
		var int_bonus: int = eq.get_equipment_bonus(4)  # AttributeNames.Attribute.INT
		stats_text = "STR %+d  AGI %+d  CON %+d  INT %+d" % [str_bonus, agi_bonus, con_bonus, int_bonus]
		_stat_labels[0].text = stats_text

	# Slot items
	for slot in SLOT_ORDER:
		var item: EquipmentItem = _equipment_component.get_equipped_item(slot)
		var label: Label = _slot_item_labels.get(slot)
		var btn: Button = _slot_buttons.get(slot)
		if label == null:
			continue
		if item != null:
			var quality_color: Color = QUALITY_COLORS.get(item.quality, SRPGTheme.PAPER)
			var enh_text := " +%d" % item.enhancement_level if item.enhancement_level > 0 else ""
			var set_text := " [%s]" % _get_set_name(item.set_id) if item.set_id != EquipmentDefinitions.NO_SET else ""
			label.text = "%s%s%s" % [item.name, enh_text, set_text]
			label.add_theme_color_override("font_color", quality_color)
			btn.disabled = false
		else:
			label.text = "(empty)"
			label.add_theme_color_override("font_color", SRPGTheme.DISABLED_TEXT)
			btn.disabled = true

## Get set name from set_id.
func _get_set_name(set_id: int) -> String:
	if set_id == EquipmentDefinitions.NO_SET:
		return ""
	var bonuses: Dictionary = EquipmentDefinitions.SET_BONUSES.get(set_id, {})
	return String(bonuses.get("name", ""))

## Collect all equipment items from the unit's equipment component.
func _collect_all_items() -> Array:
	if _equipment_component == null:
		return []
	var items: Array = _equipment_component.get_all_items()
	# Filter to items not currently equipped
	var equipped: Array[StringName] = []
	for slot in SLOT_ORDER:
		var item: EquipmentItem = _equipment_component.get_equipped_item(slot)
		if item != null:
			equipped.append(item.item_id)
	var unequipped: Array = []
	for item in items:
		if not equipped.has(item.item_id):
			unequipped.append(item)
	return unequipped

## Refresh the inventory grid with unequipped items.
func _refresh_inventory_grid() -> void:
	if _inventory_grid == null:
		return

	# Clear existing buttons
	for child in _inventory_grid.get_children():
		child.queue_free()
	_inventory_buttons.clear()

	_all_items = _collect_all_items()

	for item in _all_items:
		if _current_filter_slot >= 0 and item.slot != _current_filter_slot:
			continue
		var btn := _build_item_button(item)
		_inventory_grid.add_child(btn)
		_inventory_buttons[item.item_id] = btn

## Build a button for a single inventory item.
func _build_item_button(item: EquipmentItem) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(100, 60)
	btn.text = ""
	btn.focus_mode = Control.FOCUS_ALL

	var quality_color: Color = QUALITY_COLORS.get(item.quality, SRPGTheme.PAPER)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	btn.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", quality_color)
	name_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_lbl)

	var slot_lbl := Label.new()
	slot_lbl.text = SLOT_LABELS[item.slot]
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_color_override("font_color", SRPGTheme.PAPER_MUTED)
	slot_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(slot_lbl)

	if item.enhancement_level > 0:
		var enh_lbl := Label.new()
		enh_lbl.text = "+%d" % item.enhancement_level
		enh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enh_lbl.add_theme_color_override("font_color", SRPGTheme.GOLD)
		enh_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(enh_lbl)

	btn.pressed.connect(func() -> void: _equip_item(item))
	SRPGTheme.apply_button(btn, false, false, true)

	return btn
