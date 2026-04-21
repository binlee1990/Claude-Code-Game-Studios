# tests/unit/attributes/threshold_rewards_test.gd
# Story 005: Threshold Rewards
# Validates AC-9.1, AC-9.2, AC-10.1, AC-15.1

extends Gut

var _unit: Unit
var _signals: Array

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	_unit.unit_id = &"char_5"
	add_child(_unit)
	_signals.clear()
	_unit.attributes.threshold_unlocked.connect(_on_threshold)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _on_threshold(attr_type: int, threshold: int) -> void:
	_signals.append({"attr_type": attr_type, "threshold": threshold})

func _setup_attr(attr: int, value: int, potential: int, barrier_stage: int, barriers_broken: Dictionary) -> void:
	var comp: AttributeComponent = _unit.attributes.get_component(attr)
	comp.load_data({
		"value": value,
		"potential": potential,
		"barrier_stage": barrier_stage,
		"barriers_broken": barriers_broken,
		"thresholds_reached": {}
	})


# AC-9.1: Threshold triggers at 50/100/150 for normal attributes

func test_threshold_50_triggered_on_growth() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 48, 3, 2, {1: true, 2: false, 3: false})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1, "One threshold signal")
	assert_eq(_signals[0]["threshold"], 50, "Threshold 50")
	assert_eq(_signals[0]["attr_type"], AttributeNames.Attribute.STR)

func test_threshold_100_triggered() -> void:
	_setup_attr(AttributeNames.Attribute.INT, 99, 2, 2, {1: true, 2: false, 3: false})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1)
	assert_eq(_signals[0]["threshold"], 100)

func test_threshold_150_triggered() -> void:
	_setup_attr(AttributeNames.Attribute.CHA, 148, 4, 3, {1: true, 2: true, 3: false})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1)
	assert_eq(_signals[0]["threshold"], 150)

func test_jump_across_threshold_still_triggers() -> void:
	# V=48, P=6 → V=54, crosses 50
	_setup_attr(AttributeNames.Attribute.AGI, 48, 6, 2, {1: true, 2: false, 3: false})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1)
	assert_eq(_signals[0]["threshold"], 50)

func test_multiple_thresholds_in_one_growth() -> void:
	# V=49, P=52 with all barriers broken → V=101, crosses both 50 and 100
	_setup_attr(AttributeNames.Attribute.CON, 49, 52, 4, {1: true, 2: true, 3: true})
	_unit.apply_level_up()
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.CON), 101)
	assert_eq(_signals.size(), 2, "Both 50 and 100 triggered")


# AC-9.2: Event includes correct context

func test_game_events_forwarded_with_unit() -> void:
	var ge_signals: Array = []
	var handler := func(unit: Node, attr_type: int, threshold: int) -> void:
		ge_signals.append({"unit": unit, "attr_type": attr_type, "threshold": threshold})
	GameEvents.threshold_unlocked.connect(handler)
	_setup_attr(AttributeNames.Attribute.INT, 99, 2, 2, {1: true, 2: false, 3: false})
	_unit.apply_level_up()
	GameEvents.threshold_unlocked.disconnect(handler)
	assert_eq(ge_signals.size(), 1)
	assert_eq(ge_signals[0]["unit"].unit_id, &"char_5", "Event includes unit with correct id")
	assert_eq(ge_signals[0]["attr_type"], AttributeNames.Attribute.INT)
	assert_eq(ge_signals[0]["threshold"], 100)


# AC-10.1: No repeat trigger

func test_no_repeat_on_stay_above_threshold() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 50, 3, 2, {1: true, 2: false, 3: false})
	# First growth: V=50→53, triggers 50
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1, "First trigger")
	# Second growth: V=53→56, no new trigger
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1, "No repeat trigger")

func test_no_repeat_after_value_fluctuation() -> void:
	_setup_attr(AttributeNames.Attribute.STR, 49, 2, 2, {1: true, 2: false, 3: false})
	# V=49→51, triggers 50
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1)
	# Force value below 50 then back
	var comp: AttributeComponent = _unit.attributes.get_component(AttributeNames.Attribute.STR)
	comp.load_data({"value": 30, "potential": 3, "barrier_stage": 2, "barriers_broken": {1: true, 2: false, 3: false}, "thresholds_reached": {50: true, 100: false, 150: false}})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 1, "Still no repeat after dropping below and rising again")


# AC-15.1: Hidden attributes excluded

func test_hidden_attribute_no_trigger() -> void:
	_setup_attr(AttributeNames.Attribute.LUK, 48, 3, 2, {1: true, 2: false, 3: false})
	_unit.apply_level_up()
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.LUK), 51, "LUK did grow to 51")
	assert_eq(_signals.size(), 0, "Hidden attribute triggers no reward")

func test_hidden_attribute_no_trigger_at_100() -> void:
	_setup_attr(AttributeNames.Attribute.WIL, 99, 2, 4, {1: true, 2: true, 3: true})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 0, "Hidden attribute at 100 — no trigger")

func test_hidden_attribute_no_trigger_at_150() -> void:
	_setup_attr(AttributeNames.Attribute.RES, 148, 4, 4, {1: true, 2: true, 3: true})
	_unit.apply_level_up()
	assert_eq(_signals.size(), 0, "Hidden attribute at 150 — no trigger")
