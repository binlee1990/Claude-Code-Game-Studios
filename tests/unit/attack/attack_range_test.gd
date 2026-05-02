extends RefCounted

const AttackRangeResolver = preload("res://src/attack/attack_range_resolver.gd")

var resolver: AttackRangeResolver
var gs: GridSpace
var mp: Map

func before() -> void:
	resolver = AttackRangeResolver.new()
	gs = GridSpace.new()
	mp = Map.new()
	mp.grid_space = gs

func _make_open_map(rows: int, cols: int) -> void:
	mp._rows = rows
	mp._cols = cols
	for r in range(rows):
		for c in range(cols):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(faction: Faction.Type, atk_val: int, rng_val: int, pos: Vector2i) -> Unit:
	var u = Unit.new()
	var stats = UnitStats.new()
	stats.atk = atk_val
	stats.rng = clampi(rng_val, 1, 3)
	u.initialize(stats, faction)
	u.rng = rng_val
	u.grid_position = pos
	return u

func test_manhattan_range_rng1_adjacent() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 1, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(5, 4))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.size() == 1)

func test_manhattan_range_diagonal_rng1_rejected() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 1, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(6, 4))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.is_empty())

func test_rng2_target_reachable() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(5, 5))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.size() == 1)

func test_rng2_targ_out_of_range() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(3, 5))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.is_empty())

func test_self_tile_excluded() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(5, 3))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.is_empty())

func test_same_faction_excluded() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var ally = _make_unit(Faction.Type.PLAYER, 3, 1, Vector2i(5, 4))
	var targets = resolver.get_valid_targets(attacker, [ally], mp)
	assert(targets.is_empty())

func test_dead_target_excluded() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(5, 4))
	target.hp = 0
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.is_empty())

func test_sorted_by_distance_then_hp() -> void:
	_make_open_map(10, 10)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 3, Vector2i(0, 0))
	var b = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(0, 1))
	b.hp = 10
	var c = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(0, 2))
	c.hp = 5
	var a = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(0, 2))
	a.hp = 8
	var targets = resolver.get_valid_targets(attacker, [a, b, c], mp)
	assert(targets[0] == b)
	assert(targets[1] == c)
	assert(targets[2] == a)

func test_empty_target_list() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 2, Vector2i(5, 3))
	var targets = resolver.get_valid_targets(attacker, [], mp)
	assert(targets.is_empty())

func test_rng_zero_no_targets() -> void:
	_make_open_map(5, 5)
	var attacker = _make_unit(Faction.Type.PLAYER, 5, 0, Vector2i(5, 3))
	var target = _make_unit(Faction.Type.ENEMY, 3, 1, Vector2i(5, 4))
	var targets = resolver.get_valid_targets(attacker, [target], mp)
	assert(targets.is_empty())
