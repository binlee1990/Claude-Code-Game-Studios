# tests/integration/camera/save_load_integration_test.gd
# Camera preference persistence regression coverage.

extends Gut

const TEST_SLOT := 6

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
	var relative_path := "user://saves/save_%d.tres" % TEST_SLOT
	if FileAccess.file_exists(relative_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(relative_path))

func test_camera_preferences_round_trip_via_save_manager() -> void:
	_battle.rotate_camera(2)
	_battle.set_grid_overlay_enabled(false)
	_battle.set_map_size(20)
	assert_true(SaveManager.save_game(TEST_SLOT))

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT))
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	assert_eq(restored.get_camera_rotation_degrees(), 0)
	assert_false(restored.is_grid_overlay_enabled())
	assert_eq(restored.get_map_size(), 20)
	restored.queue_free()
