# tests/unit/turn/movement_system_test.gd
# Story 003: Movement System
# Validates AC-M1, AC-M2, AC-M3, AC-M4

extends Gut

var _move: MovementSystem

func before_each() -> void:
	_move = MovementSystem.new()

func _make_grid(width: int, height: int, terrain: int = TerrainTypes.Terrain.NORMAL) -> Array:
	var grid: Array = []
	for _y in range(height):
		var row: Array = []
		for _x in range(width):
			row.append(terrain)
		grid.append(row)
	return grid

func _set_terrain(grid: Array, x: int, y: int, terrain: int) -> void:
	grid[y][x] = terrain


# --- AC-M1: Base movement = 5 cells ---

func test_reach_5_cells_normal_terrain() -> void:
	var grid = _make_grid(11, 11)
	var reachable = _move.get_reachable_cells(grid, Vector2i(5, 5), 5)
	assert_true(Vector2i(10, 5) in reachable, "Reach 5 right")
	assert_true(Vector2i(0, 5) in reachable, "Reach 5 left")
	assert_true(Vector2i(5, 0) in reachable, "Reach 5 up")
	assert_true(Vector2i(5, 10) in reachable, "Reach 5 down")

func test_reachable_count_normal_terrain() -> void:
	var grid = _make_grid(11, 11)
	var reachable = _move.get_reachable_cells(grid, Vector2i(5, 5), 5)
	assert_eq(reachable.size(), 60, "60 cells in diamond radius 5")

func test_surrounded_by_obstacles_no_movement() -> void:
	var grid = _make_grid(3, 3)
	_set_terrain(grid, 0, 0, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 1, 0, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 2, 0, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 0, 1, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 2, 1, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 0, 2, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 1, 2, TerrainTypes.Terrain.OBSTACLE)
	_set_terrain(grid, 2, 2, TerrainTypes.Terrain.OBSTACLE)
	var reachable = _move.get_reachable_cells(grid, Vector2i(1, 1), 5)
	assert_eq(reachable.size(), 0, "No reachable cells when surrounded")

func test_cannot_exceed_movement_range() -> void:
	var grid = _make_grid(11, 1)
	var reachable = _move.get_reachable_cells(grid, Vector2i(5, 0), 3)
	assert_true(Vector2i(2, 0) in reachable, "3 cells away reachable")
	assert_false(Vector2i(1, 0) in reachable, "4 cells away not reachable with movement 3")

func test_zero_movement_no_reachable() -> void:
	var grid = _make_grid(5, 5)
	var reachable = _move.get_reachable_cells(grid, Vector2i(2, 2), 0)
	assert_eq(reachable.size(), 0, "No cells reachable with 0 movement")


# --- AC-M2: Sand terrain costs 2× ---

func test_sand_costs_double_reduces_range() -> void:
	var grid = _make_grid(11, 1, TerrainTypes.Terrain.NORMAL)
	for x in range(3, 8):
		_set_terrain(grid, x, 0, TerrainTypes.Terrain.SAND)
	var reachable = _move.get_reachable_cells(grid, Vector2i(2, 0), 5)
	assert_true(Vector2i(3, 0) in reachable, "First sand cell reachable (cost 2)")
	assert_true(Vector2i(4, 0) in reachable, "Second sand cell reachable (cost 4)")
	assert_false(Vector2i(5, 0) in reachable, "Third sand cell not reachable (cost 6 > 5)")

func test_sand_mixed_path_cost() -> void:
	var grid = _make_grid(10, 1)
	_set_terrain(grid, 3, 0, TerrainTypes.Terrain.SAND)
	var cost = _move.calculate_path_cost(grid, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	])
	assert_eq(cost, 4.0, "2 normal + 1 sand = cost 4")

func test_all_sand_halves_range() -> void:
	var grid = _make_grid(11, 1, TerrainTypes.Terrain.SAND)
	var reachable = _move.get_reachable_cells(grid, Vector2i(5, 0), 5)
	assert_true(Vector2i(7, 0) in reachable, "2 sand cells right (cost 4)")
	assert_false(Vector2i(8, 0) in reachable, "3 sand cells right not reachable (cost 6)")


