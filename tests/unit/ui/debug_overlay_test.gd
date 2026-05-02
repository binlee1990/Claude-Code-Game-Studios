extends RefCounted

func _make_map(rows: int, columns: int) -> Map:
	var map := Map.new()
	map.grid_space = GridSpace.new()
	map._rows = rows
	map._cols = columns
	return map

func test_debug_overlay_coordinate_items_cover_full_map_extents() -> void:
	var overlay := DebugOverlay.new()
	overlay.initialize(GridSpace.new(), _make_map(12, 16))

	var items := overlay.get_coordinate_draw_items()
	var has_enemy_tile := false
	var has_swapped_out_of_bounds_tile := false
	for item in items:
		if item["coord"] == Vector2i(5, 12) and item["text"] == "(5,12)":
			has_enemy_tile = true
		if item["coord"] == Vector2i(12, 5):
			has_swapped_out_of_bounds_tile = true

	assert(items.size() == 12 * 16)
	assert(has_enemy_tile)
	assert(not has_swapped_out_of_bounds_tile)
	overlay.free()

func test_debug_overlay_grid_lines_cover_tile_boundaries() -> void:
	var overlay := DebugOverlay.new()
	overlay.initialize(GridSpace.new(), _make_map(12, 16))

	var segments := overlay.get_grid_line_segments()
	var has_right_edge := false
	var has_bottom_edge := false
	for segment in segments:
		if segment["from"] == Vector2(1024, 0) and segment["to"] == Vector2(1024, 768):
			has_right_edge = true
		if segment["from"] == Vector2(0, 768) and segment["to"] == Vector2(1024, 768):
			has_bottom_edge = true

	assert(segments.size() == 17 + 13)
	assert(has_right_edge)
	assert(has_bottom_edge)
	overlay.free()

func test_debug_overlay_toggle_only_hides_coordinates() -> void:
	var overlay := DebugOverlay.new()
	overlay.initialize(GridSpace.new(), _make_map(12, 16))
	var before_segments := overlay.get_grid_line_segments().size()

	assert(overlay.are_coordinates_visible())
	overlay.toggle()

	assert(not overlay.are_coordinates_visible())
	assert(overlay.get_grid_line_segments().size() == before_segments)
	overlay.free()
