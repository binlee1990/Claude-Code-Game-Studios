class_name MovementSystem
extends RefCounted

## Grid-based movement calculator using Dijkstra with terrain costs.

const BASE_MOVEMENT: int = 5

var _dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## Get all cells reachable from start within movement budget.
func get_reachable_cells(grid: Array, start: Vector2i, max_movement: int = BASE_MOVEMENT) -> Array:
	var costs := _dijkstra(grid, start, max_movement)
	var reachable: Array = []
	for pos in costs:
		if pos != start:
			reachable.append(pos)
	return reachable

## Check if a specific target cell is reachable.
func is_reachable(grid: Array, start: Vector2i, target: Vector2i, max_movement: int = BASE_MOVEMENT) -> bool:
	var costs := _dijkstra(grid, start, max_movement)
	return costs.has(target)

## Get movement cost to reach a specific cell. Returns -1.0 if unreachable.
func get_cost_to(grid: Array, start: Vector2i, target: Vector2i, max_movement: int = BASE_MOVEMENT) -> float:
	var costs := _dijkstra(grid, start, max_movement)
	if costs.has(target):
		return costs[target]
	return -1.0

## Calculate total cost along a specific path. Returns -1.0 if blocked.
func calculate_path_cost(grid: Array, path: Array) -> float:
	if path.size() < 2:
		return 0.0
	var total: float = 0.0
	for i in range(1, path.size()):
		var pos: Vector2i = path[i]
		if not _is_valid(grid, pos):
			return -1.0
		var terrain: int = grid[pos.y][pos.x]
		if TerrainTypes.blocks_movement(terrain):
			return -1.0
		total += TerrainTypes.get_movement_cost(terrain)
	return total

func _dijkstra(grid: Array, start: Vector2i, max_movement: int) -> Dictionary:
	var costs: Dictionary = {}
	costs[start] = 0.0
	var frontier: Array = [{"pos": start, "cost": 0.0}]
	while frontier.size() > 0:
		var min_idx: int = 0
		for i in range(1, frontier.size()):
			if frontier[i]["cost"] < frontier[min_idx]["cost"]:
				min_idx = i
		var current = frontier.pop_at(min_idx)
		var pos: Vector2i = current["pos"]
		var cost: float = current["cost"]
		if cost > costs.get(pos, INF):
			continue
		for d in _dirs:
			var neighbor: Vector2i = pos + d
			if not _is_valid(grid, neighbor):
				continue
			var terrain: int = grid[neighbor.y][neighbor.x]
			if TerrainTypes.blocks_movement(terrain):
				continue
			var move_cost: float = TerrainTypes.get_movement_cost(terrain)
			var new_cost: float = cost + move_cost
			if new_cost <= float(max_movement) and new_cost < costs.get(neighbor, INF):
				costs[neighbor] = new_cost
				frontier.append({"pos": neighbor, "cost": new_cost})
	return costs

func _is_valid(grid: Array, pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= grid.size():
		return false
	if grid.size() == 0 or pos.x < 0 or pos.x >= grid[pos.y].size():
		return false
	return true
