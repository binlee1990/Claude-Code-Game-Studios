# tests/unit/resource/consumption_costs_test.gd
# Story 004: Resource Consumption & Costs
# Validates AC.3.1 through AC.3.4, AC.5.1-5.4

extends Gut

var _inventory: Inventory

func before_each() -> void:
	_inventory = Inventory.new()
	_inventory.name = "Inventory"
	add_child(_inventory)

func after_each() -> void:
	if is_instance_valid(_inventory):
		_inventory.queue_free()


# AC.3.1: Gold purchase

func test_purchase_sufficient_gold() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 500)
	var result: bool = _inventory.remove_resource(ResourceTypes.Resource.GOLD, 200)
	assert_true(result)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 300)

func test_purchase_insufficient_gold() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	var result: bool = _inventory.remove_resource(ResourceTypes.Resource.GOLD, 200)
	assert_false(result)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 100, "Gold unchanged")


# AC.3.2: Enhancement cost formula

func test_enhancement_cost_plus4_to_5() -> void:
	var cost: Dictionary = ResourceFormulas.calculate_enhancement_cost(100, 4)
	assert_eq(cost["gold"], 500, "100 * (4+1) = 500")
	assert_eq(cost["materials"], 25, "5 * 5 = 25")

func test_enhancement_cost_plus0_to_1() -> void:
	var cost: Dictionary = ResourceFormulas.calculate_enhancement_cost(100, 0)
	assert_eq(cost["gold"], 100, "100 * 1 = 100")
	assert_eq(cost["materials"], 5)

func test_enhancement_cost_plus9_to_10() -> void:
	var cost: Dictionary = ResourceFormulas.calculate_enhancement_cost(100, 9)
	assert_eq(cost["gold"], 1000, "100 * 10 = 1000")
	assert_eq(cost["materials"], 50, "5 * 10 = 50")

func test_enhancement_deducts_resources() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 1000)
	_inventory.add_resource(ResourceTypes.Resource.BASIC_MATERIAL, 100)
	var cost: Dictionary = ResourceFormulas.calculate_enhancement_cost(100, 4)
	assert_true(_inventory.remove_resource(ResourceTypes.Resource.GOLD, cost["gold"]))
	assert_true(_inventory.remove_resource(ResourceTypes.Resource.BASIC_MATERIAL, cost["materials"]))
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 500)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.BASIC_MATERIAL), 75)

func test_insufficient_materials_prevents_enhancement() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 1000)
	_inventory.add_resource(ResourceTypes.Resource.BASIC_MATERIAL, 10)
	var cost: Dictionary = ResourceFormulas.calculate_enhancement_cost(100, 4)
	assert_false(_inventory.remove_resource(ResourceTypes.Resource.BASIC_MATERIAL, cost["materials"]),
		"Not enough materials")


# AC.3.3: Fruit consumption

func test_consume_fruit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 3)
	var result: bool = _inventory.remove_resource(ResourceTypes.Resource.FRUIT_STR, 1)
	assert_true(result)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.FRUIT_STR), 2)

func test_consume_fruit_insufficient() -> void:
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 0)
	assert_false(_inventory.remove_resource(ResourceTypes.Resource.FRUIT_STR, 1))

func test_consume_fruit_correct_type() -> void:
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 5)
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_AGI, 5)
	_inventory.remove_resource(ResourceTypes.Resource.FRUIT_STR, 1)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.FRUIT_STR), 4)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.FRUIT_AGI), 5, "AGI fruit untouched")


# AC.3.4: Protection symbol

func test_protection_symbol_available() -> void:
	_inventory.add_resource(ResourceTypes.Resource.PROTECT_SYMBOL, 3)
	assert_true(_inventory.has_resource(ResourceTypes.Resource.PROTECT_SYMBOL, 1))

func test_consume_protection_symbol() -> void:
	_inventory.add_resource(ResourceTypes.Resource.PROTECT_SYMBOL, 1)
	_inventory.remove_resource(ResourceTypes.Resource.PROTECT_SYMBOL, 1)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.PROTECT_SYMBOL), 0)


# AC.5.1-5.2: Barrier resource consumption

func test_consume_barrier_resource() -> void:
	_inventory.add_resource(ResourceTypes.Resource.BARRIER_RESOURCE, 1)
	var result: bool = _inventory.remove_resource(ResourceTypes.Resource.BARRIER_RESOURCE, 1)
	assert_true(result)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.BARRIER_RESOURCE), 0)

func test_insufficient_barrier_resource() -> void:
	assert_false(_inventory.remove_resource(ResourceTypes.Resource.BARRIER_RESOURCE, 1),
		"No barrier resources available")


# Enhancement success rates

func test_safe_zone_always_succeeds() -> void:
	for level in range(5):
		var result: Dictionary = ResourceFormulas.execute_enhancement(level, false, level + 1)
		assert_eq(result["result"], ResourceFormulas.EnhancementResult.SUCCESS,
			"Level +%d always succeeds" % level)

func test_risk_zone_has_success_rate() -> void:
	assert_true(ResourceFormulas.get_enhancement_success_rate(5) < 1.0, "Not 100%% at +6")
	assert_eq(ResourceFormulas.get_enhancement_success_rate(5), 0.7, "70%% at +6")
