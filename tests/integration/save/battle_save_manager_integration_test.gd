# tests/integration/save/battle_save_manager_integration_test.gd
# Product-level SaveManager round-trip for the formal battle scene.

extends Gut

const TEST_SLOT := 7
const CharacterRosterScript = preload("res://src/core/character/character_roster.gd")

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
	assert_eq(restored._roster.get_roster_size(), 6, "Roster should restore six tracked characters")
	assert_eq(restored._roster.get_status(&"R3"), CharacterRosterScript.Status.DEPARTED, "Departed roster member should persist")
	assert_true(restored._roster.get_character(&"R2").equipment_component.get_item(&"r2_dagger") != null, "Reserve equipment should restore")
	restored.queue_free()

func test_save_manager_writes_party_units_and_inventory_items_to_save_data() -> void:
	assert_true(SaveManager.save_game(TEST_SLOT), "Scene state should save through SaveManager")
	var saved: SaveData = load("user://saves/save_%d.tres" % TEST_SLOT) as SaveData
	assert_true(saved != null, "Save file should deserialize as SaveData")
	assert_eq(saved.party_units.size(), 6, "party_units should persist full roster")
	assert_true(saved.inventory_items.size() > 0, "inventory_items should persist inventory snapshot")
	assert_true(_find_party_entry(saved.party_units, &"P1").get("party_index", -1) == 0, "Party ordering should be encoded")
	assert_eq(_find_inventory_entry(saved.inventory_items, ResourceTypes.ResourceId.GOLD).get("amount", 0), 500)

func _first_enemy(battle) -> Unit:
	for unit in battle._unit_cells:
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			return unit
	return null

func _find_party_entry(entries: Array, unit_id: StringName) -> Dictionary:
	for entry in entries:
		var payload: Dictionary = entry.get("unit", {})
		if StringName(payload.get("unit_id", "")) == unit_id:
			return entry
	return {}

func _find_inventory_entry(entries: Array, resource_type: int) -> Dictionary:
	for entry in entries:
		if int(entry.get("resource_type", -1)) == resource_type:
			return entry
	return {}
