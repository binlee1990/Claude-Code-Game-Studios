# tests/unit/attributes/growth_formula_test.gd
# Story 002: Per-Level Growth Formula
# Validates AC-2.1, AC-3.1, AC-3.2, AC-14.1 from design/gdd/attribute-growth-system.md

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


# AC-2.1: V_new = V_old + P_current

func test_basic_growth_p3() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 3, 2, {1: true, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 3, "Growth = P(3)")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 51)

func test_min_growth_p1() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 1, 2, {1: true, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 1, "P=E(1) gives +1")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 49)

func test_max_growth_p6() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 6, 2, {1: true, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 6, "P=S(6) gives +6")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 54)


# AC-3.1: Before barrier breakthrough, V_new = min(V_old + P, BARRIER_LIMIT)

func test_growth_capped_by_barrier_1() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 6, 1, {1: false, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 2, "48+6=54 capped at 50, growth=2")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 50)

func test_no_growth_at_barrier_limit() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 1, 1, {1: false, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 0, "No growth at barrier limit")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 50)

func test_growth_capped_by_barrier_2() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 97, 6, 2, {1: true, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 3, "97+6=103 capped at 100, growth=3")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 100)

func test_growth_capped_by_barrier_3() -> void:
	_setup_attr(AttributeNames.Attribute.CON, 148, 6, 3, {1: true, 2: true, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.CON], 2, "148+6=154 capped at 150, growth=2")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.CON), 150)


# AC-3.2: After barrier breakthrough, V_new = min(V_old + P, 999)

func test_growth_after_barrier_1_broken() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 6, 2, {1: true, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 6, "No cap except next barrier")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 56)

func test_growth_after_all_barriers_broken() -> void:
	_setup_attr(AttributeNames.Attribute.AGI, 140, 5, 4, {1: true, 2: true, 3: true})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.AGI], 5, "All barriers broken, full growth")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.AGI), 145)


# AC-14.1: V_new never exceeds 999

func test_hard_cap_999() -> void:
	_setup_attr(AttributeNames.Attribute.INT, 997, 6, 4, {1: true, 2: true, 3: true})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.INT], 2, "997+6=1003 capped at 999, growth=2")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.INT), 999)

func test_no_growth_at_999() -> void:
	_setup_attr(AttributeNames.Attribute.INT, 999, 6, 4, {1: true, 2: true, 3: true})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.INT], 0, "Already at 999, no growth")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.INT), 999)

func test_barrier_and_999_both_cap() -> void:
	# Barrier cap is lower than 999, so barrier cap wins
	_setup_attr(AttributeNames.Attribute.CHA, 48, 6, 1, {1: false, 2: false, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.CHA], 2, "Barrier cap applies, not 999")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.CHA), 50)
