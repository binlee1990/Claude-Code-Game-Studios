extends RefCounted

# Story 8-7: E2E Playtest — 全流程自动化验证
# Covers checkpoints 1-8, 10 at the logic/integration layer.
# CP9 (Play Again) needs scene tree for get_tree().reload_current_scene().
# InputHandler-driven hover/click tests are in tests/unit/ui/input_handler_test.gd.

const TurnState = preload("res://src/core/turn_state.gd")
const UnitState = preload("res://src/core/unit_state.gd")
const MovementResolver = preload("res://src/movement/movement_resolver.gd")
const AttackResolver = preload("res://src/attack/attack_resolver.gd")
const AttackRangeResolver = preload("res://src/attack/attack_range_resolver.gd")

var _gs: GridSpace
var _mp: Map
var _tm: TurnManager
var _mov_res: MovementResolver
var _atk_res: AttackResolver
var _atk_rng: AttackRangeResolver
var _vc: VictoryChecker
var _units: Array

var _ends: Array = []
var _facts: Array = []
var _turns: Array = []
var _dieds: Array = []

func before() -> void:
	_gs = GridSpace.new()
	_mp = Map.new()
	_mp.grid_space = _gs
	_mov_res = MovementResolver.new()
	_atk_res = AttackResolver.new()
	_atk_rng = AttackRangeResolver.new()
	_vc = VictoryChecker.new()
	_ends = []; _facts = []; _turns = []; _dieds = []

func _setup_map(size: int) -> void:
	_mp._rows = size
	_mp._cols = size
	for r in range(size):
		for c in range(size):
			_mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _mk(hp: int, atk: int, def: int, mov: int, rng: int, faction: Faction.Type) -> Unit:
	var s = UnitStats.new()
	s.max_hp = hp; s.atk = atk; s.def = def; s.mov = mov; s.rng = rng
	var u = Unit.new()
	u.initialize(s, faction)
	u.hp = hp
	return u

func _place(u: Unit, row: int, col: int) -> void:
	u.grid_position = Vector2i(row, col)
	_mp.place_unit(u, Vector2i(row, col))

func _on_end(reason: String, winner: Faction.Type) -> void:
	_ends.append({"r": reason, "w": winner})

func _on_fact(f: Faction.Type) -> void:
	_facts.append(f)

func _on_turn(n: int) -> void:
	_turns.append(n)

func _wire_tm(tm: TurnManager) -> void:
	tm.match_ended.connect(_on_end)
	tm.faction_activated.connect(_on_fact)
	tm.turn_started.connect(_on_turn)
	for u in _units:
		if not u.unit_died.is_connected(_on_died):
			u.unit_died.connect(_on_died)

func _on_died(u: Unit) -> void:
	_dieds.append(u)

# Simulate a unit taking its turn: select → move (if specified) → attack (if target)
func _act(unit: Unit, move_to: Vector2i, attack_target) -> void:
	unit.action_state = UnitState.SELECTED
	var mov_result = _mov_res.compute_reachable(unit, _mp)
	# Move if target reachable
	if mov_result.get_distance_to(move_to) >= 0:
		_mp.move_unit(unit, unit.grid_position, move_to)
		unit.action_state = UnitState.MOVED
	# Attack if valid target
	if attack_target != null:
		var targets = _atk_rng.get_valid_targets(unit, _units, _mp)
		if attack_target in targets:
			_atk_res.execute_attack(unit, attack_target)
	unit.has_acted_this_turn = true
	unit.action_state = UnitState.ACTED

# ============================================================
# CP1: 启动 → 棋盘/单位就位
# ============================================================

func test_cp1_game_initializes_all_systems() -> void:
	_setup_map(8)
	var p1 = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var p2 = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e1 = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	var e2 = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p1, 2, 2); _place(p2, 2, 3)
	_place(e1, 5, 2); _place(e2, 5, 3)
	_units = [p1, p2, e1, e2]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	assert(_tm.current_state == TurnState.FACTION_PHASE_ACTIVE)
	assert(_tm.active_faction == Faction.Type.PLAYER)
	assert(_tm.turn_number == 1)
	assert(p1.is_alive() and p2.is_alive() and e1.is_alive() and e2.is_alive())
	assert(_mp.get_unit_at(Vector2i(2, 2)) == p1)
	assert(_mp.get_unit_at(Vector2i(5, 2)) == e1)
	assert(_turns.size() >= 1 and _turns[0] == 1)
	assert(_facts.size() >= 1 and _facts[0] == Faction.Type.PLAYER)

