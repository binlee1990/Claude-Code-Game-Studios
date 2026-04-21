# tests/unit/attributes/crush_mechanic_test.gd
# Story 006: Crush Mechanic
# Validates AC-11.1, AC-11.2, AC-12.1, AC-13.1

extends Gut

var _attacker: Unit
var _defender: Unit

func before_each() -> void:
	_attacker = Unit.new()
	_attacker.name = "Attacker"
	add_child(_attacker)
	_defender = Unit.new()
	_defender.name = "Defender"
	add_child(_defender)

func after_each() -> void:
	if is_instance_valid(_attacker):
		_attacker.queue_free()
	if is_instance_valid(_defender):
		_defender.queue_free()

func _set_attr(unit: Unit, attr: int, value: int) -> void:
	var comp: AttributeComponent = unit.attributes.get_component(attr)
	comp.load_data({
		"value": value, "potential": 3,
		"barrier_stage": 4, "barriers_broken": {1: true, 2: true, 3: true},
		"thresholds_reached": {}
	})


# AC-11.1: Crush triggers when gap > 30

func test_crush_attacker_advantage() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 80)
	_set_attr(_defender, AttributeNames.Attribute.STR, 45)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_true(result["did_crush"], "|80-45|=35 > 30")
	assert_eq(result["damage_multiplier"], 1.5)
	assert_eq(result["defense_multiplier"], 0.8)

func test_crush_boundary_31() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 81)
	_set_attr(_defender, AttributeNames.Attribute.STR, 50)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_true(result["did_crush"], "|81-50|=31 > 30 triggers")

func test_crush_boundary_30_no_trigger() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 80)
	_set_attr(_defender, AttributeNames.Attribute.STR, 50)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_false(result["did_crush"], "|80-50|=30, strict > does not trigger")

func test_crush_extreme_gap() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.CON, 999)
	_set_attr(_defender, AttributeNames.Attribute.CON, 0)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.CON)
	assert_true(result["did_crush"], "Max gap triggers crush")


# AC-11.2: Crush direction

func test_direction_attacker_crushes() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 80)
	_set_attr(_defender, AttributeNames.Attribute.STR, 45)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_eq(result["crush_direction"], 1, "Attacker crushes defender")

func test_direction_defender_crushes() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 45)
	_set_attr(_defender, AttributeNames.Attribute.STR, 80)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_true(result["did_crush"])
	assert_eq(result["crush_direction"], -1, "Defender crushes attacker")

func test_equal_values_no_crush() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 50)
	_set_attr(_defender, AttributeNames.Attribute.STR, 50)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR)
	assert_false(result["did_crush"])
	assert_eq(result["crush_direction"], 0)
	assert_eq(result["delta"], 0)


# AC-12.1: No crush when gap <= 30

func test_no_crush_gap_25() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.AGI, 60)
	_set_attr(_defender, AttributeNames.Attribute.AGI, 35)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.AGI)
	assert_false(result["did_crush"], "|60-35|=25 <= 30")
	assert_eq(result["damage_multiplier"], 1.0)
	assert_eq(result["defense_multiplier"], 1.0)

func test_no_crush_result_has_applicable() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.AGI, 60)
	_set_attr(_defender, AttributeNames.Attribute.AGI, 35)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.AGI)
	assert_true(result["applicable"], "Default is_damage_action=true → applicable=true")


# AC-13.1: Not applicable for healing/buff actions

func test_not_applicable_for_heal() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.STR, 999)
	_set_attr(_defender, AttributeNames.Attribute.STR, 0)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.STR, false)
	assert_false(result["applicable"], "Heal action → not applicable")
	assert_eq(result["damage_multiplier"], 1.0, "Multipliers neutral when not applicable")
	assert_eq(result["defense_multiplier"], 1.0)

func test_not_applicable_for_buff() -> void:
	_set_attr(_attacker, AttributeNames.Attribute.INT, 200)
	_set_attr(_defender, AttributeNames.Attribute.INT, 50)
	var result := _attacker.evaluate_crush_against(_defender, AttributeNames.Attribute.INT, false)
	assert_false(result["applicable"])
	assert_true(result["did_crush"], "did_crush reflects raw gap regardless of applicability")
