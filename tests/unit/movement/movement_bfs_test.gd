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

func _make_tile_states(data: Array) -> void:
	# data[row][col] as string: . = walkable, # = blocked, O = obstacle
	mp._rows = data.size()
	mp._cols = data[0].length()
	for r in range(data.size()):
		for c in range(data[r].length()):
			var coord := Vector2i(r, c)
			match data[r][c]:
				".":
					mp._tile_states[coord] = Map.TileState.WALKABLE
				"#":
					mp._tile_states[coord] = Map.TileState.BLOCKED
				"O":
					mp._tile_states[coord] = Map.TileState.OBSTACLE

func _make_unit(hp: int, mov: int) -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	stats.max_hp = hp
	stats.mov = mov
	u.initialize(stats, Faction.Type.PLAYER)
	u.hp = hp
	return u

func test_manhattan_distance() -> void:
	assert(MovementResolver.manhattan(Vector2i(0, 0), Vector2i(3, 4)) == 7)
	assert(MovementResolver.manhattan(Vector2i(3, 4), Vector2i(0, 0)) == 7)
	assert(MovementResolver.manhattan(Vector2i(1, 1), Vector2i(1, 1)) == 0)

func test_open_grid_bfs_reachable() -> void:
	_make_tile_states([".....", ".....", ".....", ".....", "....."])
	var u := _make_unit(10, 2)
	u.grid_position = Vector2i(2, 2)
	var result := resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().size() == 13)

func test_start_tile_always_reachable() -> void:
	_make_tile_states(["...", "...", "..."])
	var u := _make_unit(10, 2)
	u.grid_position = Vector2i(1, 1)
	var result := resolver.compute_reachable(u, mp)
	assert(Vector2i(1, 1) in result.get_reachable_tiles())

func test_blocked_tiles_avoided() -> void:
	_make_tile_states(["...", ".#.", "..."])
	var u := _make_unit(10, 2)
	u.grid_position = Vector2i(0, 0)
	var result := resolver.compute_reachable(u, mp)
	assert(not Vector2i(1, 1) in result.get_reachable_tiles())

func test_occupied_tile_avoids_enemy() -> void:
	_make_tile_states(["...", "...", "..."])
	var u := _make_unit(10, 2)
	u.grid_position = Vector2i(0, 0)
	mp.place_unit(u, u.grid_position)
	var enemy := _make_unit(10, 2)
	enemy.grid_position = Vector2i(1, 1)
	mp._occupancy[Vector2i(1, 1)] = enemy
	var result := resolver.compute_reachable(u, mp)
	assert(not Vector2i(1, 1) in result.get_reachable_tiles())
	mp._occupancy.erase(Vector2i(1, 1))

func test_corner_tile_boundary() -> void:
	_make_tile_states([".....", ".....", ".....", ".....", "....."])
	var u := _make_unit(10, 3)
	u.grid_position = Vector2i(0, 0)
	var result := resolver.compute_reachable(u, mp)
	for tile in result.get_reachable_tiles():
		assert(tile.x >= 0 and tile.y >= 0)

func test_all_blocked_except_start() -> void:
	_make_tile_states([".#", "##"])
	var u := _make_unit(10, 6)
	u.grid_position = Vector2i(0, 0)
	var result := resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().size() == 1)
	assert(Vector2i(0, 0) in result.get_reachable_tiles())

func test_mov_zero_degnerate() -> void:
	_make_tile_states(["..."])
	var u := _make_unit(10, 0)
	u.grid_position = Vector2i(0, 1)
	var result := resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().size() == 1)

func test_dead_unit_returns_empty() -> void:
	_make_tile_states(["..."])
	var u := _make_unit(0, 4)
	u.grid_position = Vector2i(0, 1)
	var result := resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().is_empty())

func test_null_map_returns_empty() -> void:
	var u := _make_unit(10, 4)
	u.grid_position = Vector2i(1, 1)
	var result := resolver.compute_reachable(u, null)
	assert(result.get_reachable_tiles().is_empty())

func test_out_of_bounds_start() -> void:
	_make_tile_states(["..."])
	var u := _make_unit(10, 4)
	u.grid_position = Vector2i(-1, 5)
	var result := resolver.compute_reachable(u, mp)
	assert(result.get_reachable_tiles().is_empty())
