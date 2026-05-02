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

	var frontier: Array = [unit.grid_position]
	result._dist[unit.grid_position] = 0
	result.reachable.append(unit.grid_position)

	var limit := unit.mov
	if limit <= 0:
		return result

	while not frontier.is_empty():
		var current := _pop_lowest_cost_tile(frontier, result._dist)
		var current_dist: int = result._dist[current]

		if current_dist >= limit:
			continue

		for neighbor: Vector2i in map.get_neighbors(current):
			if not map.is_walkable(neighbor):
				continue
			var next_dist := current_dist + map.get_movement_cost(neighbor)
			if next_dist > limit:
				continue
			if result._dist.has(neighbor) and next_dist >= int(result._dist[neighbor]):
				continue

			var is_new := not result._dist.has(neighbor)
			result.parents[neighbor] = current
			result._dist[neighbor] = next_dist
			if is_new:
				result.reachable.append(neighbor)
			if not frontier.has(neighbor):
				frontier.append(neighbor)

	return result

func _pop_lowest_cost_tile(frontier: Array, distances: Dictionary) -> Vector2i:
	var best_index := 0
	for i in range(1, frontier.size()):
		var candidate: Vector2i = frontier[i]
		var current_best: Vector2i = frontier[best_index]
		var candidate_dist: int = distances[candidate]
		var best_dist: int = distances[current_best]
		if candidate_dist < best_dist:
			best_index = i
		elif candidate_dist == best_dist and _is_coord_before(candidate, current_best):
			best_index = i

	var result: Vector2i = frontier[best_index]
	frontier.remove_at(best_index)
	return result

func _is_coord_before(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y
