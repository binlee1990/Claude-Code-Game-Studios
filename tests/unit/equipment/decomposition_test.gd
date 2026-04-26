extends Gut

const InventoryScript := preload("res://src/core/resource/inventory.gd")

var _unit: Unit
var _inventory

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "DecomposeUnit"
	add_child(_unit)
	_inventory = InventoryScript.new()
	_inventory.name = "Inventory"
	add_child(_inventory)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()
	if is_instance_valid(_inventory):
		_inventory.queue_free()

func _add_item(item_id: String, quality: int, level: int = 0) -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": item_id,
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": quality,
		"enhancement_level": level,
	}))

func test_gold_decomposition_guarantees_rare_materials() -> void:
	_add_item("gold_blade", EquipmentDefinitions.Quality.GOLD, 12)
	var result: Dictionary = _unit.equipment_component.decompose_item(&"gold_blade", _inventory, 1)
	assert_true(result["success"])
	assert_eq(result["basic_materials"], 50)
	assert_eq(result["rare_materials"], 5)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 50)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.RARE_MATERIAL), 5)

func test_enhancement_level_does_not_change_output() -> void:
	_add_item("white_a", EquipmentDefinitions.Quality.WHITE, 0)
	_add_item("white_b", EquipmentDefinitions.Quality.WHITE, 5)
	var first: Dictionary = _unit.equipment_component.decompose_item(&"white_a", null, 2)
	var second: Dictionary = _unit.equipment_component.decompose_item(&"white_b", null, 3)
	assert_eq(first["basic_materials"], second["basic_materials"])
	assert_eq(first["rare_materials"], second["rare_materials"])

func test_decomposed_item_removed_from_equipment_inventory() -> void:
	_add_item("blue_blade", EquipmentDefinitions.Quality.BLUE, 4)
	assert_true(_unit.equipment_component.get_item(&"blue_blade") != null)
	_unit.equipment_component.decompose_item(&"blue_blade", _inventory, 10)
	assert_true(_unit.equipment_component.get_item(&"blue_blade") == null)
