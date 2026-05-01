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