# --- AC-M3: Obstacles block movement ---

func test_obstacle_blocks_path() -> void:
	var grid = _make_grid(5, 1)
	_set_terrain(grid, 2, 0, TerrainTypes.Terrain.OBSTACLE)
	var reachable = _move.get_reachable_cells(grid, Vector2i(0, 0), 5)
	assert_true(Vector2i(1, 0) in reachable, "Cell before obstacle reachable")
	assert_false(Vector2i(2, 0) in reachable, "Obstacle not reachable")
	assert_false(Vector2i(3, 0) in reachable, "Cell beyond obstacle not reachable")

func test_obstacle_cell_excluded() -> void:
	var grid = _make_grid(3, 3)
	_set_terrain(grid, 1, 1, TerrainTypes.Terrain.OBSTACLE)
	var reachable = _move.get_reachable_cells(grid, Vector2i(0, 0), 5)
	assert_false(Vector2i(1, 1) in reachable, "Obstacle excluded from reachable")

func test_path_through_obstacle_returns_negative() -> void:
	var grid = _make_grid(5, 1)
	_set_terrain(grid, 2, 0, TerrainTypes.Terrain.OBSTACLE)
	var cost = _move.calculate_path_cost(grid, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	])
	assert_eq(cost, -1.0, "Blocked path returns -1")

func test_pathfind_around_obstacle() -> void:
	# 3x3 grid, obstacle at center
	var grid = _make_grid(3, 3)
	_set_terrain(grid, 1, 1, TerrainTypes.Terrain.OBSTACLE)
	var reachable = _move.get_reachable_cells(grid, Vector2i(0, 0), 5)
	# Can reach (2,0) via (1,0), (2,2) via (2,1) or (1,2)
	assert_true(Vector2i(2, 0) in reachable, "Can path around obstacle")
	assert_true(Vector2i(2, 2) in reachable, "Can reach opposite corner around obstacle")


# --- AC-M4: Movement can be interrupted ---

func test_partial_move_cost_within_budget() -> void:
	var grid = _make_grid(10, 1)
	var cost = _move.get_cost_to(grid, Vector2i(0, 0), Vector2i(3, 0), 5)
	assert_eq(cost, 3.0, "Cost to cell 3 is 3")
	assert_true(cost <= 5.0, "Cell 3 reachable within budget")

func test_stop_at_any_reachable_cell() -> void:
	var grid = _make_grid(10, 1)
	for i in range(1, 6):
		var cost = _move.get_cost_to(grid, Vector2i(0, 0), Vector2i(i, 0), 5)
		assert_true(cost > 0.0 and cost <= 5.0, "Cell %d reachable" % i)

func test_stay_in_place_valid() -> void:
	var grid = _make_grid(5, 5)
	var reachable = _move.get_reachable_cells(grid, Vector2i(2, 2), 5)
	assert_false(Vector2i(2, 2) in reachable, "Start not in reachable (already there)")


# --- Additional coverage ---

func test_path_cost_all_normal() -> void:
	var grid = _make_grid(5, 1)
	var cost = _move.calculate_path_cost(grid, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	])
	assert_eq(cost, 3.0, "3 normal cells = cost 3")

func test_path_single_cell_zero_cost() -> void:
	var grid = _make_grid(3, 3)
	var cost = _move.calculate_path_cost(grid, [Vector2i(1, 1)])
	assert_eq(cost, 0.0, "Single cell path = 0 cost")

func test_is_reachable_true() -> void:
	var grid = _make_grid(5, 5)
	assert_true(_move.is_reachable(grid, Vector2i(2, 2), Vector2i(4, 2), 5), "Reachable cell")

func test_is_reachable_false_obstacle() -> void:
	var grid = _make_grid(5, 1)
	_set_terrain(grid, 2, 0, TerrainTypes.Terrain.OBSTACLE)
	assert_false(_move.is_reachable(grid, Vector2i(0, 0), Vector2i(4, 0), 5), "Behind obstacle unreachable")
