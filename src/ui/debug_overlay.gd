class_name DebugOverlay extends Node2D

const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const GRID_LINE_WIDTH := 1.0
const COORDINATE_TEXT_OFFSET := Vector2(-14, 4)
const COORDINATE_FONT_SIZE := 10

var _grid_space: GridSpace
var _map: Map
var _coordinates_visible: bool = true

func initialize(grid_space: GridSpace, p_map: Map) -> void:
	_grid_space = grid_space
	_map = p_map
	queue_redraw()

func toggle() -> void:
	_coordinates_visible = not _coordinates_visible
	queue_redraw()

func are_coordinates_visible() -> bool:
	return _coordinates_visible

func get_grid_line_segments() -> Array:
	var result: Array = []
	if _map == null:
		return result

	var width := _map.columns * GridSpace.TILE_SIZE
	var height := _map.rows * GridSpace.TILE_SIZE
	for col in range(_map.columns + 1):
		var x := col * GridSpace.TILE_SIZE
		result.append({"from": Vector2(x, 0), "to": Vector2(x, height)})
	for row in range(_map.rows + 1):
		var y := row * GridSpace.TILE_SIZE
		result.append({"from": Vector2(0, y), "to": Vector2(width, y)})
	return result

func get_coordinate_draw_items() -> Array:
	var result: Array = []
	if _grid_space == null or _map == null:
		return result

	for row in range(_map.rows):
		for col in range(_map.columns):
			var coord := Vector2i(row, col)
			result.append({
				"coord": coord,
				"text": "(%d,%d)" % [row, col],
				"position": _grid_space.tile_center(coord) + COORDINATE_TEXT_OFFSET,
			})
	return result

func _draw() -> void:
	if _grid_space == null or _map == null:
		return

	for segment in get_grid_line_segments():
		draw_line(segment["from"], segment["to"], GRID_LINE_COLOR, GRID_LINE_WIDTH)

	if not _coordinates_visible:
		return
	if not is_inside_tree():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return

	for item in get_coordinate_draw_items():
		draw_string(font, item["position"], item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, COORDINATE_FONT_SIZE, Color.WHITE)