# ============================================================
# CP2+CP4: 选中→移动→攻击目标阶段 (逻辑)
# ============================================================

func test_cp2_cp4_unit_selection_and_movement_logic() -> void:
	_setup_map(8)
	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 2, 2); _place(e, 5, 5)
	_units = [p, e]

	# Without InputHandler, verify the underlying systems directly
	# Select: set action_state
	p.action_state = UnitState.SELECTED
	assert(p.can_move())

	# Movement: compute reachable and execute
	var result = _mov_res.compute_reachable(p, _mp)
	assert(not result.get_reachable_tiles().is_empty())
	assert(result.get_distance_to(Vector2i(2, 3)) >= 0)  # adjacent reachable

	# Execute move
	_mp.move_unit(p, Vector2i(2, 2), Vector2i(2, 3))
	assert(p.grid_position == Vector2i(2, 3))
	p.action_state = UnitState.MOVED

	# Attack targeting: check valid targets
	var targets = _atk_rng.get_valid_targets(p, _units, _mp)
	# e at (5,5), p at (2,3), Manhattan=4, rng=1 → not in range yet
	assert(targets.is_empty())  # no targets in range (rng=1)

# ============================================================
# CP5+CP6: 攻击 + 击杀 (逻辑)
# ============================================================

func test_cp5_cp6_attack_and_lethal_kill() -> void:
	_setup_map(8)
	var p = _mk(10, 9, 0, 4, 1, Faction.Type.PLAYER)
	var e = _mk(4, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 3, 3); _place(e, 3, 4)
	_units = [p, e]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	# Verify attack target valid
	var targets = _atk_rng.get_valid_targets(p, _units, _mp)
	assert(targets.size() == 1 and targets[0] == e)

	# Execute attack
	var died_before = _dieds.size()
	p.action_state = UnitState.SELECTED
	_atk_res.execute_attack(p, e)
	# atk=9 def=1 → damage=8, e.hp=4 → lethal
	assert(not e.is_alive())
	assert(_dieds.size() == died_before + 1)

# ============================================================
# CP7: End Turn → 阵营切换 (热座)
# ============================================================

func test_cp7_end_turn_switches_faction() -> void:
	_setup_map(8)
	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 2, 2); _place(e, 5, 5)
	_units = [p, e]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	assert(_tm.active_faction == Faction.Type.PLAYER)

	# Player acts
	_act(p, Vector2i(3, 2), null)
	_tm.end_current_faction_turn()
	assert(_tm.active_faction == Faction.Type.ENEMY)

	# Enemy can now act (hotseat: player controls enemy too)
	assert(not e.has_acted_this_turn)  # fresh turn for enemy

func test_cp7_two_full_cycles() -> void:
	_setup_map(8)
	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 2, 2); _place(e, 5, 5)
	_units = [p, e]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	# Cycle 1: Player → Enemy → Player (turn increments)
	_act(p, Vector2i(3, 2), null)
	_tm.end_current_faction_turn()
	assert(_tm.turn_number == 1)  # still turn 1 after player phase

	_act(e, Vector2i(5, 4), null)
	_tm.end_current_faction_turn()
	assert(_tm.turn_number == 2)  # incremented after enemy phase

	# Cycle 2
	_act(p, Vector2i(4, 2), null)
	_tm.end_current_faction_turn()
	_act(e, Vector2i(5, 3), null)
	_tm.end_current_faction_turn()
	assert(_tm.turn_number == 3)

# ============================================================
# CP8a: 全灭敌方 → WIN (完整游戏)
# ============================================================

func test_cp8_full_game_victory() -> void:
	_setup_map(8)
	var p = _mk(10, 9, 0, 4, 1, Faction.Type.PLAYER)
	var e1 = _mk(1, 4, 1, 3, 1, Faction.Type.ENEMY)
	var e2 = _mk(1, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 3, 3); _place(e1, 3, 4); _place(e2, 5, 5)
	_units = [p, e1, e2]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	# Turn 1 Player: kill e1 (adjacent)
	p.action_state = UnitState.SELECTED
	_atk_res.execute_attack(p, e1)
	assert(not e1.is_alive())
	p.has_acted_this_turn = true
	p.action_state = UnitState.ACTED
	_tm.end_current_faction_turn()

	# Turn 1 Enemy: move e2 closer
	assert(_tm.active_faction == Faction.Type.ENEMY)
	_act(e2, Vector2i(4, 5), null)
	_tm.end_current_faction_turn()

	# Turn 2 Player: move to (4,4), kill e2
	assert(_tm.turn_number == 2)
	assert(_tm.active_faction == Faction.Type.PLAYER)
	_mp.move_unit(p, Vector2i(3, 3), Vector2i(4, 4))
	p.action_state = UnitState.MOVED
	_atk_res.execute_attack(p, e2)
	assert(not e2.is_alive())

	# Should trigger match_ended
	assert(_ends.size() >= 1)
	assert(_ends[0]["w"] == Faction.Type.PLAYER)
	assert(_ends[0]["r"] == "elimination")

