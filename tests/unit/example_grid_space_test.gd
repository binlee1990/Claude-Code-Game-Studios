## Example GdUnit4 test for GridSpace coordinate transforms (ADR-0001).
##
## This file confirms the test framework is functional and demonstrates
## the project's test naming conventions:
##   File: [system]_[feature]_test.gd
##   Func: test_[scenario]_[expected]
##
## Requires GdUnit4 addon installed in Godot project.

const TILE_SIZE: int = 64

## GridSpace mock — replicates ADR-0001's public interface without scene tree dependency.
## In production, import from src/core/grid_space.gd instead.
class GridSpace:
	extends RefCounted

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(floori(world_pos.y / TILE_SIZE), floori(world_pos.x / TILE_SIZE))

	func grid_to_world(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.y * TILE_SIZE, grid_pos.x * TILE_SIZE)

	func tile_center(grid_pos: Vector2i) -> Vector2:
		return grid_to_world(grid_pos) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)


func test_world_to_grid_origin() -> void:
	var gs := GridSpace.new()
	assert(gs.world_to_grid(Vector2(0, 0)) == Vector2i(0, 0))


func test_world_to_grid_positive() -> void:
	var gs := GridSpace.new()
	# Pixel (128, 64) → grid row=1, col=2
	assert(gs.world_to_grid(Vector2(128, 64)) == Vector2i(1, 2))


func test_grid_to_world_basic() -> void:
	var gs := GridSpace.new()
	# Grid (row=1, col=2) → pixel (192, 128)
	assert(gs.grid_to_world(Vector2i(1, 2)) == Vector2(128, 192))


func test_tile_center_returns_midpoint() -> void:
	var gs := GridSpace.new()
	var center := gs.tile_center(Vector2i(0, 0))
	assert(center == Vector2(32, 32))


func test_roundtrip_identity() -> void:
	var gs := GridSpace.new()
	var world := Vector2(200, 150)
	var grid := gs.world_to_grid(world)
	# Roundtrip preserves grid coordinate
	assert(grid == Vector2i(2, 3))
	assert(gs.grid_to_world(grid) == Vector2(128, 192))
