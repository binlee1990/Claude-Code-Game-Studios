# tests/unit/resource/data_model_inventory_test.gd
# Story 001: Resource Data Model & Inventory
# Validates AC.1.1 through AC.1.3

extends Gut

var _inventory: Inventory

func before_each() -> void:
	_inventory = Inventory.new()
	_inventory.name = "Inventory"
	add_child(_inventory)

func after_each() -> void:
	if is_instance_valid(_inventory):
		_inventory.queue_free()


# Basic operations

func test_initial_all_zero() -> void:
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 0)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.BASIC_MATERIAL), 0)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.RARE_MATERIAL), 0)

func test_add_resource() -> void:
	var added: int = _inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	assert_eq(added, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 100)

func test_remove_resource() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	var result: bool = _inventory.remove_resource(ResourceTypes.Resource.GOLD, 30)
	assert_true(result)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 70)

func test_remove_insufficient_returns_false() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 50)
	assert_false(_inventory.remove_resource(ResourceTypes.Resource.GOLD, 100))
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 50, "Amount unchanged")

func test_has_resource() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	assert_true(_inventory.has_resource(ResourceTypes.Resource.GOLD, 100))
	assert_true(_inventory.has_resource(ResourceTypes.Resource.GOLD, 50))
	assert_false(_inventory.has_resource(ResourceTypes.Resource.GOLD, 101))

func test_add_zero_returns_zero() -> void:
	assert_eq(_inventory.add_resource(ResourceTypes.Resource.GOLD, 0), 0)
	assert_eq(_inventory.add_resource(ResourceTypes.Resource.GOLD, -5), 0)

func test_remove_zero_returns_true() -> void:
	assert_true(_inventory.remove_resource(ResourceTypes.Resource.GOLD, 0))


# Signal emission

func test_resource_changed_signal() -> void:
	var signals: Array = []
	_inventory.resource_changed.connect(func(r, o, n): signals.append({"r": r, "o": o, "n": n}))
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 50)
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["r"], ResourceTypes.Resource.GOLD)
	assert_eq(signals[0]["o"], 0)
	assert_eq(signals[0]["n"], 50)

func test_signal_on_remove() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	var signals: Array = []
	_inventory.resource_changed.connect(func(r, o, n): signals.append({"o": o, "n": n}))
	_inventory.remove_resource(ResourceTypes.Resource.GOLD, 30)
	assert_eq(signals[0]["o"], 100)
	assert_eq(signals[0]["n"], 70)


# AC.1.2: Stack limit enforcement

func test_gold_stack_limit() -> void:
	var added: int = _inventory.add_resource(ResourceTypes.Resource.GOLD, 99999999)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 9999999)
	assert_eq(added, 9999999)
	assert_eq(99999999 - 9999999, 90000000)

func test_gold_near_cap_then_overflow() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 9999998)
	var added: int = _inventory.add_resource(ResourceTypes.Resource.GOLD, 5)
	assert_eq(added, 1, "Only 1 fits")
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 9999999)

func test_gold_at_cap_no_gain() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 9999999)
	var added: int = _inventory.add_resource(ResourceTypes.Resource.GOLD, 100)
	assert_eq(added, 0, "No gain when at cap")
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.GOLD), 9999999)

func test_basic_material_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.BASIC_MATERIAL, 99999)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.BASIC_MATERIAL), 9999)

func test_fruit_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 98)
	var added: int = _inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 3)
	assert_eq(added, 1, "Only 1 fits")
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.FRUIT_STR), 99)

func test_rare_material_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.RARE_MATERIAL, 9999)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.RARE_MATERIAL), 999)

func test_protect_symbol_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.PROTECT_SYMBOL, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.PROTECT_SYMBOL), 99)

func test_barrier_resource_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.BARRIER_RESOURCE, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.BARRIER_RESOURCE), 99)

func test_overflow_signal() -> void:
	var overflows: Array = []
	_inventory.resource_overflow.connect(func(r, d): overflows.append({"r": r, "d": d}))
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 99999999)
	assert_eq(overflows.size(), 1)
	assert_eq(overflows[0]["r"], ResourceTypes.Resource.GOLD)
	assert_eq(overflows[0]["d"], 90000000)


# AC.1.3: Achievement points unlimited

func test_achievement_no_limit() -> void:
	_inventory.add_resource(ResourceTypes.Resource.ACHIEVEMENT, 999999)
	var added: int = _inventory.add_resource(ResourceTypes.Resource.ACHIEVEMENT, 100)
	assert_eq(added, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.ACHIEVEMENT), 1000099)

func test_achievement_accumulates_large() -> void:
	_inventory.add_resource(ResourceTypes.Resource.ACHIEVEMENT, 9999999)
	_inventory.add_resource(ResourceTypes.Resource.ACHIEVEMENT, 9999999)
	assert_eq(_inventory.get_amount(ResourceTypes.Resource.ACHIEVEMENT), 19999998)


# AC.1.1: Serialization round-trip

func test_serialization_round_trip() -> void:
	_inventory.add_resource(ResourceTypes.Resource.GOLD, 5000)
	_inventory.add_resource(ResourceTypes.Resource.BASIC_MATERIAL, 300)
	_inventory.add_resource(ResourceTypes.Resource.FRUIT_STR, 10)
	_inventory.add_resource(ResourceTypes.Resource.ACHIEVEMENT, 2500)

	var data: Dictionary = _inventory.serialize()
	var loaded := Inventory.new()
	loaded.name = "LoadedInv"
	add_child(loaded)
	loaded.deserialize(data)

	assert_eq(loaded.get_amount(ResourceTypes.Resource.GOLD), 5000)
	assert_eq(loaded.get_amount(ResourceTypes.Resource.BASIC_MATERIAL), 300)
	assert_eq(loaded.get_amount(ResourceTypes.Resource.FRUIT_STR), 10)
	assert_eq(loaded.get_amount(ResourceTypes.Resource.ACHIEVEMENT), 2500)
	assert_eq(loaded.get_amount(ResourceTypes.Resource.RARE_MATERIAL), 0)
	loaded.queue_free()

func test_all_fruit_types_tracked_separately() -> void:
	var fruits: Array[int] = [
		ResourceTypes.Resource.FRUIT_STR, ResourceTypes.Resource.FRUIT_AGI,
		ResourceTypes.Resource.FRUIT_CON, ResourceTypes.Resource.FRUIT_INT,
		ResourceTypes.Resource.FRUIT_CHA, ResourceTypes.Resource.FRUIT_LUK,
		ResourceTypes.Resource.FRUIT_WIL, ResourceTypes.Resource.FRUIT_RES,
		ResourceTypes.Resource.FRUIT_SOU,
	]
	for i in fruits.size():
		_inventory.add_resource(fruits[i], (i + 1) * 5)

	for i in fruits.size():
		assert_eq(_inventory.get_amount(fruits[i]), (i + 1) * 5,
			"%s = %d" % [ResourceTypes.Resource.keys()[fruits[i]], (i + 1) * 5])

func test_is_fruit_helper() -> void:
	assert_true(ResourceTypes.is_fruit(ResourceTypes.Resource.FRUIT_STR))
	assert_false(ResourceTypes.is_fruit(ResourceTypes.Resource.GOLD))

func test_fruit_to_attr_helper() -> void:
	assert_eq(ResourceTypes.fruit_to_attr(ResourceTypes.Resource.FRUIT_STR), AttributeNames.Attribute.STR)
	assert_eq(ResourceTypes.fruit_to_attr(ResourceTypes.Resource.FRUIT_SOU), AttributeNames.Attribute.SOU)
