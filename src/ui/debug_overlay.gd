class_name DebugOverlay extends Node2D

var _grid_space: GridSpace
var _map: Map
var _visible: bool = true

func initialize(grid_space: GridSpace, p_map: Map) -> void:
	_grid_space = grid_space
	_map = p_map
	queue_redraw()

func toggle() -> void:
	_visible = not _visible
	queue_redraw()

func _draw() -> void:
	if not _visible:
		return
	if _grid_space == null or _map == null:
		return

	if not is_inside_tree():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return

	for y in _map.rows:
		for x in _map.columns:
			var coord := Vector2i(x, y)
			var center := _grid_space.tile_center(coord)
			var text := "(%d,%d)" % [x, y]
			draw_string(font, center + Vector2(-14, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
