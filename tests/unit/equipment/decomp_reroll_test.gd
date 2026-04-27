extends Gut

const InventoryScript := preload("res://src/core/resource/inventory.gd")

var _unit: Unit
var _inventory

func before_each() -> void:
	_unit = Unit.new()
	add_child(_unit)
	_inventory = InventoryScript.new()
	add_child(_inventory)
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 200)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()
	if is_instance_valid(_inventory):
		_inventory.queue_free()

func _add_item(item_id: String, quality: int = EquipmentDefinitions.Quality.BLUE, level: int = 4) -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": item_id,
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": quality,
		"enhancement_level": level,
		"affixes": [EquipmentAffixGenerator.generate_affix(quality, EquipmentDefinitions.AffixType.STR, 1)],
	}))

func test_reroll_consumes_resources_and_preserves_enhancement_level() -> void:
	_add_item("blue_blade", EquipmentDefinitions.Quality.BLUE, 7)
	var result: Dictionary = _unit.equipment_component.reroll_affix(&"blue_blade", 0, _inventory, 22)

	assert_true(result["success"])
	assert_true(result["new_affix"]["value"] >= 8 and result["new_affix"]["value"] <= 24)
	assert_eq(result["enhancement_level"], 7)
	assert_eq(_unit.equipment_component.get_item(&"blue_blade").enhancement_level, 7)
	assert_true(_inventory.get_amount(ResourceTypes.ResourceId.GOLD) < 5000)
	assert_true(_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL) < 200)

func test_reroll_rejects_missing_affix_and_shortage() -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "plain",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.WHITE,
		"affixes": [],
	}))
	assert_eq(_unit.equipment_component.reroll_affix(&"plain", 0, _inventory, 1)["reason"], "missing_affix")

	_add_item("poor_blade")
	_inventory.deserialize({})
	assert_eq(_unit.equipment_component.reroll_affix(&"poor_blade", 0, _inventory, 1)["reason"], "insufficient_resources")

func test_decompose_and_reroll_round_trip_through_unit_serialization() -> void:
	_add_item("round_trip_blade", EquipmentDefinitions.Quality.PURPLE, 6)
	_unit.equipment_component.equip_item(&"round_trip_blade")
	_unit.equipment_component.reroll_affix(&"round_trip_blade", 0, _inventory, 31)
	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	add_child(loaded)
	loaded.deserialize(saved)
	assert_eq(loaded.equipment_component.get_item(&"round_trip_blade").enhancement_level, 6)
	assert_eq(loaded.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.WEAPON).item_id, &"round_trip_blade")
	loaded.equipment_component.decompose_item(&"round_trip_blade", _inventory, 1)
	assert_eq(loaded.equipment_component.get_item(&"round_trip_blade"), null)
	loaded.queue_free()
