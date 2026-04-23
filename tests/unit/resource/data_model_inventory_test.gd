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
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 0)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 0)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.RARE_MATERIAL), 0)

func test_add_resource() -> void:
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	assert_eq(added, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 100)

func test_remove_resource() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	var result: bool = _inventory.remove_resource(ResourceTypes.ResourceId.GOLD, 30)
	assert_true(result)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 70)

func test_remove_insufficient_returns_false() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 50)
	assert_false(_inventory.remove_resource(ResourceTypes.ResourceId.GOLD, 100))
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 50, "Amount unchanged")

func test_has_resource() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	assert_true(_inventory.has_resource(ResourceTypes.ResourceId.GOLD, 100))
	assert_true(_inventory.has_resource(ResourceTypes.ResourceId.GOLD, 50))
	assert_false(_inventory.has_resource(ResourceTypes.ResourceId.GOLD, 101))

func test_add_zero_returns_zero() -> void:
	assert_eq(_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 0), 0)
	assert_eq(_inventory.add_resource(ResourceTypes.ResourceId.GOLD, -5), 0)

func test_remove_zero_returns_true() -> void:
	assert_true(_inventory.remove_resource(ResourceTypes.ResourceId.GOLD, 0))


# Signal emission

func test_resource_changed_signal() -> void:
	var signals: Array = []
	_inventory.resource_changed.connect(func(r, o, n): signals.append({"r": r, "o": o, "n": n}))
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 50)
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["r"], ResourceTypes.ResourceId.GOLD)
	assert_eq(signals[0]["o"], 0)
	assert_eq(signals[0]["n"], 50)

func test_signal_on_remove() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	var signals: Array = []
	_inventory.resource_changed.connect(func(r, o, n): signals.append({"o": o, "n": n}))
	_inventory.remove_resource(ResourceTypes.ResourceId.GOLD, 30)
	assert_eq(signals[0]["o"], 100)
	assert_eq(signals[0]["n"], 70)


# AC.1.2: Stack limit enforcement

func test_gold_stack_limit() -> void:
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.GOLD, 99999999)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 9999999)
	assert_eq(added, 9999999)
	assert_eq(99999999 - 9999999, 90000000)

func test_gold_near_cap_then_overflow() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 9999998)
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5)
	assert_eq(added, 1, "Only 1 fits")
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 9999999)

func test_gold_at_cap_no_gain() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 9999999)
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	assert_eq(added, 0, "No gain when at cap")
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.GOLD), 9999999)

func test_basic_material_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 99999)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 9999)

func test_fruit_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.FRUIT_STR, 98)
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.FRUIT_STR, 3)
	assert_eq(added, 1, "Only 1 fits")
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.FRUIT_STR), 99)

func test_rare_material_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.RARE_MATERIAL, 9999)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.RARE_MATERIAL), 999)

func test_protect_symbol_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), 99)

func test_barrier_resource_stack_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.BARRIER_RESOURCE, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.BARRIER_RESOURCE), 99)

func test_overflow_signal() -> void:
	var overflows: Array = []
	_inventory.resource_overflow.connect(func(r, d): overflows.append({"r": r, "d": d}))
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 99999999)
	assert_eq(overflows.size(), 1)
	assert_eq(overflows[0]["r"], ResourceTypes.ResourceId.GOLD)
	assert_eq(overflows[0]["d"], 90000000)


# AC.1.3: Achievement points unlimited

func test_achievement_no_limit() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 999999)
	var added: int = _inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 100)
	assert_eq(added, 100)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.ACHIEVEMENT), 1000099)

func test_achievement_accumulates_large() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 9999999)
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 9999999)
	assert_eq(_inventory.get_amount(ResourceTypes.ResourceId.ACHIEVEMENT), 19999998)


# AC.1.1: Serialization round-trip

func test_serialization_round_trip() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 300)
	_inventory.add_resource(ResourceTypes.ResourceId.FRUIT_STR, 10)
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 2500)

	var data: Dictionary = _inventory.serialize()
	var loaded := Inventory.new()
	loaded.name = "LoadedInv"
	add_child(loaded)
	loaded.deserialize(data)

	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.GOLD), 5000)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 300)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.FRUIT_STR), 10)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.ACHIEVEMENT), 2500)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.RARE_MATERIAL), 0)
	loaded.queue_free()

func test_all_fruit_types_tracked_separately() -> void:
	var fruits: Array[int] = [
		ResourceTypes.ResourceId.FRUIT_STR, ResourceTypes.ResourceId.FRUIT_AGI,
		ResourceTypes.ResourceId.FRUIT_CON, ResourceTypes.ResourceId.FRUIT_INT,
		ResourceTypes.ResourceId.FRUIT_CHA, ResourceTypes.ResourceId.FRUIT_LUK,
		ResourceTypes.ResourceId.FRUIT_WIL, ResourceTypes.ResourceId.FRUIT_RES,
		ResourceTypes.ResourceId.FRUIT_SOU,
	]
	for i in fruits.size():
		_inventory.add_resource(fruits[i], (i + 1) * 5)

	for i in fruits.size():
		assert_eq(_inventory.get_amount(fruits[i]), (i + 1) * 5,
			"%s = %d" % [ResourceTypes.get_resource_name(fruits[i]), (i + 1) * 5])

func test_is_fruit_helper() -> void:
	assert_true(ResourceTypes.is_fruit(ResourceTypes.ResourceId.FRUIT_STR))
	assert_false(ResourceTypes.is_fruit(ResourceTypes.ResourceId.GOLD))

func test_fruit_to_attr_helper() -> void:
	assert_eq(ResourceTypes.fruit_to_attr(ResourceTypes.ResourceId.FRUIT_STR), AttributeNames.Attribute.STR)
	assert_eq(ResourceTypes.fruit_to_attr(ResourceTypes.ResourceId.FRUIT_SOU), AttributeNames.Attribute.SOU)
