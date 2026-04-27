extends Gut

const CharacterManagementScene := preload("res://src/ui/management/character_management_screen.tscn")

var _roster: CharacterRoster
var _screen: CharacterManagement

func before_each() -> void:
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)
	Inventory.reset()
	_roster = CharacterRoster.new()
	_roster.name = "Roster"
	add_child(_roster)

	var unit := Unit.new()
	unit.unit_id = &"leader"
	unit.display_name = "Leader"
	_roster.add_character(unit, CharacterRoster.Status.DEPLOYED)

func after_each() -> void:
	if is_instance_valid(_screen):
		_screen.queue_free()
	if is_instance_valid(_roster):
		_roster.queue_free()
	Inventory.reset()

func test_initialize_before_entering_tree_refreshes_after_ready() -> void:
	_screen = CharacterManagementScene.instantiate()

	_screen.initialize(_roster)
	add_child(_screen)

	assert_ne(_screen._detail_container, null, "Detail container should be built during _ready")
	assert_ne(_screen._roster_list, null, "Roster list should be built during _ready")
	assert_eq(_screen._pending_party, [&"leader"], "Initialize should preserve party state before _ready")
	assert_true(_screen._roster_list.get_child_count() > 0, "Ready should refresh roster rows for pre-initialized data")

func test_selecting_roster_item_refreshes_luk_detail() -> void:
	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	add_child(_screen)

	_screen.call("_on_roster_item_selected", &"leader")

	assert_true(_screen._detail_attr_labels.has("LUK"), "Details should use the AttributeNames LUK enum key")
	assert_false(_screen._detail_attr_labels.has("LCK"), "Details should not use the invalid LCK key")
	assert_true((_screen._detail_attr_labels["LUK"] as Label).text.begins_with("LUK:"))

func test_selecting_roster_item_refreshes_skill_names() -> void:
	var unit: Unit = _roster.get_character(&"leader")
	assert_true(unit.learn_skill(&"defend"), "Fixture unit should learn a normal skill")
	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	add_child(_screen)

	_screen.call("_on_roster_item_selected", &"leader")

	assert_true(_screen._detail_skill_list.get_child_count() > 0, "Skill detail list should render owned skills")
	var first_skill := _screen._detail_skill_list.get_child(0) as Label
	assert_ne(first_skill, null)
	assert_true(first_skill.text.length() > 0, "Skill row should use SkillData.name or skill_id")

func test_roster_list_uses_confirmed_party_order() -> void:
	_add_unit(&"archer", "Archer", CharacterRoster.Status.AVAILABLE)
	_add_unit(&"cleric", "Cleric", CharacterRoster.Status.AVAILABLE)
	assert_true(_roster.set_party([&"cleric", &"leader"]))

	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	add_child(_screen)

	var ordered: Array[StringName] = _screen.call("_get_ordered_deployable_ids")
	assert_eq(ordered[0], &"cleric")
	assert_eq(ordered[1], &"leader")
	assert_true(ordered.has(&"archer"))

	_screen.call("_on_roster_item_selected", &"archer")
	_screen.call("_on_party_slot_pressed", 2)
	_screen.call("_on_confirm_party_pressed")

	assert_eq(_roster.get_party(), [&"cleric", &"leader", &"archer"])

func test_equipment_detail_buttons_equip_and_unequip_items() -> void:
	var unit: Unit = _roster.get_character(&"leader")
	unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "bronze_sword",
		"name": "Bronze Sword",
		"slot": EquipmentDefinitions.Slot.WEAPON,
	}))
	unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "iron_sword",
		"name": "Iron Sword",
		"slot": EquipmentDefinitions.Slot.WEAPON,
	}))
	unit.equipment_component.equip_item(&"bronze_sword")

	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	add_child(_screen)
	_screen.call("_on_roster_item_selected", &"leader")

	var equip_button := _find_button_by_text(_screen, SRPGLocalization.translate("management.equip"), true)
	assert_ne(equip_button, null, "Unequipped inventory items should expose an equip button")
	equip_button.pressed.emit()
	assert_eq(unit.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.WEAPON).item_id, &"iron_sword")

	var unequip_button := _find_button_by_text(_screen, SRPGLocalization.translate("management.unequip"), true)
	assert_ne(unequip_button, null, "Equipped slots should expose an unequip button")
	unequip_button.pressed.emit()
	assert_eq(unit.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.WEAPON), null)

