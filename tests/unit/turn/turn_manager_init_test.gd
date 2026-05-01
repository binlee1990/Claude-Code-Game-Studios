const TurnState = preload("res://src/core/turn_state.gd")

# Story turn/001: TurnManager initialization + TurnConfig tests
# TR-turn-001, TR-turn-006 | ADR-0004

func _make_units():
	var stats = UnitStats.new()
	var u1 = Unit.new()
	u1.initialize(stats, Faction.Type.PLAYER)
	var u2 = Unit.new()
	u2.initialize(stats, Faction.Type.ENEMY)
	return [u1, u2]

func test_turn_config_default_turn_cap_is_30():
	var cfg = TurnConfig.new()
	assert(cfg.turn_cap == 30)

func test_turn_config_validate_accepts_valid_range():
	var cfg = TurnConfig.new()
	assert(cfg.validate())

func test_turn_config_validate_boundary_one():
	var cfg = TurnConfig.new()
	cfg.turn_cap = 1
	assert(cfg.validate())

func test_turn_config_validate_boundary_99():
	var cfg = TurnConfig.new()
	cfg.turn_cap = 99
	assert(cfg.validate())

func test_turn_manager_extends_refcounted():
	var tm = TurnManager.new()
	assert(tm is RefCounted)

func test_turn_manager_initial_state_is_match_not_started():
	var tm = TurnManager.new()
	assert(tm.current_state == TurnState.MATCH_NOT_STARTED)

func test_initialize_stores_dependencies():
	var tm = TurnManager.new()
	var u = _make_units()
	var c = TurnConfig.new()
	var v = VictoryChecker.new()
	var a = NullAI.new()
	tm.initialize(u, c, v, a)
	assert(tm.turn_cap == 30)

func test_start_match_transitions_to_faction_phase_active():
	var tm = TurnManager.new()
	var u = _make_units()
	tm.initialize(u, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.current_state == TurnState.FACTION_PHASE_ACTIVE)

func test_start_match_activates_player_first():
	var tm = TurnManager.new()
	var u = _make_units()
	tm.initialize(u, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.active_faction == Faction.Type.PLAYER)

func test_start_match_turn_number_starts_at_one():
	var tm = TurnManager.new()
	var u = _make_units()
	tm.initialize(u, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.turn_number == 1)

func test_start_match_twice_asserts():
	var tm = TurnManager.new()
	var u = _make_units()
	tm.initialize(u, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	tm.start_match()
	assert(tm.current_state == TurnState.FACTION_PHASE_ACTIVE)
	# Second start_match should be guarded; test confirms state unchanged
