extends Gut

var _screen: CharacterManagement
var _roster: CharacterRoster
var _unit: Unit

func before_each() -> void:
	Inventory.reset()
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 200)
	_roster = CharacterRoster.new()
	add_child(_roster)
	_unit = Unit.new()
	_unit.unit_id = &"P1"
	_unit.display_name = "Swordsman"
	add_child(_unit)
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "ui_blade",
		"name": "UI Blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"enhancement_level": 6,
		"affixes": [EquipmentAffixGenerator.generate_affix(EquipmentDefinitions.Quality.BLUE, EquipmentDefinitions.AffixType.STR, 1)],
	}))
	_unit.equipment_component.equip_item(&"ui_blade")
	_roster.add_character(_unit, CharacterRoster.Status.DEPLOYED)
	_roster.set_party([_unit.unit_id])
	_screen = load("res://src/ui/management/character_management_screen.tscn").instantiate()
	add_child(_screen)
	_screen.initialize(_roster)
	_screen._selected_unit_id = _unit.unit_id
	_screen._reroll_rng_seed = 7
	_screen._decompose_rng_seed = 1

func after_each() -> void:
	Inventory.reset()
	if is_instance_valid(_screen):
		_screen.queue_free()
	if is_instance_valid(_roster):
		_roster.queue_free()
	if is_instance_valid(_unit):
		_unit.queue_free()

func test_character_management_reroll_updates_item_and_emits_change() -> void:
	var emitted := {"count": 0}
	_screen.equipment_changed.connect(func(_unit_arg: Unit, _slot: int, _old_item_id: StringName, _new_item_id: StringName) -> void:
		emitted["count"] += 1
	)
	var old_affix: Dictionary = _unit.equipment_component.get_item(&"ui_blade").affixes[0].duplicate(true)
	_screen._on_reroll_item_pressed(_unit.unit_id, &"ui_blade", EquipmentDefinitions.Slot.WEAPON)

	assert_eq(emitted["count"], 1)
	assert_ne(_unit.equipment_component.get_item(&"ui_blade").affixes[0], old_affix)
	assert_eq(_unit.equipment_component.get_item(&"ui_blade").enhancement_level, 6)

func test_character_management_decompose_removes_item_and_returns_materials() -> void:
	var before_materials := Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	_screen._on_decompose_item_pressed(_unit.unit_id, &"ui_blade", EquipmentDefinitions.Slot.WEAPON)

	assert_eq(_unit.equipment_component.get_item(&"ui_blade"), null)
	assert_true(Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL) > before_materials)
