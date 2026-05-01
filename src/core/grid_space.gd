class_name GridSpace extends RefCounted

const TILE_SIZE: int = 64

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.y / TILE_SIZE), floori(world_pos.x / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.y * TILE_SIZE, grid_pos.x * TILE_SIZE)

func tile_center(grid_pos: Vector2i) -> Vector2:
	return grid_to_world(grid_pos) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
