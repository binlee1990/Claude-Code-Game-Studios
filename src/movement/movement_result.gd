class_name MovementResult extends RefCounted

var reachable: Array[Vector2i] = []
var parents: Dictionary = {}
var start: Vector2i
var _dist: Dictionary = {}

func get_reachable_tiles() -> Array[Vector2i]:
	return reachable.duplicate()

func get_path_to(target: Vector2i) -> Array[Vector2i]:
	if not parents.has(target) and target != start:
		return []
	var path: Array[Vector2i] = []
	var current := target
	while current != start:
		path.append(current)
		current = parents[current]
	path.append(start)
	path.reverse()
	return path

func get_distance_to(target: Vector2i) -> int:
	if target == start:
		return 0
	if not _dist.has(target):
		return -1
	return _dist[target]

func get_start_tile() -> Vector2i:
	return start
