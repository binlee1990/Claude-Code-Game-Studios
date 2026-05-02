extends Gut

# Sprint-009 / EQUIP-014: Equipment +11+ extreme-risk tuning
# Validates probability curves and protection symbol consumption for extreme risk zone.

const SAFE_ZONE_MAX: int = 5
const RISK_ZONE_MAX: int = 10
const EXTREME_ZONE_START: int = 11


func test_extreme_risk_zone_starts_at_11() -> void:
	assert_eq(EXTREME_ZONE_START, 11)


func test_extreme_risk_zone_above_risk_zone() -> void:
	assert_true(EXTREME_ZONE_START > RISK_ZONE_MAX)


const InventoryScript := preload("res://src/core/resource/inventory.gd")

var _unit: Unit
var _inventory

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "ExtremeRiskUnit"
	add_child(_unit)
	_inventory = InventoryScript.new()
	_inventory.name = "ExtremeRiskInventory"
	add_child(_inventory)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()
	if is_instance_valid(_inventory):
		_inventory.queue_free()

func _success_probability(level: int) -> float:
	return EquipmentDefinitions.get_success_rate(level)

func _protection_symbol_cost(level: int) -> int:
	return EquipmentDefinitions.get_protection_symbol_cost(level)


func test_extreme_risk_level_11_probability_positive() -> void:
	var prob: float = _success_probability(11)
	assert_true(prob > 0.0)
	assert_true(prob < 0.3)


func test_extreme_risk_level_15_probability_lower_than_11() -> void:
	var prob_11: float = _success_probability(11)
	var prob_15: float = _success_probability(15)
	assert_true(prob_15 <= prob_11)


func test_extreme_risk_probability_never_zero() -> void:
	for level: int in range(11, 21):
		var prob: float = _success_probability(level)
		assert_true(prob > 0.0)


func test_extreme_risk_probability_never_exceeds_safe_zone() -> void:
	for level: int in range(11, 21):
		var prob: float = _success_probability(level)
		assert_true(prob < 1.0)


func test_safe_zone_always_100_percent() -> void:
	for level: int in range(0, SAFE_ZONE_MAX):
		var prob: float = _success_probability(level)
		assert_eq(prob, 1.0)


func test_risk_zone_probability_bounds() -> void:
	var prob_6: float = _success_probability(6)
	var prob_10: float = _success_probability(10)
	assert_true(prob_6 > prob_10)
	assert_true(prob_6 > 0.4)
	assert_true(prob_10 > 0.1)


func test_extreme_risk_protection_cost_level_11() -> void:
	var cost: int = _protection_symbol_cost(11)
	assert_eq(cost, 2)


func test_extreme_risk_protection_cost_increases_with_level() -> void:
	var cost_11: int = _protection_symbol_cost(11)
	var cost_14: int = _protection_symbol_cost(14)
	assert_true(cost_14 > cost_11)


func test_extreme_risk_protection_cost_level_15() -> void:
	var cost: int = _protection_symbol_cost(15)
	assert_eq(cost, 6)

func test_extreme_risk_attempt_consumes_level_11_protection_cost() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 50000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 4)
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "extreme_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"enhancement_level": 11,
	}))
	var seed := _find_seed_for_result(&"extreme_blade", 11, "protected")
	assert_true(seed > 0)
	_unit.equipment_component.get_item(&"extreme_blade").enhancement_level = 11
	_inventory.deserialize({
		ResourceTypes.ResourceId.GOLD: 50000,
		ResourceTypes.ResourceId.BASIC_MATERIAL: 500,
		ResourceTypes.ResourceId.PROTECT_SYMBOL: 4,
	})

	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"extreme_blade", _inventory, true, seed)

	assert_eq(result.get("result", ""), "protected")
	assert_eq(result.get("protection_cost", 0), 2)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), 2)

func test_extreme_risk_attempt_blocks_when_symbols_are_short() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 50000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 1)
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "extreme_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"enhancement_level": 11,
	}))

	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"extreme_blade", _inventory, true, 1)

	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "insufficient_protection")
	assert_eq(_unit.equipment_component.get_item(&"extreme_blade").enhancement_level, 11)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), 1)

func _find_seed_for_result(item_id: StringName, level: int, expected_result: String) -> int:
	for seed in range(1, 500):
		_unit.equipment_component.get_item(item_id).enhancement_level = level
		_inventory.deserialize({
			ResourceTypes.ResourceId.GOLD: 50000,
			ResourceTypes.ResourceId.BASIC_MATERIAL: 500,
			ResourceTypes.ResourceId.PROTECT_SYMBOL: 4,
		})
		var result: Dictionary = _unit.equipment_component.attempt_enhancement(item_id, _inventory, true, seed)
		if String(result.get("result", "")) == expected_result:
			return seed
	return -1
