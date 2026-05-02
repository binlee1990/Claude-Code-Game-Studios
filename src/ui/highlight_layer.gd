class_name HighlightLayer extends Node2D

var _tiles: Array = []
var _color: Color
var _grid_space: GridSpace

signal highlight_changed(tiles: Array)

static var _test_instances: Array = []

func _init() -> void:
	_test_instances.append(weakref(self))

static func free_test_instances() -> void:
	for ref in _test_instances:
		var layer = ref.get_ref()
		if is_instance_valid(layer):
			layer.free()
	_test_instances.clear()

func initialize(grid_space: GridSpace, color: Color) -> void:
	_grid_space = grid_space
	_color = color

func set_highlight(tiles: Array) -> void:
	_tiles = tiles.duplicate()
	queue_redraw()
	highlight_changed.emit(get_highlight_tiles())

func clear() -> void:
	_tiles.clear()
	queue_redraw()
	highlight_changed.emit([])

func get_highlight_tiles() -> Array:
	return _tiles.duplicate()

func get_highlight_color() -> Color:
	return _color

func get_highlight_rects() -> Array:
	var rects: Array = []
	if _grid_space == null:
		return rects
	for tile in _tiles:
		rects.append(Rect2(_grid_space.grid_to_world(tile), Vector2(GridSpace.TILE_SIZE, GridSpace.TILE_SIZE)))
	return rects

func _draw() -> void:
	for rect in get_highlight_rects():
		draw_rect(rect, _color)