func test_equipped_item_enhance_button_spends_resources_and_emits_change() -> void:
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 500)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 25)
	var unit: Unit = _roster.get_character(&"leader")
	unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "bronze_sword",
		"name": "Bronze Sword",
		"slot": EquipmentDefinitions.Slot.WEAPON,
	}))
	unit.equipment_component.equip_item(&"bronze_sword")
	var events: Array = []

	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	_screen.equipment_changed.connect(func(changed_unit: Unit, slot: int, old_item_id: StringName, new_item_id: StringName) -> void:
		events.append({"unit": changed_unit, "slot": slot, "old": old_item_id, "new": new_item_id})
	)
	add_child(_screen)
	_screen.call("_on_roster_item_selected", &"leader")

	var enhance_button := _find_button_by_text(_screen, SRPGLocalization.translate("management.enhance"), true)
	assert_ne(enhance_button, null, "Equipped safe-zone items should expose an enhancement button")
	enhance_button.pressed.emit()

	assert_eq(unit.equipment_component.get_item(&"bronze_sword").enhancement_level, 1)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.GOLD), 400)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 20)
	assert_eq(events.size(), 1)

func test_risk_zone_enhance_button_is_disabled_at_plus_five() -> void:
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	var unit: Unit = _roster.get_character(&"leader")
	unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "blue_sword",
		"name": "Bronze Sword",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"enhancement_level": 5,
	}))
	unit.equipment_component.equip_item(&"blue_sword")

	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	add_child(_screen)
	_screen.call("_on_roster_item_selected", &"leader")

	var enhance_button := _find_button_by_text(_screen, SRPGLocalization.translate("management.enhance"), false)
	assert_ne(enhance_button, null)
	assert_true(enhance_button.disabled, "Sprint-006 UI should not expose +6 risk-zone enhancement")
	assert_true(_collect_label_text(_screen).contains(SRPGLocalization.translate("management.enhance_risk_locked")))

func test_character_detail_shows_top_three_bonds() -> void:
	var story_progress := {
		"bond_levels": {
			"leader::cleric": {"unit_a": "leader", "unit_b": "cleric", "affinity": 210, "rank": "B", "bond_type": "comrade"},
			"archer::leader": {"unit_a": "archer", "unit_b": "leader", "affinity": 80, "rank": "C", "bond_type": "comrade"},
		}
	}
	_screen = CharacterManagementScene.instantiate()
	_screen.initialize(_roster)
	_screen.set_story_progress(story_progress)
	add_child(_screen)
	_screen.call("_on_roster_item_selected", &"leader")

	var text := _collect_label_text(_screen)
	assert_true(text.contains("cleric"))
	assert_true(text.contains("archer"))
	assert_true(text.contains("战友"))
	assert_true(text.contains("210"))

func test_management_screen_uses_full_rect_responsive_root() -> void:
	_screen = CharacterManagementScene.instantiate()
	_screen.set_ui_scale(1.3)
	_screen.initialize(_roster)
	add_child(_screen)

	var root := _screen.find_child("ManagementMainHBox", true, false) as HBoxContainer
	assert_ne(root, null, "Management screen should use a named full-size root")
	assert_eq(root.anchor_right, 1.0)
	assert_eq(root.anchor_bottom, 1.0)
	assert_eq(root.offset_bottom, -49.0)

	assert_ne(_screen._left_panel, null)
	assert_ne(_screen._right_panel, null)
	assert_eq(_screen._left_panel.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_eq(_screen._right_panel.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_almost_eq(_screen._left_panel.size_flags_stretch_ratio, 0.34, 0.001)
	assert_almost_eq(_screen._right_panel.size_flags_stretch_ratio, 0.66, 0.001)

func _add_unit(unit_id: StringName, display_name: String, status: int) -> Unit:
	var unit := Unit.new()
	unit.unit_id = unit_id
	unit.display_name = display_name
	_roster.add_character(unit, status)
	return unit

func _find_button_by_text(node: Node, text: String, enabled_only: bool = false) -> Button:
	if node is Button:
		var button := node as Button
		if button.text == text and (not enabled_only or not button.disabled):
			return button
	for child in node.get_children():
		var found := _find_button_by_text(child, text, enabled_only)
		if found != null:
			return found
	return null

func _collect_label_text(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + "\n"
	for child in node.get_children():
		out += _collect_label_text(child)
	return out
