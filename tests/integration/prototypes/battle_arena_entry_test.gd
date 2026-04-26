# tests/integration/prototypes/battle_arena_entry_test.gd
# Regression coverage for the formal battle entry scene.

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

func test_formal_battle_scene_uses_playable_vertical_slice_controller() -> void:
	assert_ne(_battle, null, "Formal battle scene should instantiate")
	assert_eq(_battle._phase, _battle.VSPhase.SELECT_UNIT, "Formal battle scene should start on a player turn")
	var actor: Unit = _battle._combat.get_current_actor()
	assert_ne(actor, null, "Formal battle scene should create a current actor")
	assert_eq(_battle._combat.get_unit_team(actor), CombatSystem.Team.PLAYER, "Formal battle entry should be immediately controllable")
	assert_true(_battle._info_label.text.begins_with("Your turn:"), "Formal battle scene should expose the same playable prompt as the prototype")
	assert_eq(_battle.get_battle_id(), "chapter_01_tutorial", "Formal battle scene should now load the first content slice")
	assert_true(_battle.get_objective_text().contains("Defeat both raiders"), "Formal battle scene should expose a Chapter 1 objective")

func test_chapter_one_applies_tutorial_difficulty_profile() -> void:
	var profile: Dictionary = _battle.get_difficulty_profile()
	assert_eq(int(round(float(profile.get("enemy_stat_multiplier", 0.0)) * 10.0)), 7, "Chapter 1 should use the 0.7x tutorial curve")

	var dark_knight: Unit = _find_unit("E1")
	assert_ne(dark_knight, null, "Tutorial enemy should exist")
	assert_eq(_battle._combat._combat_units[dark_knight]["max_hp"], 49, "Enemy HP should be scaled by the difficulty profile")
	assert_eq(dark_knight.get_attribute(AttributeNames.Attribute.STR), 14, "Enemy attributes should be scaled by the difficulty profile")
	assert_true(_battle._objective_label.text.contains("First Playthrough Tutorial"), "Objective HUD should expose the active difficulty curve")

func test_formal_battle_uses_tactical_profiles_and_terrain() -> void:
	var swordsman: Unit = _find_unit("P1")
	var boss: Unit = _find_unit("E1")

	assert_eq(
		int(_battle._get_tactical_profile(swordsman).get("weapon_type", -1)),
		TacticalFormulas.WeaponType.SWORD,
		"Player tactics should load weapon type from the battle definition"
	)
	assert_eq(
		int(_battle._map_terrain.get(Vector2i(8, 8), -1)),
		TerrainTypes.Terrain.WATER_PUDDLE,
		"Battle definition terrain overrides should load into the formal map"
	)
	assert_true(
		_battle._get_tactical_damage_multiplier(swordsman, boss) >= 1.5,
		"Sword vs spear should apply the weapon triangle in formal battle damage"
	)

func test_chapter_one_units_use_definition_classes_and_class_skills() -> void:
	var swordsman: Unit = _find_unit("P1")
	var archer: Unit = _find_unit("P2")

	assert_eq(swordsman.class_component.get_class_id(), ClassNames.ClassID.BASIC_WARRIOR, "Swordsman should use the warrior class from the battle definition")
	assert_ne(swordsman.skill_component.get_skill(&"heavy_strike"), null, "Warrior should receive the warrior class skill")
	assert_eq(archer.class_component.get_class_id(), ClassNames.ClassID.BASIC_ARCHER, "Archer should use the archer class from the battle definition")
	assert_ne(archer.skill_component.get_skill(&"precise_shot"), null, "Archer should receive the archer class skill")
	assert_eq(archer.skill_component.get_skill(&"heavy_strike"), null, "Archer should not keep the default warrior skill")

func test_tutorial_boss_phase_checkpoint_updates_below_half_hp() -> void:
	var boss: Unit = _find_unit("E1")
	var actor: Unit = _battle._combat.get_current_actor()
	_battle._combat.apply_damage(boss, 25, actor)

	var boss_state: Dictionary = _battle.get_boss_state()
	assert_eq(boss_state.get("boss_id", ""), "E1", "Tutorial boss should expose a runtime boss id")
	assert_eq(boss_state.get("phase", 0), 2, "Boss should switch phase below the configured 50% threshold")
	assert_eq(boss_state.get("checkpoint_phase", 0), 2, "Boss phase switch should store a checkpoint phase")
	assert_true(_battle._boss_label.text.contains("Broken Guard"), "Boss HUD should show the active phase")
	assert_eq(_battle.get_story_progress().get("boss_phase", 0), 2, "Story progress should record the boss phase checkpoint")

