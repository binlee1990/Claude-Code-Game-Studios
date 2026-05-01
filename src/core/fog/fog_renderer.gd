class_name FogRenderer
extends Node

const COLOR_UNKNOWN: Color = Color(0.0, 0.0, 0.0, 0.55)
const COLOR_EXPLORED: Color = Color(0.0, 0.0, 0.0, 0.25)
const COLOR_VISIBLE: Color = Color(0.0, 0.0, 0.0, 0.0)

var _fog_state: FogStateManager = null
var _overlay_layer: TileMapLayer = null
var _grid_origin: Vector2i = Vector2i.ZERO
var _cell_size: int = 64
var _fusion_builder: Resource = null


func setup(fog_state: FogStateManager, overlay_layer: TileMapLayer, grid_origin: Vector2i, cell_size: int) -> void:
	_fog_state = fog_state
	_overlay_layer = overlay_layer
	_grid_origin = grid_origin
	_cell_size = cell_size


func refresh_overlay(grid_width: int, grid_height: int) -> void:
	if _overlay_layer == null or _fog_state == null:
		return
	_overlay_layer.clear()
	if not _fog_state.is_enabled():
		return
	for x: int in range(grid_width):
		for y: int in range(grid_height):
			var cell: Vector2i = Vector2i(x, y)
			var state: int = _fog_state.get_cell_state(cell)
			var color: Color = _state_to_color(state)
			if color.a > 0.0:
				_set_cell_color(cell, color)


func refresh_cell(cell: Vector2i) -> void:
	if _overlay_layer == null or _fog_state == null:
		return
	if not _fog_state.is_enabled():
		return
	var state: int = _fog_state.get_cell_state(cell)
	var color: Color = _state_to_color(state)
	if color.a > 0.0:
		_set_cell_color(cell, color)
	else:
		_overlay_layer.erase_cell(_grid_to_tilemap(cell))


func _state_to_color(state: int) -> Color:
	match state:
		FogStateManager.FogCellState.UNKNOWN:
			return COLOR_UNKNOWN
		FogStateManager.FogCellState.EXPLORED:
			return COLOR_EXPLORED
		_:
			return COLOR_VISIBLE


func _set_cell_color(cell: Vector2i, color: Color) -> void:
	var tile_pos: Vector2i = _grid_to_tilemap(cell)
	_overlay_layer.set_cell(tile_pos, 0, Vector2i.ZERO)
	_overlay_layer.set_cell_tile_data(tile_pos, 0, _build_tile_data(color))


func _build_tile_data(color: Color) -> TileData:
	if _fusion_builder == null:
		_fusion_builder = _create_fusion_builder()
	if _fusion_builder == null:
		return TileData.new()
	return _fusion_builder.color(color)


func _create_fusion_builder() -> Resource:
	var script: GDScript = load("res://src/core/fog/fusion_builder.gd") as GDScript
	if script:
		var builder: RefCounted = script.new()
		if builder:
			return builder
	return null


func _grid_to_tilemap(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x + _grid_origin.x, cell.y + _grid_origin.y)


func get_color_for_state(state: int) -> Color:
	return _state_to_color(state)
