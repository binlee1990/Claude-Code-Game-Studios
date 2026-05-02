class_name FogStateManager
extends RefCounted

enum FogCellState { UNKNOWN = 0, EXPLORED = 1, VISIBLE = 2 }

const BASE_VISION: int = 3
const SCOUT_BONUS: int = 3
const HEIGHT_BONUS: int = 1
const LIGHT_BONUS: int = 2

var _explored_cells: Dictionary = {}
var _visible_cells: Dictionary = {}
var _enabled: bool = false
var _base_vision: int = BASE_VISION


func is_enabled() -> bool:
	return _enabled


func set_enabled(v: bool) -> void:
	_enabled = v
	if not _enabled:
		clear()


func set_base_vision(value: int) -> void:
	_base_vision = maxi(value, 0)


func get_cell_state(cell: Vector2i) -> int:
	if not _enabled:
		return FogCellState.VISIBLE
	if _visible_cells.has(cell):
		return FogCellState.VISIBLE
	if _explored_cells.has(cell):
		return FogCellState.EXPLORED
	return FogCellState.UNKNOWN


func is_cell_visible(cell: Vector2i) -> bool:
	return get_cell_state(cell) == FogCellState.VISIBLE


func is_cell_explored(cell: Vector2i) -> bool:
	var state := get_cell_state(cell)
	return state == FogCellState.VISIBLE or state == FogCellState.EXPLORED


func reveal_from_position(pos: Vector2i, vision_range: int) -> void:
	if not _enabled:
		return
	for dx in range(-vision_range, vision_range + 1):
		for dy in range(-vision_range, vision_range + 1):
			var cell := Vector2i(pos.x + dx, pos.y + dy)
			_visible_cells[cell] = true
			_explored_cells[cell] = true


func recalculate_visible(unit_positions: Array, unit_vision_ranges: Array) -> void:
	if not _enabled:
		return
	_visible_cells.clear()
	for i in range(unit_positions.size()):
		reveal_from_position(unit_positions[i], unit_vision_ranges[i])


func calculate_vision_range(agility: int, class_id: String = "", on_high_ground: bool = false, near_light: bool = false) -> int:
	var vision := _base_vision
	if agility >= 80:
		vision += 2
	elif agility >= 60:
		vision += 1
	if class_id == "scout":
		vision += SCOUT_BONUS
	if on_high_ground:
		vision += HEIGHT_BONUS
	if near_light:
		vision += LIGHT_BONUS
	return vision


func get_explored_cells() -> Array:
	return _explored_cells.keys()


func set_explored_cells(cells: Array) -> void:
	_explored_cells.clear()
	for cell in cells:
		if cell is Vector2i:
			_explored_cells[cell] = true


func clear() -> void:
	_explored_cells.clear()
	_visible_cells.clear()
