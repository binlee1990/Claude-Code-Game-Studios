const UnitState = preload("res://src/core/unit_state.gd")

# Story unit/003: Unit public interface + action_state state machine
# TR-unit-003, TR-unit-004, TR-unit-005, TR-unit-007 | ADR-0003

func _make_stats():
	var s = UnitStats.new()
	s.max_hp = 10
	s.atk = 5
	s.def = 2
	s.mov = 4
	s.rng = 1
	return s

func test_unit_initialize_loads_stats_correctly():
	var u = Unit.new()
	var s = _make_stats()
	u.initialize(s, Faction.Type.PLAYER)
	assert(u.max_hp == 10)
	assert(u.atk == 5)
	assert(u.def == 2)
	assert(u.mov == 4)
	assert(u.rng == 1)
	assert(u.hp == 10)

func test_unit_initialize_sets_faction():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.ENEMY)
	assert(u.faction == Faction.Type.ENEMY)

func test_unit_initialize_generates_unique_ids():
	var u1 = Unit.new()
	var u2 = Unit.new()
	var u3 = Unit.new()
	u1.initialize(_make_stats(), Faction.Type.PLAYER)
	u2.initialize(_make_stats(), Faction.Type.PLAYER)
	u3.initialize(_make_stats(), Faction.Type.PLAYER)
	assert(u1.unit_id != u2.unit_id)
	assert(u2.unit_id != u3.unit_id)
	assert(u1.unit_id != u3.unit_id)

func test_unit_is_alive_when_hp_above_zero():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	assert(u.is_alive())
	assert(not u.is_dead())

func test_unit_is_dead_when_hp_zero():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	u.hp = 0
	assert(u.is_dead())
	assert(not u.is_alive())

func test_unit_can_be_selected_when_idle_and_alive_and_not_acted():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	assert(u.can_be_selected())

func test_unit_cannot_be_selected_after_acted():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	u.has_acted_this_turn = true
	assert(not u.can_be_selected())

func test_unit_cannot_be_selected_when_dead():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	u.hp = 0
	assert(not u.can_be_selected())

func test_unit_cannot_be_selected_when_not_idle():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	u.action_state = UnitState.SELECTED
	assert(not u.can_be_selected())

func test_unit_can_move_only_when_selected():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	assert(not u.can_move())
	u.action_state = UnitState.SELECTED
	assert(u.can_move())
	u.action_state = UnitState.MOVED
	assert(not u.can_move())

func test_unit_can_attack_when_selected_or_moved():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	assert(not u.can_attack())
	u.action_state = UnitState.SELECTED
	assert(u.can_attack())
	u.action_state = UnitState.MOVED
	assert(u.can_attack())

func test_unit_reset_action_state_restores_idle_and_clears_acted_flag():
	var u = Unit.new()
	u.initialize(_make_stats(), Faction.Type.PLAYER)
	u.action_state = UnitState.ACTED
	u.has_acted_this_turn = true
	u.reset_action_state()
	assert(u.action_state == UnitState.IDLE)
	assert(not u.has_acted_this_turn)
