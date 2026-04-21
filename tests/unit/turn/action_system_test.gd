# tests/unit/turn/action_system_test.gd
# Story 002: Action System
# Validates AC.2.1, AC.2.2, AC.2.3

extends Gut

var _action: ActionSystem
var _units: Array = []

func before_each() -> void:
	_action = ActionSystem.new()
	_action.name = "ActionSystem"
	add_child(_action)

func after_each() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	if is_instance_valid(_action):
		_action.queue_free()

func _create_unit(uid: StringName = &"", max_mp: int = 100, skill_costs: Array = []) -> Unit:
	var unit := Unit.new()
	unit.name = "ActionUnit_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	_units.append(unit)
	_action.initialize(_units, {unit: {"max_mp": max_mp, "skill_costs": skill_costs}})
	return unit

func _setup_single(max_mp: int = 100, skill_costs: Array = []) -> Unit:
	_units.clear()
	return _create_unit(&"test", max_mp, skill_costs)


# --- AC.2.1: One action per turn ---

func test_can_act_initially_true() -> void:
	var u = _setup_single()
	assert_true(_action.can_act(u), "Unit can act before any action")

func test_cannot_act_after_basic_attack() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.BASIC_ATTACK)
	assert_false(_action.can_act(u), "Cannot act after basic attack")

func test_cannot_act_after_standby() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.STANDBY)
	assert_false(_action.can_act(u), "Cannot act after standby")

func test_cannot_act_after_skill() -> void:
	var u = _setup_single(100, [20])
	_action.execute_action(u, ActionSystem.ActionType.SKILL, 20)
	assert_false(_action.can_act(u), "Cannot act after skill")

func test_move_does_not_end_turn() -> void:
	var u = _setup_single()
	var result = _action.execute_action(u, ActionSystem.ActionType.MOVE)
	assert_true(result, "Move succeeds")
	assert_true(_action.can_act(u), "Can still act after move")
	assert_false(_action.can_move(u), "Cannot move again")

func test_cannot_move_twice() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.MOVE)
	var result = _action.execute_action(u, ActionSystem.ActionType.MOVE)
	assert_false(result, "Second move should fail")

func test_round_reset_clears_acted_flag() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.BASIC_ATTACK)
	assert_false(_action.can_act(u))
	_action.reset_round()
	assert_true(_action.can_act(u), "Can act after round reset")
	assert_true(_action.can_move(u), "Can move after round reset")

func test_execute_action_after_acted_fails() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.BASIC_ATTACK)
	assert_false(_action.execute_action(u, ActionSystem.ActionType.STANDBY), "No action after acted")


# --- AC.2.2: Action options available ---

func test_full_mp_all_actions_available() -> void:
	var u = _setup_single(100, [20])
	var actions = _action.get_available_actions(u)
	assert_true(ActionSystem.ActionType.MOVE in actions, "MOVE available")
	assert_true(ActionSystem.ActionType.BASIC_ATTACK in actions, "BASIC_ATTACK available")
	assert_true(ActionSystem.ActionType.SKILL in actions, "SKILL available")
	assert_true(ActionSystem.ActionType.STANDBY in actions, "STANDBY available")

func test_no_skills_skill_not_available() -> void:
	var u = _setup_single(100, [])
	var actions = _action.get_available_actions(u)
	assert_false(ActionSystem.ActionType.SKILL in actions, "SKILL not available without skills")
	assert_true(ActionSystem.ActionType.MOVE in actions, "MOVE still available")
	assert_true(ActionSystem.ActionType.BASIC_ATTACK in actions, "BASIC_ATTACK still available")

func test_after_move_no_move_in_actions() -> void:
	var u = _setup_single(100, [20])
	_action.execute_action(u, ActionSystem.ActionType.MOVE)
	var actions = _action.get_available_actions(u)
	assert_false(ActionSystem.ActionType.MOVE in actions, "MOVE not available after move")
	assert_true(ActionSystem.ActionType.BASIC_ATTACK in actions, "BASIC_ATTACK still available")

func test_acted_unit_no_actions() -> void:
	var u = _setup_single()
	_action.execute_action(u, ActionSystem.ActionType.BASIC_ATTACK)
	var actions = _action.get_available_actions(u)
	assert_eq(actions.size(), 0, "No actions available after acting")


# --- AC.2.3: MP depletion ---

func test_zero_mp_only_attack_and_standby() -> void:
	var u = _setup_single(0, [20])
	assert_eq(_action.get_current_mp(u), 0, "MP should be 0")
	var actions = _action.get_available_actions(u)
	assert_eq(actions.size(), 2, "Only 2 actions when MP depleted")
	assert_true(ActionSystem.ActionType.BASIC_ATTACK in actions)
	assert_true(ActionSystem.ActionType.STANDBY in actions)
	assert_false(ActionSystem.ActionType.MOVE in actions, "MOVE not available when MP depleted")
	assert_false(ActionSystem.ActionType.SKILL in actions, "SKILL not available when MP depleted")

func test_mp_exactly_equals_skill_cost_usable() -> void:
	var u = _setup_single(20, [20])
	assert_eq(_action.get_current_mp(u), 20)
	var actions = _action.get_available_actions(u)
	assert_true(ActionSystem.ActionType.SKILL in actions, "SKILL available when MP equals cost")
	var result = _action.execute_action(u, ActionSystem.ActionType.SKILL, 20)
	assert_true(result, "Skill executes when MP exactly equals cost")

func test_mp_below_skill_cost_skill_disabled() -> void:
	var u = _setup_single(19, [20])
	assert_eq(_action.get_current_mp(u), 19)
	var actions = _action.get_available_actions(u)
	assert_false(ActionSystem.ActionType.SKILL in actions, "SKILL not available when MP < cost")
	assert_true(ActionSystem.ActionType.MOVE in actions, "MOVE still available")
	assert_true(ActionSystem.ActionType.BASIC_ATTACK in actions, "BASIC_ATTACK still available")

func test_mp_recovery_on_round_reset() -> void:
	var u = _setup_single(100, [30])
	_action.execute_action(u, ActionSystem.ActionType.SKILL, 30)
	assert_eq(_action.get_current_mp(u), 70)
	_action.reset_round()
	var expected: int = 70 + int(100 * 0.1)  # 70 + 10 = 80
	assert_eq(_action.get_current_mp(u), expected, "MP recovers 10% on round reset")

func test_mp_recovery_capped_at_max() -> void:
	var u = _setup_single(100, [])
	# MP is already at max (100)
	_action.reset_round()
	assert_eq(_action.get_current_mp(u), 100, "MP capped at max_mp")

func test_skill_deducts_mp() -> void:
	var u = _setup_single(50, [15])
	_action.execute_action(u, ActionSystem.ActionType.SKILL, 15)
	assert_eq(_action.get_current_mp(u), 35, "MP deducted after skill use")
