# tests/integration/save/battle_save_manager_integration_test.gd
# Product-level SaveManager round-trip for the formal battle scene.

extends Gut

const TEST_SLOT := 7

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
	var absolute_path: String = ProjectSettings.globalize_path("user://saves/save_%d.tres" % TEST_SLOT)
	if FileAccess.file_exists("user://saves/save_%d.tres" % TEST_SLOT):
		DirAccess.remove_absolute(absolute_path)

func test_save_manager_restores_formal_battle_runtime_state() -> void:
	var enemy: Unit = _first_enemy(_battle)
	_battle.rotate_camera(2)
	_battle.set_grid_overlay_enabled(false)
	_battle.set_active_menu_tab("settings")
	_battle._toggle_menu()
	_battle._cycle_speed_tier()
	_battle._toggle_auto_battle()
	_battle._combat.apply_damage(enemy, 12, _battle._combat.get_current_actor())
	assert_true(SaveManager.save_game(TEST_SLOT), "Scene state should save through SaveManager")

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT), "Saved slot should load")
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	var restored_enemy: Unit = _first_enemy(restored)
	assert_eq(restored.get_camera_rotation_degrees(), 0)
	assert_false(restored.is_grid_overlay_enabled())
	assert_eq(restored._active_menu_tab, "settings")
	assert_true(restored._menu_layer.visible, "UI menu visibility should restore")
	assert_eq(restored._speed_controller.get_tier(), SpeedController.SpeedTier.FAST)
	assert_true(restored._auto_battle_controller.is_enabled())
	assert_eq(restored._combat.get_unit_hp(restored_enemy), restored._combat._combat_units[restored_enemy]["hp"])
	assert_true(restored._combat.get_unit_hp(restored_enemy) < 70, "Enemy HP should restore from saved combat state")
	restored.queue_free()

func _first_enemy(battle) -> Unit:
	for unit in battle._unit_cells:
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			return unit
	return null
