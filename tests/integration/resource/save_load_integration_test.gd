# tests/integration/resource/save_load_integration_test.gd
# Story 006: Resource Save/Load Integration
# Validates AC-S1 through AC-S4

extends Gut

const InventoryScript := preload("res://src/core/resource/inventory.gd")

var _inventory

func before_each() -> void:
	_inventory = _new_inventory("Inventory")

func after_each() -> void:
	if is_instance_valid(_inventory):
		_inventory.queue_free()

func _new_inventory(node_name: String):
	var inventory = InventoryScript.new()
	inventory.name = node_name
	add_child(inventory)
	return inventory

func _setup_complex_inventory() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 300)
	_inventory.add_resource(ResourceTypes.ResourceId.FRUIT_STR, 5)
	_inventory.add_resource(ResourceTypes.ResourceId.FRUIT_AGI, 3)
	_inventory.add_resource(ResourceTypes.ResourceId.RARE_MATERIAL, 10)
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 2)
	_inventory.add_resource(ResourceTypes.ResourceId.BARRIER_RESOURCE, 1)
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 3500)


# AC-S1: Full inventory round-trip

func test_full_inventory_round_trip() -> void:
	_setup_complex_inventory()
	var data: Dictionary = _inventory.serialize()

	var loaded = _new_inventory("Loaded")
	loaded.deserialize(data)

	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.GOLD), 5000)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 300)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.FRUIT_STR), 5)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.FRUIT_AGI), 3)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.RARE_MATERIAL), 10)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), 2)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.BARRIER_RESOURCE), 1)
	loaded.queue_free()


# AC-S2: Achievement points round-trip

func test_achievement_points_round_trip() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 3500)
	var data: Dictionary = _inventory.serialize()

	var loaded = _new_inventory("Loaded")
	loaded.deserialize(data)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.ACHIEVEMENT), 3500)
	loaded.queue_free()

func test_achievement_large_value() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.ACHIEVEMENT, 9999999)
	var data: Dictionary = _inventory.serialize()

	var loaded = _new_inventory("Loaded")
	loaded.deserialize(data)
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.ACHIEVEMENT), 9999999)
	loaded.queue_free()


# AC-S3: Stack limit state preserved (no post-load overflow)

func test_no_overflow_after_load() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 9999999)
	var data: Dictionary = _inventory.serialize()

	var loaded = _new_inventory("Loaded")
	loaded.deserialize(data)

	# Try adding more — should be blocked
	var added: int = loaded.add_resource(ResourceTypes.ResourceId.GOLD, 100)
	assert_eq(added, 0, "Cannot add past cap after load")
	assert_eq(loaded.get_amount(ResourceTypes.ResourceId.GOLD), 9999999)
	loaded.queue_free()


# AC-S4: Double round-trip integrity

func test_double_round_trip() -> void:
	_setup_complex_inventory()

	var saved1: Dictionary = _inventory.serialize()
	var loaded1 = _new_inventory("L1")
	loaded1.deserialize(saved1)

	var saved2: Dictionary = loaded1.serialize()
	var loaded2 = _new_inventory("L2")
	loaded2.deserialize(saved2)

	# Compare all resources
	var all_res: Array = ResourceTypes.all_resource_ids()
	for res in all_res:
		assert_eq(loaded2.get_amount(res), loaded1.get_amount(res),
			"%s identical across round-trips" % ResourceTypes.get_resource_name(res))

	loaded1.queue_free()
	loaded2.queue_free()

func test_all_fruits_round_trip() -> void:
	var fruits: Array[int] = [
		ResourceTypes.ResourceId.FRUIT_STR, ResourceTypes.ResourceId.FRUIT_AGI,
		ResourceTypes.ResourceId.FRUIT_CON, ResourceTypes.ResourceId.FRUIT_INT,
		ResourceTypes.ResourceId.FRUIT_CHA, ResourceTypes.ResourceId.FRUIT_LUK,
		ResourceTypes.ResourceId.FRUIT_WIL, ResourceTypes.ResourceId.FRUIT_RES,
		ResourceTypes.ResourceId.FRUIT_SOU,
	]
	for i in fruits.size():
		_inventory.add_resource(fruits[i], (i + 1) * 5)

	var data: Dictionary = _inventory.serialize()
	var loaded = _new_inventory("Loaded")
	loaded.deserialize(data)

	for i in fruits.size():
		assert_eq(loaded.get_amount(fruits[i]), (i + 1) * 5,
			"%s preserved" % ResourceTypes.get_resource_name(fruits[i]))
	loaded.queue_free()
