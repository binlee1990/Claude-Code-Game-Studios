class_name HighlightLayer extends Node2D

var _tiles: Array = []
var _color: Color
var _grid_space: GridSpace

func initialize(grid_space: GridSpace, color: Color) -> void:
	_grid_space = grid_space
	_color = color

func set_highlight(tiles: Array) -> void:
	_tiles = tiles
	queue_redraw()

func clear() -> void:
	_tiles.clear()
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(0, 0, GridSpace.TILE_SIZE, GridSpace.TILE_SIZE)
	for tile in _tiles:
		rect.position = _grid_space.grid_to_world(tile)
		draw_rect(rect, _color)
