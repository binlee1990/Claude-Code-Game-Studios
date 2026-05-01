class_name FogTargetFilter
extends RefCounted

var _fog_state: FogStateManager = null


func setup(fog_state: FogStateManager) -> void:
	_fog_state = fog_state


func is_targetable(cell: Vector2i) -> bool:
	if _fog_state == null:
		return true
	if not _fog_state.is_enabled():
		return true
	return _fog_state.is_cell_visible(cell)


func filter_targets(targets: Array, get_cell_func: Callable) -> Array:
	if _fog_state == null or not _fog_state.is_enabled():
		return targets.duplicate()
	var filtered: Array = []
	for target in targets:
		var cell: Vector2i = get_cell_func.call(target)
		if is_targetable(cell):
			filtered.append(target)
	return filtered


func filter_positions(positions: Array) -> Array:
	if _fog_state == null or not _fog_state.is_enabled():
		return positions.duplicate()
	var filtered: Array = []
	for pos in positions:
		if pos is Vector2i and is_targetable(pos):
			filtered.append(pos)
	return filtered