func test_chapter_one_victory_updates_story_progress() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var enemies: Array = []
	for unit in _battle._unit_cells.keys():
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			enemies.append(unit)

	for enemy in enemies:
		_battle._combat.apply_damage(enemy, 999, actor)
	_battle._check_battle_end()

	var progress: Dictionary = _battle.get_story_progress()
	assert_true(progress.get("chapter_01_complete", false), "Victory should mark Chapter 1 complete")
	assert_true(progress.get("tutorial_complete", false), "Victory should mark tutorial battle complete")

	var summary: Dictionary = _battle._settlement_reward_summary
	assert_true(summary.get("rewards_enabled", false), "Victory should generate settlement rewards")
	assert_true(int(summary.get("exp_per_unit", 0)) > 0, "Victory should award survivor EXP")
	assert_true(int(summary.get("gold_awarded", 0)) > 0, "Victory should award gold")
	assert_true(int(summary.get("materials_awarded", 0)) > 0, "Victory should award materials")
	assert_true(int(summary.get("equipment_count", 0)) >= 1, "Boss victory should drop equipment")
	assert_true(Inventory.get_amount(ResourceTypes.ResourceId.GOLD) > 500, "Victory rewards should apply to inventory")
	assert_true(actor.class_component.get_current_class_exp() > 0, "Victory EXP should apply to surviving player class progress")

	_battle._toggle_menu()
	_battle.set_active_menu_tab("settlement")
	assert_true(_battle._menu_content_label.text.contains("Gold"), "Settlement tab should show reward details")
	assert_true(_battle._menu_content_label.text.contains("Equipment"), "Settlement tab should show equipment details")

func test_chapter_two_entry_loads_act_a_without_inventory_shadowing() -> void:
	if is_instance_valid(_battle):
		_battle.free()
	var sd := SaveData.new()
	sd.battle_state = {
		"battle_definition_path": "res://src/ui/combat/battle_definitions/chapter_02_act_a.json",
	}
	sd.story_progress = {
		"chapter": 2,
		"current_battle": "chapter_02_act_a",
		"chapter_02_started": true,
	}
	SaveManager._pending_loaded_data = sd
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

	assert_eq(_battle.get_battle_id(), "chapter_02_act_a")
	assert_eq(_battle.get_story_progress().get("chapter", 0), 2)
	assert_true(Inventory.get_amount(ResourceTypes.ResourceId.GOLD) >= 0, "Chapter 2 entry should use Inventory autoload without a local shadow")

func test_campaign_advance_loads_follow_up_battle_and_camp_path() -> void:
	_defeat_current_enemies()

	assert_true(_battle.advance_to_next_battle(), "Cleared tutorial battle should advance to the follow-up encounter")
	assert_eq(_battle.get_battle_id(), "chapter_01_crossroads", "Campaign advance should load the second Chapter 1 battle")
	assert_eq(_battle.get_story_progress().get("current_battle", ""), "chapter_01_crossroads", "Story progress should switch to the follow-up battle")
	assert_true(_battle.get_campaign_state().get("camp_report", "").contains("learned Defend"), "Default camp plan should train baseline skills")
	assert_ne(_find_unit("E4"), null, "Follow-up battle should load the second encounter boss")
	assert_eq(
		int(_battle._map_terrain.get(Vector2i(9, 8), -1)),
		TerrainTypes.Terrain.WATER_PUDDLE,
		"Follow-up battle should load its tactical terrain"
	)

func test_chapter_one_three_battle_campaign_reaches_finale_and_completion() -> void:
	_defeat_current_enemies()
	assert_true(_battle.advance_to_next_battle(), "Tutorial should advance to Crossroads")

	_defeat_current_enemies()
	assert_true(_battle.advance_to_next_battle(), "Crossroads should advance to the finale")

	assert_eq(_battle.get_battle_id(), "chapter_01_finale", "Campaign should load the third Chapter 1 battle")
	assert_true(_battle.get_briefing_text().contains("watchtower"), "Finale should expose narrative pacing text")
	assert_ne(_find_unit("R2"), null, "Finale should deploy the reserve Rogue as a pacing escalation")
	assert_ne(_find_unit("E6"), null, "Finale should load the gate commander boss")
	assert_eq(int(_battle._map_terrain.get(Vector2i(10, 7), -1)), TerrainTypes.Terrain.WATER_PUDDLE, "Finale should include tactical terrain")

	_defeat_current_enemies()
	var progress: Dictionary = _battle.get_story_progress()
	assert_true(progress.get("chapter_01_finale_complete", false), "Finale victory should mark the finale complete")
	assert_true(progress.get("chapter_01_complete", false), "Finale victory should mark Chapter 1 complete")
	assert_eq(_battle.get_campaign_state().get("next_battle_definition_path", ""), "", "Chapter 1 finale should currently be the end of the slice")

func _find_unit(unit_id: String) -> Unit:
	for unit in _battle._unit_cells.keys():
		if String(unit.unit_id) == unit_id:
			return unit
	return null

func _defeat_current_enemies() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var enemies: Array = []
	for unit in _battle._unit_cells.keys():
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			enemies.append(unit)
	for enemy in enemies:
		_battle._combat.apply_damage(enemy, 999, actor)
	_battle._check_battle_end()
