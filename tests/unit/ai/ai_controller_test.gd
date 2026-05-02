extends RefCounted

const ActionType = preload("res://src/ai/action_type.gd")

var ai: NullAI

func before() -> void:
	ai = NullAI.new()

func test_null_ai_returns_empty_action_list() -> void:
	var units: Array[Unit] = []
	var ws := WorldState.new()
	var result := ai.take_turn(units, ws)
	assert(result.is_empty())
	assert(result.size() == 0)
	assert(result.get_actions().is_empty())

func test_null_ai_with_nonempty_units_returns_empty() -> void:
	var u := _make_unit()
	var units: Array[Unit] = [u]
	var ws := WorldState.new()
	var result := ai.take_turn(units, ws)
	assert(result.is_empty())

func test_null_ai_with_null_world_state() -> void:
	var units: Array[Unit] = []
	var result := ai.take_turn(units, null)
	assert(result.is_empty())

func test_null_ai_extends_ai_controller() -> void:
	assert(ai is AIController)
	assert(ai is NullAI)

func _make_unit() -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	u.initialize(stats, Faction.Type.PLAYER)
	return u
