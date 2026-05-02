# Story map/002: CSV map loading tests
# TR-map-002, TR-map-004, TR-map-008 | ADR-0005

var _map: Map

func after() -> void:
	if is_instance_valid(_map):
		_map.free()

func test_csv_loading_valid_map_populates_tile_states() -> void:
	_map = Map.new()
	var gs := GridSpace.new()
	_map.initialize(gs, "test_map")
	var dims := _map.get_dimensions()
	assert(dims.cols == 16)
	assert(dims.rows == 12)

func test_csv_loading_walkable_tile_is_walkable() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	# test_map.csv has walkable '.' at origin
	assert(_map.get_tile_state(Vector2i(0, 0)) == Map.TileState.WALKABLE)

func test_csv_loading_blocked_tile_is_blocked() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	# test_map.csv has '#' at (2,4)
	assert(_map.get_tile_state(Vector2i(2, 4)) == Map.TileState.BLOCKED)

func test_csv_loading_out_of_bounds_returns_blocked() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	# Out-of-bounds defaults to BLOCKED (safe default)
	assert(_map.get_tile_state(Vector2i(100, 100)) == Map.TileState.BLOCKED)

func test_rough_tile_is_walkable_with_cost_two() -> void:
	_map = Map.new()
	_map._rows = 1
	_map._cols = 1
	_map._tile_states[Vector2i(0, 0)] = Map.TileState.ROUGH

	assert(_map.is_walkable(Vector2i(0, 0)))
	assert(_map.get_movement_cost(Vector2i(0, 0)) == 2)

func test_blocked_and_obstacle_tiles_have_no_movement_cost() -> void:
	_map = Map.new()
	_map._rows = 1
	_map._cols = 2
	_map._tile_states[Vector2i(0, 0)] = Map.TileState.BLOCKED
	_map._tile_states[Vector2i(0, 1)] = Map.TileState.OBSTACLE

	assert(_map.get_movement_cost(Vector2i(0, 0)) < 0)
	assert(_map.get_movement_cost(Vector2i(0, 1)) < 0)

func test_is_coord_in_bounds_corner() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	assert(_map.is_coord_in_bounds(Vector2i(0, 0)))
	assert(_map.is_coord_in_bounds(Vector2i(11, 15)))

func test_is_coord_in_bounds_outside() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	assert(not _map.is_coord_in_bounds(Vector2i(-1, 0)))
	assert(not _map.is_coord_in_bounds(Vector2i(0, 16)))
	assert(not _map.is_coord_in_bounds(Vector2i(12, 0)))
