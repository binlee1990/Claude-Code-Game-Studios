# tests/unit/attributes/fruit_system_test.gd
# Story 003: Fruit System (Potential Upgrade)
# Validates AC-4.1, AC-4.2, AC-5.1, AC-6.1 from design/gdd/attribute-growth-system.md

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _setup_attr(attr: int, value: int, potential: int, barrier_stage: int, barriers_broken: Dictionary) -> void:
	var comp: AttributeComponent = _unit.attributes.get_component(attr)
	comp.load_data({
		"value": value,
		"potential": potential,
		"barrier_stage": barrier_stage,
		"barriers_broken": barriers_broken,
		"thresholds_reached": {}
	})


# AC-4.1: Fruit raises potential by 1 tier

func test_fruit_e_to_d() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 1, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result, "Fruit should succeed P=E→D")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 2, "P should be D(2)")

func test_fruit_d_to_c() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 2, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result, "Fruit should succeed P=D→C")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 3, "P should be C(3)")

func test_fruit_a_to_s() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 5, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result, "Fruit should succeed P=A→S")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 6, "P should be S(6)")

func test_fruit_on_hidden_attribute() -> void:
	_setup_attr(AttributeNames.Attribute.LUK, 30, 1, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.LUK)
	assert_true(result, "Fruit works on hidden attributes")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.LUK), 2)


# AC-4.2: Fruit only affects target attribute

func test_fruit_only_affects_target() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 1, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result)
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 2, "STR P changed")
	# All other attributes should remain at default E(1)
	for attr: int in AttributeNames.ALL_ATTRIBUTES:
		if attr != AttributeNames.Attribute.STR:
			assert_eq(_unit.get_potential(attr), 1, \
				"Attribute %d should remain P=E(1)" % attr)


# AC-5.1: Fruit rejected at max potential S(6)

func test_fruit_rejected_at_s() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 6, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_false(result, "Fruit should be rejected at P=S")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 6, "P should remain S(6)")

func test_can_use_fruit_false_at_s() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 30, 6, 1, {1: false, 2: false, 3: false})
	var comp: AttributeComponent = _unit.attributes.get_component(AttributeNames.Attribute.STR)
	assert_false(comp.can_use_fruit(), "can_use_fruit should be false at P=S")


# AC-6.1: Fruit rejected at barrier cap (V >= barrier limit, barrier not broken)

func test_fruit_rejected_at_barrier_1_cap() -> void:
	# V=50, barrier 1 not broken (limit=50)
	_setup_attr(AttributeNames.Attribute.STR, 50, 2, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_false(result, "Fruit rejected when V=50 at barrier 1")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 2, "P unchanged")

func test_fruit_succeeds_below_barrier_cap() -> void:
	# V=49, barrier 1 not broken (limit=50)
	_setup_attr(AttributeNames.Attribute.STR, 49, 2, 1, {1: false, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result, "Fruit succeeds when V=49 < barrier 50")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 3, "P raised")

func test_fruit_succeeds_after_barrier_broken() -> void:
	# V=50, barrier 1 broken, barrier 2 not broken
	_setup_attr(AttributeNames.Attribute.STR, 50, 2, 2, {1: true, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_true(result, "Fruit succeeds after barrier 1 broken, even at V=50")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 3)

func test_fruit_rejected_at_barrier_2_cap() -> void:
	# V=100, barrier 1 broken, barrier 2 not broken
	_setup_attr(AttributeNames.Attribute.STR, 100, 3, 2, {1: true, 2: false, 3: false})
	var result := _unit.use_fruit(AttributeNames.Attribute.STR)
	assert_false(result, "Fruit rejected at barrier 2 cap V=100")
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 3, "P unchanged")

func test_fruit_on_invalid_attribute() -> void:
	var result := _unit.use_fruit(-999)
	assert_false(result, "Fruit on invalid attribute should return false")
