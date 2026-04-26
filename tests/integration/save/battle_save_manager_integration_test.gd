# tests/integration/save/battle_save_manager_integration_test.gd
# Product-level SaveManager round-trip for the formal battle scene.

extends Gut

const TEST_SLOT := 7
const CharacterRosterScript = preload("res://src/core/character/character_roster.gd")

var _battle

func before_each() -> void:
	_remove_test_save()
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()
	_remove_test_save()

func _remove_test_save() -> void:
	var absolute_path: String = ProjectSettings.globalize_path("user://saves/save_%d.tres" % TEST_SLOT)
	if FileAccess.file_exists("user://saves/save_%d.tres" % TEST_SLOT):
		DirAccess.remove_absolute(absolute_path)
	var temp_absolute_path: String = ProjectSettings.globalize_path("user://saves/save_%d.tmp.tres" % TEST_SLOT)
	if FileAccess.file_exists("user://saves/save_%d.tmp.tres" % TEST_SLOT):
		DirAccess.remove_absolute(temp_absolute_path)

func test_save_manager_restores_formal_battle_runtime_state() -> void:
	var enemy: Unit = _first_enemy(_battle)
	_battle.rotate_camera(2)
	_battle.set_grid_overlay_enabled(false)
	_battle.set_active_menu_tab("settings")
	_battle._toggle_menu()
	_battle._cycle_speed_tier()
	_battle._toggle_auto_battle()
	_battle._combat.apply_damage(enemy, 25, _battle._combat.get_current_actor())
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
	assert_eq(restored._roster.get_character(&"P2").class_component.get_class_id(), ClassNames.ClassID.BASIC_ARCHER, "Roster classes should restore from the content definition")
	assert_ne(restored._roster.get_character(&"P2").skill_component.get_skill(&"precise_shot"), null, "Roster class skills should restore with the unit")
	assert_eq(restored.get_story_progress().get("current_battle", ""), "chapter_01_tutorial", "Story progress should restore with the battle")
	assert_eq(restored.get_boss_state().get("phase", 0), 2, "Boss checkpoint phase should restore with battle state")
	restored.queue_free()

func test_save_manager_restores_management_screen_state() -> void:
	_battle.open_management_screen("equipment")
	assert_true(SaveManager.save_game(TEST_SLOT), "Management screen state should save through SaveManager")

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT), "Saved management state should load")
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	assert_true(restored.get_management_screen_state().get("visible", false), "Management screen visibility should restore")
	assert_eq(restored.get_management_screen_state().get("tab", ""), "equipment", "Management screen tab should restore")
	assert_true(String(restored.get_management_screen_state().get("content", "")).contains("Equipment Management"), "Restored management screen should render content")
	restored.queue_free()

func test_save_manager_writes_party_units_and_inventory_items_to_save_data() -> void:
	assert_true(SaveManager.save_game(TEST_SLOT), "Scene state should save through SaveManager")
	var saved: SaveData = ResourceLoader.load(
		"user://saves/save_%d.tres" % TEST_SLOT,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	) as SaveData
	assert_true(saved != null, "Save file should deserialize as SaveData")
	assert_eq(saved.party_units.size(), 6, "party_units should persist full roster")
	assert_true(saved.inventory_items.size() > 0, "inventory_items should persist inventory snapshot")
	assert_eq(saved.story_progress.get("chapter", 0), 1, "story_progress should persist Chapter 1")
	assert_eq(saved.story_progress.get("current_battle", ""), "chapter_01_tutorial", "story_progress should persist current battle id")
	var difficulty_profile: Dictionary = saved.battle_state.get("difficulty_profile", {})
	assert_eq(int(round(float(difficulty_profile.get("enemy_stat_multiplier", 0.0)) * 10.0)), 7, "battle_state should persist the tutorial difficulty profile")
	assert_true(_find_party_entry(saved.party_units, &"P1").get("party_index", -1) == 0, "Party ordering should be encoded")
	assert_eq(_find_inventory_entry(saved.inventory_items, ResourceTypes.ResourceId.GOLD).get("amount", 0), 500)

func test_save_manager_restores_chapter_one_settlement_rewards() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	for unit in _battle._unit_cells.keys():
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			_battle._combat.apply_damage(unit, 999, actor)
	_battle._check_battle_end()
	assert_true(_battle._settlement_reward_summary.get("rewards_enabled", false), "Victory should generate settlement data before saving")
	assert_true(SaveManager.save_game(TEST_SLOT), "Post-battle settlement should save through SaveManager")

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT), "Saved post-battle slot should load")
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	assert_true(restored._settlement_reward_summary.get("rewards_enabled", false), "Settlement summary should restore")
	assert_true(int(restored._settlement_reward_summary.get("gold_awarded", 0)) > 0, "Saved settlement should keep gold reward")
	assert_true(Inventory.get_amount(ResourceTypes.ResourceId.GOLD) > 500, "Rewarded inventory should restore")
	assert_true(restored.get_story_progress().get("chapter_01_complete", false), "Victory story progress should restore")
	restored._toggle_menu()
	restored.set_active_menu_tab("settlement")
	assert_true(restored._menu_content_label.text.contains("Equipment"), "Restored settlement tab should show reward details")
	restored.queue_free()

func test_save_manager_restores_campaign_follow_up_state() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	for unit in _battle._unit_cells.keys():
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			_battle._combat.apply_damage(unit, 999, actor)
	_battle._check_battle_end()
	assert_true(_battle.advance_to_next_battle(), "Campaign should advance after tutorial victory")
	assert_true(SaveManager.save_game(TEST_SLOT), "Follow-up campaign battle should save through SaveManager")

	_battle.queue_free()
	_battle = null

	assert_true(SaveManager.load_game(TEST_SLOT), "Saved follow-up campaign slot should load")
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var restored = scene.instantiate()
	add_child(restored)

	assert_eq(restored.get_battle_id(), "chapter_01_crossroads", "SaveManager should restore the active follow-up battle definition")
	assert_eq(restored.get_story_progress().get("current_battle", ""), "chapter_01_crossroads", "Campaign story progress should restore")
	assert_true(restored.get_campaign_state().get("camp_report", "").contains("Defend"), "Camp report should restore")
	assert_ne(_find_unit_by_id(restored, "E4"), null, "Follow-up battle units should restore")
	assert_eq(int(restored._map_terrain.get(Vector2i(9, 8), -1)), TerrainTypes.Terrain.WATER_PUDDLE, "Follow-up tactical terrain should restore")
	restored.queue_free()

func _first_enemy(battle) -> Unit:
	for unit in battle._unit_cells:
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			return unit
	return null

func _find_unit_by_id(battle, unit_id: String) -> Unit:
	for unit in battle._unit_cells:
		if String(unit.unit_id) == unit_id:
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
