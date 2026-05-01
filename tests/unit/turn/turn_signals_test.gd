const TurnState = preload("res://src/core/turn_state.gd")

# Story turn/004: Turn signals + AIController interface tests
# TR-turn-005, TR-turn-008, TR-ai-001, TR-ai-004 | ADR-0004, ADR-0008

func test_null_ai_extends_ai_controller():
	var ai = NullAI.new()
	assert(ai is AIController)

func test_null_ai_returns_empty_array():
	var ai = NullAI.new()
	var result = ai.take_turn([], {})
	assert(result == [])

func test_null_ai_accepts_empty_inputs():
	var ai = NullAI.new()
	var result = ai.take_turn([], {})
	assert(result.is_empty())

func test_turn_manager_match_ended_signal_with_elimination():
	var stats = UnitStats.new()
	var u = Unit.new()
	u.initialize(stats, Faction.Type.PLAYER)
	var tm = TurnManager.new()
	tm.initialize([u], TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	var reason = ""
	var winner: Faction.Type
	tm.match_ended.connect(func(r: String, w: Faction.Type):
		reason = r
		winner = w
	)
	tm.start_match()
	assert(reason == "elimination")
	assert(winner == Faction.Type.PLAYER)

func test_turn_manager_readonly_properties_before_start():
	var stats = UnitStats.new()
	var u = Unit.new()
	u.initialize(stats, Faction.Type.PLAYER)
	var tm = TurnManager.new()
	tm.initialize([u], TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	assert(tm.current_state == TurnState.MATCH_NOT_STARTED)
	assert(tm.turn_cap == 30)
