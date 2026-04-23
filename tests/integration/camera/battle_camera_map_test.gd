# tests/integration/camera/battle_camera_map_test.gd
# Camera & map presentation regression coverage.

extends Gut

var _battle

func before_each() -> void:
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_default_camera_and_map_state() -> void:
	assert_eq(_battle.get_map_size(), 15)
	assert_eq(_battle.get_camera_rotation_degrees(), 0)
	assert_true(_battle.is_grid_overlay_enabled())
	assert_eq(_battle._cells.size(), 225, "15x15 map should build 225 projected cells")

func test_camera_rotation_is_locked_for_top_down_slice() -> void:
	var before: Vector2 = _battle.get_cell_click_point(Vector2i(2, 5))
	_battle.rotate_camera(1)
	var after: Vector2 = _battle.get_cell_click_point(Vector2i(2, 5))
	assert_eq(_battle.get_camera_rotation_degrees(), 0)
	assert_eq(before, after, "Top-down slice keeps a fixed orthographic view")

func test_map_size_presets_rebuild_cells() -> void:
	_battle.set_map_size(20)
	assert_eq(_battle.get_map_size(), 20)
	assert_eq(_battle._cells.size(), 400)
	_battle.set_map_size(25)
	assert_eq(_battle.get_map_size(), 25)
	assert_eq(_battle._cells.size(), 625)

func test_grid_overlay_toggle_changes_alpha() -> void:
	var sample := Vector2i(0, 0)
	var before_alpha: float = (_battle._cells[sample] as ColorRect).color.a
	_battle.set_grid_overlay_enabled(false)
	var after_alpha: float = (_battle._cells[sample] as ColorRect).color.a
	assert_true(after_alpha < before_alpha, "Grid overlay toggle should reduce tile visibility")

func test_height_map_contains_all_three_levels() -> void:
	var found := {}
	for height in _battle._map_heights.values():
		found[height] = true
	assert_true(found.has(0), "Generated map should include lowland cells")
	assert_true(found.has(1), "Generated map should include plain cells")
	assert_true(found.has(2), "Generated map should include highland cells")
