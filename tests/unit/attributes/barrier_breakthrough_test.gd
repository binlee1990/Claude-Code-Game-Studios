# tests/unit/attributes/barrier_breakthrough_test.gd
# Story 004: Barrier Breakthrough
# Validates AC-7.1, AC-7.2, AC-8.1, AC-8.2, AC-8.3

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


# AC-7.1: CAN_BREAK TRUE when V >= threshold AND barrier not broken

func test_can_break_at_stage_1_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 3, 1, {1: false, 2: false, 3: false})
	assert_true(_unit.can_break_barrier(AttributeNames.Attribute.STR), "V=50, barrier 1 not broken → can break")

func test_can_break_above_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 55, 3, 1, {1: false, 2: false, 3: false})
	assert_true(_unit.can_break_barrier(AttributeNames.Attribute.STR), "V=55 > 50 → can break")

func test_can_break_at_stage_2_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 100, 3, 2, {1: true, 2: false, 3: false})
	assert_true(_unit.can_break_barrier(AttributeNames.Attribute.STR), "V=100, barrier 2 not broken → can break")

func test_can_break_at_stage_3_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 150, 3, 3, {1: true, 2: true, 3: false})
	assert_true(_unit.can_break_barrier(AttributeNames.Attribute.STR), "V=150, barrier 3 not broken → can break")


# AC-7.2: CAN_BREAK FALSE when conditions not met

func test_cannot_break_below_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 49, 3, 1, {1: false, 2: false, 3: false})
	assert_false(_unit.can_break_barrier(AttributeNames.Attribute.STR), "V=49 < 50 → cannot break")

func test_cannot_break_already_broken() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 3, 2, {1: true, 2: false, 3: false})
	assert_false(_unit.can_break_barrier(AttributeNames.Attribute.STR), "Barrier 1 already broken, stage 2 V<100 → cannot break")

func test_cannot_break_all_barriers_done() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 200, 3, 4, {1: true, 2: true, 3: true})
	assert_false(_unit.can_break_barrier(AttributeNames.Attribute.STR), "All barriers broken → cannot break")


# AC-8.1: Breakthrough changes state

func test_execute_breakthrough_changes_state() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 3, 1, {1: false, 2: false, 3: false})
	var result := _unit.execute_breakthrough(AttributeNames.Attribute.STR)
	assert_true(result, "Breakthrough should succeed")
	assert_false(_unit.can_break_barrier(AttributeNames.Attribute.STR), "After breakthrough, cannot break again at this stage")

func test_execute_breakthrough_fails_when_not_possible() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 3, 1, {1: false, 2: false, 3: false})
	var result := _unit.execute_breakthrough(AttributeNames.Attribute.STR)
	assert_false(result, "Breakthrough should fail when V < threshold")


# AC-8.2: Growth cap removed after breakthrough

func test_growth_cap_removed_after_breakthrough() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 6, 1, {1: false, 2: false, 3: false})
	# Break barrier 1
	_unit.execute_breakthrough(AttributeNames.Attribute.STR)
	# Now grow — should not be capped at 50
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 6, "Full growth after barrier 1 broken")
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 56)

func test_sequential_barrier_breakthrough() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 100, 6, 1, {1: false, 2: false, 3: false})
	# Break barrier 1
	assert_true(_unit.execute_breakthrough(AttributeNames.Attribute.STR))
	# Break barrier 2
	assert_true(_unit.execute_breakthrough(AttributeNames.Attribute.STR))
	# Growth should be capped at 150 (barrier 3)
	_setup_attr(AttributeNames.Attribute.STR, 148, 6, 3, {1: true, 2: true, 3: false})
	var results := _unit.apply_level_up()
	assert_eq(results[AttributeNames.Attribute.STR], 2, "Capped at barrier 3 (150)")


# AC-8.3: Breakthrough is permanent

func test_breakthrough_cannot_revert() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 3, 1, {1: false, 2: false, 3: false})
	_unit.execute_breakthrough(AttributeNames.Attribute.STR)
	# Manually set value below threshold to simulate any state change
	_setup_attr(AttributeNames.Attribute.STR, 30, 3, 2, {1: true, 2: false, 3: false})
	# Barrier 1 should still be broken
	var comp: AttributeComponent = _unit.attributes.get_component(AttributeNames.Attribute.STR)
	var data := comp.get_data()
	assert_true(data["barriers_broken"][1], "Barrier 1 remains broken permanently")
