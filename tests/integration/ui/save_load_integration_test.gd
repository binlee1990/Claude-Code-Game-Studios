# tests/integration/ui/save_load_integration_test.gd
# UI preference persistence regression coverage.

extends Gut

const TEST_SLOT := 5

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

func test_ui_preferences_round_trip_via_save_manager() -> void:
	_battle._ui_preferences["master_volume"] = 65
	_battle._ui_preferences["screen_mode"] = "fullscreen"
	_battle.set_active_menu_tab("settings")
	_battle._toggle_menu()
	assert_true(SaveManager.save_game(TEST_SLOT))

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT))
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	assert_eq(restored._ui_preferences["master_volume"], 65)
	assert_eq(restored._ui_preferences["screen_mode"], "fullscreen")
	assert_eq(restored._active_menu_tab, "settings")
	assert_true(restored._menu_layer.visible)
	restored.queue_free()
