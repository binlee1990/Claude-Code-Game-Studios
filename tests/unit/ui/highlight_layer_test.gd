extends RefCounted

const HighlightLayer = preload("res://src/ui/highlight_layer.gd")

func test_initialize_stores_color() -> void:
	var layer := HighlightLayer.new()
	layer.initialize(GridSpace.new(), Color("#0891B2"))
	assert(layer.get_highlight_color() == Color("#0891B2"))

func test_set_highlight_stores_defensive_copy_and_emits() -> void:
	var layer := HighlightLayer.new()
	layer.initialize(GridSpace.new(), Color("#06B6D4"))
	var observed := {"signal_count": 0}
	layer.highlight_changed.connect(func(_tiles: Array): observed["signal_count"] += 1)

	var tiles := [Vector2i(1, 2), Vector2i(3, 4)]
	layer.set_highlight(tiles)
	tiles.clear()

	assert(observed["signal_count"] == 1)
	assert(layer.get_highlight_tiles().size() == 2)
	assert(layer.get_highlight_tiles()[0] == Vector2i(1, 2))

func test_clear_removes_all_highlights_and_emits() -> void:
	var layer := HighlightLayer.new()
	layer.initialize(GridSpace.new(), Color("#EA580C"))
	var observed := {"signal_count": 0}
	layer.highlight_changed.connect(func(_tiles: Array): observed["signal_count"] += 1)

	layer.set_highlight([Vector2i(1, 1)])
	layer.clear()

	assert(observed["signal_count"] == 2)
	assert(layer.get_highlight_tiles().is_empty())

func test_highlight_rects_use_grid_space_and_tile_size() -> void:
	var layer := HighlightLayer.new()
	layer.initialize(GridSpace.new(), Color("#0891B2"))
	layer.set_highlight([Vector2i(2, 3)])

	var rects := layer.get_highlight_rects()
	assert(rects.size() == 1)
	assert(rects[0].position == Vector2(192, 128))
	assert(rects[0].size == Vector2(GridSpace.TILE_SIZE, GridSpace.TILE_SIZE))

func test_z_index_can_follow_move_path_attack_order() -> void:
	var move_layer := HighlightLayer.new()
	var path_layer := HighlightLayer.new()
	var attack_layer := HighlightLayer.new()

	move_layer.z_index = 1
	path_layer.z_index = 2
	attack_layer.z_index = 3

	assert(move_layer.z_index < path_layer.z_index)
	assert(path_layer.z_index < attack_layer.z_index)
