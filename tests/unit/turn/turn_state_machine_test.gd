const TurnState = preload("res://src/core/turn_state.gd")
const UnitState = preload("res://src/core/unit_state.gd")

# Story turn/002: Turn state machine core — 4 states + 5 transitions
# TR-turn-002, TR-turn-003, TR-turn-007 | ADR-0004

func _make_units(n_player: int, n_enemy: int):
	var result = []
	var stats = UnitStats.new()
	for i in range(n_player):
		var u = Unit.new()
		u.initialize(stats, Faction.Type.PLAYER)
		result.append(u)
	for i in range(n_enemy):
		var u = Unit.new()
		u.initialize(stats, Faction.Type.ENEMY)
		result.append(u)
	return result

func test_start_match_emits_match_started_then_turn_started_then_faction_activated():
	var units = _make_units(3, 3)
	var s = {"match_started": 0, "turn_started": 0, "faction_activated": 0}
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.match_started.connect(func(): s["match_started"] += 1)
	tm.turn_started.connect(func(_n: int): s["turn_started"] += 1)
	tm.faction_activated.connect(func(_f: Faction.Type): s["faction_activated"] += 1)
	tm.start_match()
	assert(s["match_started"] == 1)
	assert(s["turn_started"] == 1)
	assert(s["faction_activated"] == 1)

func test_auto_advance_when_all_acted():
	var units = _make_units(3, 3)
	var s = {"phase_ended": 0}
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.faction_phase_ended.connect(func(_f: Faction.Type): s["phase_ended"] += 1)
	tm.start_match()
	for u in units:
		if u.faction == Faction.Type.PLAYER:
			u.has_acted_this_turn = true
	tm._on_unit_action_completed(units[0])
	assert(s["phase_ended"] == 1)

func test_end_turn_manually_transitions_to_ending():
	var units = _make_units(3, 3)
	var s = {"phase_ended": 0}
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.faction_phase_ended.connect(func(_f: Faction.Type): s["phase_ended"] += 1)
	tm.start_match()
	tm.end_current_faction_turn()
	assert(s["phase_ended"] == 1)

func test_end_turn_during_ending_is_ignored():
	var units = _make_units(3, 3)
	var s = {"phase_ended": 0}
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.faction_phase_ended.connect(func(_f: Faction.Type): s["phase_ended"] += 1)
	tm.start_match()
	tm.end_current_faction_turn()
	tm.end_current_faction_turn()
	assert(s["phase_ended"] == 1)

func test_faction_rotation_player_to_enemy():
	var units = _make_units(3, 3)
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.active_faction == Faction.Type.PLAYER)
	tm.end_current_faction_turn()
	assert(tm.active_faction == Faction.Type.ENEMY)

func test_faction_rotation_enemy_to_player():
	var units = _make_units(3, 3)
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	tm.end_current_faction_turn()
	tm.end_current_faction_turn()
	assert(tm.active_faction == Faction.Type.PLAYER)

func test_turn_increments_only_after_enemy_phase():
	var units = _make_units(3, 3)
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.turn_number == 1)
	tm.end_current_faction_turn()
	assert(tm.turn_number == 1)
	tm.end_current_faction_turn()
	assert(tm.turn_number == 2)

func test_units_reset_on_phase_transition():
	var units = _make_units(3, 3)
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	for u in units:
		if u.faction == Faction.Type.PLAYER:
			u.has_acted_this_turn = true
			u.action_state = UnitState.ACTED
	tm.end_current_faction_turn()
	for u in units:
		if u.faction == Faction.Type.ENEMY:
			assert(not u.has_acted_this_turn)
			assert(u.action_state == UnitState.IDLE)

func test_end_turn_in_match_ended_is_ignored():
	var units = _make_units(1, 0)
	var tm = TurnManager.new()
	tm.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.current_state == TurnState.MATCH_ENDED)
	tm.end_current_faction_turn()
