extends Gut

const InventoryScript := preload("res://src/core/resource/inventory.gd")

var _unit: Unit
var _inventory

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "EnhanceUnit"
	add_child(_unit)
	_inventory = InventoryScript.new()
	_inventory.name = "Inventory"
	add_child(_inventory)
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 50000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 5)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()
	if is_instance_valid(_inventory):
		_inventory.queue_free()

func _add_weapon(level: int = 0, quality: int = EquipmentDefinitions.Quality.BLUE) -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "test_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": quality,
		"enhancement_level": level,
	}))

func test_safe_zone_enhancement_always_succeeds() -> void:
	_add_weapon(3)
	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"test_blade", _inventory, false, 10)
	assert_true(result["success"])
	assert_eq(result["new_level"], 4)

func test_enhancement_cost_uses_inventory_peek_cost() -> void:
	_add_weapon(2)
	var cost: Dictionary = _unit.equipment_component.get_enhancement_cost(&"test_blade", _inventory)

	assert_eq(cost["gold"], 300)
	assert_eq(cost["materials"], 15)

func test_enhancement_shortage_reports_exact_missing_resources() -> void:
	_add_weapon(4)
	_inventory.deserialize({
		ResourceTypes.ResourceId.GOLD: 200,
		ResourceTypes.ResourceId.BASIC_MATERIAL: 3,
	})

	var shortage: Dictionary = _unit.equipment_component.get_enhancement_shortage(&"test_blade", _inventory)

	assert_eq(shortage["gold"], 300)
	assert_eq(shortage["materials"], 22)

func test_equipment_enhanced_signal_emits_after_attempt() -> void:
	_add_weapon(0)
	var events: Array = []
	var handler := func(item_id: String, level: int, success: bool) -> void:
		events.append({"item_id": item_id, "level": level, "success": success})
	GameEvents.equipment_enhanced.connect(handler)

	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"test_blade", _inventory, false, 10)

	GameEvents.equipment_enhanced.disconnect(handler)
	assert_true(result["success"])
	assert_eq(events.size(), 1)
	assert_eq(events[0]["item_id"], "test_blade")
	assert_eq(events[0]["level"], 1)
	assert_true(events[0]["success"])

func test_risk_zone_rates_follow_expected_curve() -> void:
	assert_eq(EquipmentDefinitions.get_success_rate(5), 0.70)
	assert_eq(EquipmentDefinitions.get_success_rate(9), 0.30)
	assert_true(EquipmentDefinitions.get_success_rate(9) < EquipmentDefinitions.get_success_rate(5))

func test_failure_without_protection_downgrades_by_five() -> void:
	_add_weapon(7)
	for seed in range(1, 400):
		var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"test_blade", _inventory, false, seed)
		if result["result"] == "downgraded":
			assert_false(result["success"])
			assert_eq(result["new_level"], 2)
			return
		_unit.equipment_component.get_item(&"test_blade").enhancement_level = 7
	assert_true(false, "expected at least one downgrade outcome")

func test_failure_with_protection_keeps_level_and_consumes_symbol() -> void:
	_add_weapon(7)
	var initial_symbols: int = _inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL)
	for seed in range(1, 400):
		var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"test_blade", _inventory, true, seed)
		if result["result"] == "protected":
			assert_false(result["success"])
			assert_eq(result["new_level"], 7)
			assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), initial_symbols - 1)
			return
		_unit.equipment_component.get_item(&"test_blade").enhancement_level = 7
		_inventory.deserialize({
			ResourceTypes.ResourceId.GOLD: 50000,
			ResourceTypes.ResourceId.BASIC_MATERIAL: 500,
			ResourceTypes.ResourceId.PROTECT_SYMBOL: initial_symbols,
		})
	assert_true(false, "expected at least one protected failure outcome")

func test_cannot_enhance_beyond_quality_cap() -> void:
	_add_weapon(5, EquipmentDefinitions.Quality.WHITE)
	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"test_blade", _inventory, false, 1)
	assert_false(result["success"])
	assert_eq(result["reason"], "at_cap")
