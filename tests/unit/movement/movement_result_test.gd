extends RefCounted

const MovementResolver = preload("res://src/movement/movement_resolver.gd")

var resolver: MovementResolver
var gs: GridSpace
var mp: Map

func before() -> void:
	resolver = MovementResolver.new()
	gs = GridSpace.new()
	mp = Map.new()
	mp.grid_space = gs

func _make_open_map(rows: int, cols: int) -> void:
	mp._rows = rows
	mp._cols = cols
	for r in range(rows):
		for c in range(cols):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(hp: int, mov: int, pos: Vector2i) -> Unit:
	var u = Unit.new()
	var stats = UnitStats.new()
	stats.max_hp = hp
	stats.mov = mov
	u.initialize(stats, Faction.Type.PLAYER)
	u.hp = hp
	u.grid_position = pos
	return u

func test_path_reconstruction_shortest() -> void:
	_make_open_map(5, 5)
	var u = _make_unit(10, 3, Vector2i(0, 0))
	var result = resolver.compute_reachable(u, mp)
	var path = result.get_path_to(Vector2i(2, 1))
	assert(path.size() == 4)
	assert(path[0] == Vector2i(0, 0))
	assert(path[path.size() - 1] == Vector2i(2, 1))

func test_zero_step_path() -> void:
	_make_open_map(3, 3)
	var u = _make_unit(10, 3, Vector2i(1, 1))
	var result = resolver.compute_reachable(u, mp)
	var path = result.get_path_to(Vector2i(1, 1))
	assert(path.size() == 1)
	assert(path[0] == Vector2i(1, 1))

func test_unreachable_target_returns_empty_path() -> void:
	_make_open_map(5, 5)
	var u = _make_unit(10, 1, Vector2i(0, 0))
	var result = resolver.compute_reachable(u, mp)
	var path = result.get_path_to(Vector2i(4, 4))
	assert(path.is_empty())

func test_get_distance_to_reachable() -> void:
	_make_open_map(5, 5)
	var u = _make_unit(10, 3, Vector2i(0, 0))
	var result = resolver.compute_reachable(u, mp)
	assert(result.get_distance_to(Vector2i(0, 0)) == 0)
	assert(result.get_distance_to(Vector2i(0, 1)) == 1)
	assert(result.get_distance_to(Vector2i(1, 1)) == 2)

func test_get_distance_to_unreachable_returns_minus_one() -> void:
	_make_open_map(5, 5)
	var u = _make_unit(10, 1, Vector2i(0, 0))
	var result = resolver.compute_reachable(u, mp)
	assert(result.get_distance_to(Vector2i(4, 4)) == -1)

func test_get_start_tile() -> void:
	_make_open_map(3, 3)
	var u = _make_unit(10, 2, Vector2i(0, 1))
	var result = resolver.compute_reachable(u, mp)
	assert(result.get_start_tile() == Vector2i(0, 1))

func test_dead_unit_returns_empty_reachable() -> void:
	_make_open_map(3, 3)
	var u = _make_unit(0, 4, Vector2i(1, 1))
	var result = resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().is_empty())
	assert(result.get_path_to(Vector2i(1, 1)).is_empty())

func test_all_neighbors_blocked_only_start() -> void:
	mp._rows = 3
	mp._cols = 3
	for r in range(3):
		for c in range(3):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE if (r == 1 and c == 1) else Map.TileState.BLOCKED
	var u = _make_unit(10, 6, Vector2i(1, 1))
	var result = resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().size() == 1)