# ============================================================
# CP8b: 全灭己方 → DEFEAT
# ============================================================

func test_cp8_defeat_player_eliminated() -> void:
	_setup_map(8)
	var p = _mk(1, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(10, 9, 0, 4, 1, Faction.Type.ENEMY)
	_place(p, 3, 3); _place(e, 3, 4)
	_units = [p, e]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	# Player attacks (survives)
	p.action_state = UnitState.SELECTED
	_atk_res.execute_attack(p, e)
	assert(e.is_alive())
	p.has_acted_this_turn = true
	_tm.end_current_faction_turn()

	# Enemy kills player
	e.action_state = UnitState.SELECTED
	_atk_res.execute_attack(e, p)
	assert(not p.is_alive())
	assert(_ends.size() >= 1)
	assert(_ends[0]["w"] == Faction.Type.ENEMY)
	assert(_ends[0]["r"] == "elimination")

# ============================================================
# CP10: 回合上限 → DRAW
# ============================================================

func test_cp10_turn_cap_draw() -> void:
	_setup_map(8)
	var tc = TurnConfig.new()
	tc.turn_cap = 2

	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(10, 5, 2, 4, 1, Faction.Type.ENEMY)
	_place(p, 2, 2); _place(e, 5, 5)
	_units = [p, e]

	_tm = TurnManager.new()
	_tm.initialize(_units, tc, _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	# T1 PLAYER → T1 ENEMY (turn=1→2)
	_act(p, p.grid_position, null)
	_tm.end_current_faction_turn()
	_act(e, e.grid_position, null)
	_tm.end_current_faction_turn()
	assert(_tm.turn_number == 2)

	# T2 PLAYER → T2 ENEMY (turn=2→3 > cap=2)
	_act(p, p.grid_position, null)
	_tm.end_current_faction_turn()
	_act(e, e.grid_position, null)
	_tm.end_current_faction_turn()

	assert(_ends.size() >= 1)
	assert(_ends[0]["w"] == Faction.Type.NONE)
	assert(_ends[0]["r"] == "turn_cap")

# ============================================================
# 信号完整性验证
# ============================================================

func test_e2e_signal_order_on_match_start() -> void:
	_setup_map(8)
	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	_place(p, 2, 2)
	_units = [p]

	_tm = TurnManager.new()
	_tm.initialize(_units, TurnConfig.new(), _vc, NullAI.new())
	_wire_tm(_tm)
	_tm.start_match()

	assert(_turns.size() >= 1)
	assert(_turns[0] == 1)
	assert(_facts.size() >= 1)
	assert(_facts[0] == Faction.Type.PLAYER)

func test_e2e_victory_checker_pure_function() -> void:
	_setup_map(8)
	var p = _mk(10, 5, 2, 4, 1, Faction.Type.PLAYER)
	var e = _mk(8, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 2, 2); _place(e, 5, 5)
	_units = [p, e]

	# Determinism check
	var r1 = _vc.determine_winner(_units, 1, 30)
	var r2 = _vc.determine_winner(_units, 1, 30)
	assert(r1.winner == r2.winner and r1.reason == r2.reason)

func test_e2e_unit_died_occupancy_cleanup() -> void:
	_setup_map(8)
	var p = _mk(10, 9, 0, 4, 1, Faction.Type.PLAYER)
	var e = _mk(1, 4, 1, 3, 1, Faction.Type.ENEMY)
	_place(p, 3, 3); _place(e, 3, 4)
	_units = [p, e]

	var e_pos = e.grid_position
	assert(_mp.get_unit_at(e_pos) == e)

	p.action_state = UnitState.SELECTED
	_atk_res.execute_attack(p, e)
	assert(not e.is_alive())
	assert(_dieds.size() >= 1)
	# In production, Game._on_unit_died calls map.remove_unit + queue_free
	# Simulate the cleanup
	_mp.remove_unit(e_pos)
	e.queue_free()
	assert(_mp.get_unit_at(e_pos) == null)
