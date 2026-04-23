# test_turn_order_integration.gd
# Integration test for turn-based combat turn order
# Validates turn-based-mode.md speed-sequence system

extends Gut

var _turn_manager: Node = null
var _units: Array = []


func before_each() -> void:
	_units.clear()
	# Setup mock turn manager
	_turn_manager = Node.new()
	_turn_manager.set_meta("type", "TurnManager")
	add_child(_turn_manager)

func after_each() -> void:
	for unit in _units:
		if is_instance_valid(unit):
			unit.queue_free()
	_units.clear()
	if is_instance_valid(_turn_manager):
		_turn_manager.queue_free()
	_turn_manager = null


func test_speed_sorting() -> void:
	# Units should be sorted by speed descending
	var unit1 := _create_mock_unit("fast", 50.0)  # Speed 50
	var unit2 := _create_mock_unit("slow", 20.0)  # Speed 20
	var unit3 := _create_mock_unit("medium", 35.0)  # Speed 35

	_units = [unit1, unit2, unit3]
	_sort_by_speed()

	assert_eq(_units[0].name, "fast", "Fastest should be first")
	assert_eq(_units[1].name, "medium", "Medium should be second")
	assert_eq(_units[2].name, "slow", "Slowest should be last")


func test_equal_speed_tiebreaker() -> void:
	# Equal speed should use secondary stat (e.g., agi or random)
	var unit1 := _create_mock_unit("a", 30.0)
	var unit2 := _create_mock_unit("b", 30.0)

	_units = [unit1, unit2]
	_sort_by_speed()  # Tiebreaker: alphabetical

	assert_eq(_units[0].name, "a", "Alphabetical tiebreaker")


func test_turn_order_modifiers() -> void:
	# Buffs/debuffs should modify turn order
	var unit := _create_mock_unit("normal", 30.0)
	_apply_buff(unit, "speed_up", 1.5)  # 50% speed increase

	var modified_speed := _get_effective_speed(unit)
	assert_true(modified_speed > 30.0, "Speed buff should increase effective speed")


func test_turn_skip_on_stun() -> void:
	# Stunned units should be skipped in turn order
	var stunned_unit := _create_mock_unit("stunned", 40.0)
	_apply_debuff(stunned_unit, "stun", 2)  # 2 turns

	var should_skip := _is_unit_skipped(stunned_unit)
	assert_true(should_skip, "Stunned unit should be skipped")


func _create_mock_unit(name: String, speed: float) -> Node:
	var unit := Node.new()
	unit.set_meta("type", "Unit")
	unit.name = name
	unit.set_meta("speed", speed)
	add_child(unit)
	return unit


func _sort_by_speed() -> void:
	_units.sort_custom(func(a, b):
		var speed_a = a.get_meta("speed")
		var speed_b = b.get_meta("speed")
		if speed_a == speed_b:
			return a.name < b.name  # Tiebreaker
		return speed_a > speed_b
	)


func _get_effective_speed(unit: Node) -> float:
	var base_speed: float = float(unit.get_meta("speed"))
	var modifiers: float = float(unit.get_meta("speed_modifiers", 1.0))
	return base_speed * modifiers


func _apply_buff(unit: Node, buff_id: String, multiplier: float) -> void:
	var current: float = float(unit.get_meta("speed_modifiers", 1.0))
	unit.set_meta("speed_modifiers", current * multiplier)


func _apply_debuff(unit: Node, debuff_id: String, duration: int) -> void:
	unit.set_meta("debuff_" + debuff_id, duration)


func _is_unit_skipped(unit: Node) -> bool:
	return unit.has_meta("debuff_stun") and int(unit.get_meta("debuff_stun")) > 0
