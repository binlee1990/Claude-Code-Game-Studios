# Story map/003: Grid topology — neighbor + bounds tests
# TR-map-005 | ADR-0005

var _map: Map

func after() -> void:
	if is_instance_valid(_map):
		_map.free()

func before() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")

func test_get_neighbors_interior_tile_returns_four_cardinal() -> void:
	var neighbors = _map.get_neighbors(Vector2i(5, 5))
	assert(neighbors.size() == 4)

func test_get_neighbors_corner_tile_returns_two() -> void:
	var neighbors = _map.get_neighbors(Vector2i(0, 0))
	assert(neighbors.size() == 2)
	# Must include only cardinal directions
	for n in neighbors:
		assert(n == Vector2i(1, 0) or n == Vector2i(0, 1))

func test_get_neighbors_edge_tile_returns_three() -> void:
	var neighbors = _map.get_neighbors(Vector2i(0, 5))
	assert(neighbors.size() == 3)

func test_get_neighbors_no_diagonal() -> void:
	var neighbors = _map.get_neighbors(Vector2i(5, 5))
	for n in neighbors:
		var diff = n - Vector2i(5, 5)
		# von Neumann: |dr| + |dc| == 1
		assert(abs(diff.x) + abs(diff.y) == 1)

func test_get_neighbors_includes_blocked_tiles() -> void:
	# (2,4) is blocked but should still appear as neighbor of (2,5)
	var neighbors = _map.get_neighbors(Vector2i(2, 5))
	var has_blocked = false
	for n in neighbors:
		if n == Vector2i(2, 4):
			has_blocked = true
	assert(has_blocked)

func test_is_walkable_empty_walkable_tile_returns_true() -> void:
	# Tile (0,0) is walkable and unoccupied
	assert(_map.is_walkable(Vector2i(0, 0)))

func test_is_walkable_blocked_tile_returns_false() -> void:
	# Tile (2,4) is blocked
	assert(not _map.is_walkable(Vector2i(2, 4)))

func test_is_walkable_out_of_bounds_returns_false() -> void:
	assert(not _map.is_walkable(Vector2i(-1, 0)))
	assert(not _map.is_walkable(Vector2i(0, 100)))
