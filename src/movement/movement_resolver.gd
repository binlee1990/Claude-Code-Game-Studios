class_name MovementResolver extends RefCounted

const MovementResult = preload("res://src/movement/movement_result.gd")

static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func compute_reachable(unit: Unit, map: Map) -> MovementResult:
	var result := MovementResult.new()

	if unit == null:
		return result
	result.start = unit.grid_position
	if not unit.is_alive():
		return result
	if map == null:
		return result
	if not map.is_coord_in_bounds(unit.grid_position):
		return result

	var visited: Dictionary = {}
	var queue: Array = [unit.grid_position]
	visited[unit.grid_position] = true
	result._dist[unit.grid_position] = 0
	result.reachable.append(unit.grid_position)

	var head: int = 0
	var limit := unit.mov
	if limit <= 0:
		return result

	while head < queue.size():
		var current = queue[head]
		head += 1
		var current_dist: int = result._dist[current]

		if current_dist >= limit:
			continue

		for neighbor: Vector2i in map.get_neighbors(current):
			if visited.has(neighbor):
				continue
			if not map.is_walkable(neighbor):
				continue
			visited[neighbor] = true
			result.parents[neighbor] = current
			result._dist[neighbor] = current_dist + 1
			result.reachable.append(neighbor)
			queue.append(neighbor)

	return result
