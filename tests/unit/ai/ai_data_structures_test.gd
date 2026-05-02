extends RefCounted

const ActionType = preload("res://src/ai/action_type.gd")
const MovementResolver = preload("res://src/movement/movement_resolver.gd")

var gs: GridSpace
var mp: Map

func before() -> void:
	gs = GridSpace.new()
	mp = Map.new()
	mp.grid_space = gs

func _make_open_map() -> void:
	mp._rows = 5
	mp._cols = 5
	for r in range(5):
		for c in range(5):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(faction: Faction.Type, pos: Vector2i) -> Unit:
	var u = Unit.new()
	var stats = UnitStats.new()
	u.initialize(stats, faction)
	u.grid_position = pos
	return u

func test_action_plan_move_and_attack() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var t = _make_unit(Faction.Type.PLAYER, Vector2i(1, 1))
	var ap = ActionPlan.new(u, ActionType.MOVE_AND_ATTACK, Vector2i(3, 4), t)
	assert(ap.unit == u)
	assert(ap.type == ActionType.MOVE_AND_ATTACK)
	assert(ap.move_target == Vector2i(3, 4))
	assert(ap.attack_target == t)

func test_action_plan_move_only() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var ap = ActionPlan.new(u, ActionType.MOVE_ONLY, Vector2i(3, 4), null)
	assert(ap.type == ActionType.MOVE_ONLY)
	assert(ap.attack_target == null)

func test_action_plan_attack_only() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var t = _make_unit(Faction.Type.PLAYER, Vector2i(0, 1))
	var ap = ActionPlan.new(u, ActionType.ATTACK_ONLY, Vector2i(0, 0), t)
	assert(ap.type == ActionType.ATTACK_ONLY)
	assert(ap.move_target == u.grid_position)

func test_action_plan_wait() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var ap = ActionPlan.new(u, ActionType.WAIT, u.grid_position, null)
	assert(ap.type == ActionType.WAIT)
	assert(ap.move_target == u.grid_position)
	assert(ap.attack_target == null)

func test_action_list_ordering() -> void:
	var u1 = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var u2 = _make_unit(Faction.Type.ENEMY, Vector2i(1, 0))
	var ap1 = ActionPlan.new(u1, ActionType.WAIT, u1.grid_position, null)
	var ap2 = ActionPlan.new(u2, ActionType.WAIT, u2.grid_position, null)
	var al = ActionList.new()
	al.add(ap1)
	al.add(ap2)
	assert(al.size() == 2)
	assert(not al.is_empty())
	var actions = al.get_actions()
	assert(actions[0] == ap1)
	assert(actions[1] == ap2)

func test_action_list_is_empty() -> void:
	var al = ActionList.new()
	assert(al.is_empty())
	assert(al.size() == 0)

func test_action_list_defensive_copy() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var ap = ActionPlan.new(u, ActionType.WAIT, u.grid_position, null)
	var al = ActionList.new()
	al.add(ap)
	var copy1 = al.get_actions()
	copy1.clear()
	assert(al.size() == 1, "original must not be affected by copy mutation")

func test_world_state_clone_deep_copy() -> void:
	_make_open_map()
	var w = WorldState.new()
	w.map = mp
	w._occupancy_snapshot[Vector2i(0, 0)] = _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	var clone = w.clone()
	clone._occupancy_snapshot[Vector2i(0, 1)] = _make_unit(Faction.Type.ENEMY, Vector2i(0, 1))
	assert(clone._occupancy_snapshot.size() == 2, "clone has both entries")
	assert(w._occupancy_snapshot.size() == 1, "original unchanged by clone modification")

func test_world_state_map_access() -> void:
	_make_open_map()
	var w = WorldState.new()
	w.map = mp
	var neighbors = mp.get_neighbors(Vector2i(2, 2))
	var ws_neighbors = w.map.get_neighbors(Vector2i(2, 2))
	assert(neighbors.size() == ws_neighbors.size())

func test_empty_action_list_valid() -> void:
	var al = ActionList.new()
	assert(al.is_empty(), "empty ActionList is vacuously valid")

func test_f1_r1_unit_membership() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var units: Array[Unit] = [u]
	var ap = ActionPlan.new(u, ActionType.WAIT, u.grid_position, null)
	assert(ap.unit in units, "unit must be in the input units array")

func test_f1_r2_no_duplicate_units() -> void:
	var u1 = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var u2 = _make_unit(Faction.Type.ENEMY, Vector2i(1, 0))
	var al = ActionList.new()
	al.add(ActionPlan.new(u1, ActionType.WAIT, u1.grid_position, null))
	al.add(ActionPlan.new(u2, ActionType.WAIT, u2.grid_position, null))
	var actions = al.get_actions()
	assert(actions[0].unit != actions[1].unit, "no duplicate units")

func test_f1_r3_target_faction_alive() -> void:
	var attacker = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var target = _make_unit(Faction.Type.PLAYER, Vector2i(0, 1))
	var ap = ActionPlan.new(attacker, ActionType.ATTACK_ONLY, attacker.grid_position, target)
	assert(ap.attack_target.faction != ap.unit.faction, "target must be different faction")
	assert(ap.attack_target.is_alive(), "target must be alive")

func test_f1_r4_manhattan_within_mov() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	assert(MovementResolver.manhattan(u.grid_position, Vector2i(0, 3)) <= u.mov, "within range")
	assert(MovementResolver.manhattan(u.grid_position, Vector2i(0, 5)) > u.mov, "out of range")

func test_f1_r5_no_occupancy_conflict() -> void:
	var u1 = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var u2 = _make_unit(Faction.Type.ENEMY, Vector2i(1, 0))
	var ap1 = ActionPlan.new(u1, ActionType.MOVE_ONLY, Vector2i(3, 4), null)
	var ap2 = ActionPlan.new(u2, ActionType.MOVE_ONLY, Vector2i(5, 6), null)
	assert(ap1.move_target != ap2.move_target, "different move targets -> no conflict")

func test_f1_r6_type_fields_completeness() -> void:
	var u = _make_unit(Faction.Type.ENEMY, Vector2i(0, 0))
	var t = _make_unit(Faction.Type.PLAYER, Vector2i(0, 1))
	var ma = ActionPlan.new(u, ActionType.MOVE_AND_ATTACK, Vector2i(3, 4), t)
	assert(ma.move_target != u.grid_position and ma.attack_target != null)
	var mo = ActionPlan.new(u, ActionType.MOVE_ONLY, Vector2i(3, 4), null)
	assert(mo.move_target != u.grid_position and mo.attack_target == null)
	var ao = ActionPlan.new(u, ActionType.ATTACK_ONLY, u.grid_position, t)
	assert(ao.move_target == u.grid_position and ao.attack_target != null)
	var w = ActionPlan.new(u, ActionType.WAIT, u.grid_position, null)
	assert(w.move_target == u.grid_position and w.attack_target == null)
