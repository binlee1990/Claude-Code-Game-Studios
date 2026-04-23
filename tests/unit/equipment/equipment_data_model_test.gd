extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "EquipmentUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func test_slot_constraint_replaces_equipped_item() -> void:
	var first := EquipmentItem.new({"item_id": "bronze_sword", "slot": EquipmentDefinitions.Slot.WEAPON})
	var second := EquipmentItem.new({"item_id": "iron_sword", "slot": EquipmentDefinitions.Slot.WEAPON})
	_unit.equipment_component.add_item(first)
	_unit.equipment_component.add_item(second)

	_unit.equipment_component.equip_item(&"bronze_sword")
	var result: Dictionary = _unit.equipment_component.equip_item(&"iron_sword")

	assert_true(result["success"])
	assert_eq(result["replaced_item_id"], &"bronze_sword")
	assert_eq(_unit.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.WEAPON).item_id, &"iron_sword")
	assert_true(_unit.equipment_component.get_item(&"bronze_sword") != null)

func test_quality_affix_capacity_mapping() -> void:
	assert_eq(EquipmentDefinitions.get_affix_capacity(EquipmentDefinitions.Quality.WHITE), 1)
	assert_eq(EquipmentDefinitions.get_affix_capacity(EquipmentDefinitions.Quality.GREEN), 2)
	assert_eq(EquipmentDefinitions.get_affix_capacity(EquipmentDefinitions.Quality.BLUE), 3)
	assert_eq(EquipmentDefinitions.get_affix_capacity(EquipmentDefinitions.Quality.PURPLE), 4)
	assert_eq(EquipmentDefinitions.get_affix_capacity(EquipmentDefinitions.Quality.GOLD), 4)

func test_gold_item_gets_set_assignment() -> void:
	var item := EquipmentItem.new({
		"item_id": "gold_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.GOLD,
		"rng_seed": 77,
	})
	assert_ne(item.set_id, EquipmentDefinitions.NO_SET)

func test_base_attributes_generated_in_quality_range() -> void:
	var blue := EquipmentItem.new({
		"item_id": "blue_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"rng_seed": 11,
	})
	var gold := EquipmentItem.new({
		"item_id": "gold_ring",
		"slot": EquipmentDefinitions.Slot.ACCESSORY,
		"quality": EquipmentDefinitions.Quality.GOLD,
		"rng_seed": 13,
	})
	assert_true(blue.base_attributes["attack"] >= 18 and blue.base_attributes["attack"] <= 30)
	assert_true(gold.base_attributes["focus"] >= 45 and gold.base_attributes["focus"] <= 70)
