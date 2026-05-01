# Story map/001: GridSpace coordinate transform tests
# TR-map-001, TR-map-007 | ADR-0001

const TILE_SIZE: int = 64

func test_gridspace_grid_to_world_origin_returns_zero() -> void:
	var gs := GridSpace.new()
	assert(gs.grid_to_world(Vector2i(0, 0)) == Vector2(0, 0))

func test_gridspace_grid_to_world_row_increases_y() -> void:
	var gs := GridSpace.new()
	# grid_to_world(row=1, col=0) → (col*64, row*64) = (0, 64)
	assert(gs.grid_to_world(Vector2i(1, 0)) == Vector2(0, 64))

func test_gridspace_grid_to_world_col_increases_x() -> void:
	var gs := GridSpace.new()
	# grid_to_world(row=0, col=1) → (64, 0)
	assert(gs.grid_to_world(Vector2i(0, 1)) == Vector2(64, 0))

func test_gridspace_grid_to_world_standard_position() -> void:
	var gs := GridSpace.new()
	# AC-F1: grid_to_world(2, 3) → Vector2(192, 128)
	assert(gs.grid_to_world(Vector2i(2, 3)) == Vector2(192, 128))

func test_gridspace_world_to_grid_origin() -> void:
	var gs := GridSpace.new()
	assert(gs.world_to_grid(Vector2(0, 0)) == Vector2i(0, 0))

func test_gridspace_world_to_grid_standard_position() -> void:
	var gs := GridSpace.new()
	# AC-F2: world_to_grid(215, 150) → Vector2i(2, 3)
	assert(gs.world_to_grid(Vector2(215, 150)) == Vector2i(2, 3))

func test_gridspace_world_to_grid_negative_pixels_returns_negative_coords() -> void:
	var gs := GridSpace.new()
	# Edge case: negative pixels → negative grid coords (caller does bounds check)
	var result := gs.world_to_grid(Vector2(-10, -10))
	assert(result.x < 0)
	assert(result.y < 0)

func test_gridspace_tile_center_origin() -> void:
	var gs := GridSpace.new()
	# tile_center(0,0) → (32, 32)
	assert(gs.tile_center(Vector2i(0, 0)) == Vector2(32, 32))

func test_gridspace_tile_center_standard_position() -> void:
	var gs := GridSpace.new()
	# AC-F3: tile_center(2, 3) → Vector2(224, 160)
	assert(gs.tile_center(Vector2i(2, 3)) == Vector2(224, 160))

func test_gridspace_roundtrip_grid_to_world_to_grid() -> void:
	var gs := GridSpace.new()
	var grid_pos := Vector2i(5, 7)
	var world := gs.grid_to_world(grid_pos)
	var back := gs.world_to_grid(world)
	assert(back == grid_pos)

func test_gridspace_tile_size_is_64() -> void:
	assert(GridSpace.TILE_SIZE == 64)
