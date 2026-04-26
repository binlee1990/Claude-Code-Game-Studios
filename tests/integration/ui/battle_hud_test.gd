# tests/integration/ui/battle_hud_test.gd
# Battle HUD and menu-system regression coverage.

extends Gut

const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")

var _battle

func before_each() -> void:
	SRPGLocalizationScript.set_locale(SRPGLocalizationScript.DEFAULT_LOCALE)
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	SRPGLocalizationScript.set_locale(SRPGLocalizationScript.DEFAULT_LOCALE)
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_battle_hud_builds_turn_order_actions_and_status() -> void:
	assert_true(_battle._turn_list.get_child_count() >= 4, "Turn order list should show the battle roster")
	assert_eq(_battle._action_bar.get_child_count(), 5, "Action bar should expose move, attack, skill, standby, and end turn")
	assert_true(_battle._status_name_label.text.begins_with("单位："), "Status panel should show the focused unit")

func test_health_change_reactively_updates_hp_bar() -> void:
	var enemy: Unit = _first_enemy()
	var hp_before: int = _battle._combat.get_unit_hp(enemy)
	var bar_before: float = (_battle._hp_bars[enemy] as ProgressBar).value
	_battle._combat.apply_damage(enemy, 10, _battle._combat.get_current_actor())
	assert_true(_battle._combat.get_unit_hp(enemy) < hp_before)
	assert_true((_battle._hp_bars[enemy] as ProgressBar).value < bar_before, "HP bar should update from the health_changed event")

func test_resource_hud_updates_from_inventory_events() -> void:
	var before_text: String = (_battle._resource_labels["gold"] as Label).text
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 25)
	var after_text: String = (_battle._resource_labels["gold"] as Label).text
	assert_ne(before_text, after_text)
	assert_true(after_text.contains("525"), "Gold HUD should reflect inventory updates")

func test_menu_tabs_and_visibility_toggle() -> void:
	_battle._toggle_menu()
	assert_true(_battle._menu_layer.visible, "Menu overlay should open")
	_battle.set_active_menu_tab("inventory")
	assert_true(_battle._menu_content_label.text.begins_with("背包"))
	_battle._toggle_menu()
	assert_false(_battle._menu_layer.visible, "Menu overlay should close")

func test_save_tab_exposes_story_and_difficulty() -> void:
	_battle._toggle_menu()
	_battle.set_active_menu_tab("save")
	assert_true(_battle._menu_content_label.text.contains("chapter_01_tutorial"), "Save tab should show story progress")
	assert_true(_battle._menu_content_label.text.contains("首次游玩教学"), "Save tab should show the active difficulty profile")

func test_campaign_camp_and_tactics_tabs_expose_production_systems() -> void:
	_battle._toggle_menu()
	_battle.set_active_menu_tab("campaign")
	assert_true(_battle._menu_content_label.text.contains("chapter_01_tutorial"), "Campaign tab should show the active battle")
	assert_true(_battle._menu_content_label.text.contains("chapter_01_crossroads"), "Campaign tab should show the configured next battle")
	assert_true(_battle._menu_content_label.text.contains("剧情"), "Campaign tab should show story state")
	_battle.set_active_menu_tab("camp")
	assert_true(_battle._menu_content_label.text.contains("默认计划"), "Camp tab should show the default recommended plan")
	_battle.set_active_menu_tab("tactics")
	assert_true(_battle._menu_content_label.text.contains("移动"), "Tactics tab should show tactical profiles")

func test_independent_management_screen_exposes_rewards_camp_party_and_equipment() -> void:
	_battle.open_management_screen("rewards")
	var state: Dictionary = _battle.get_management_screen_state()
	assert_true(state.get("visible", false), "Management screen should open independently from the menu overlay")
	assert_true(String(state.get("content", "")).contains("战果"), "Rewards management tab should show settlement context")

	_battle.set_active_management_tab("camp")
	assert_true(String(_battle.get_management_screen_state().get("content", "")).contains("推荐回营"), "Camp management tab should show the recommended plan")
	_battle.set_active_management_tab("party")
	assert_true(String(_battle.get_management_screen_state().get("content", "")).contains("队伍编成"), "Party management tab should show roster details")
	_battle.set_active_management_tab("equipment")
	assert_true(String(_battle.get_management_screen_state().get("content", "")).contains("装备管理"), "Equipment management tab should show gear details")
	_battle.close_management_screen()
	assert_false(_battle.get_management_screen_state().get("visible", true), "Management screen should close")

func test_localization_catalog_and_audio_cues_are_wired() -> void:
	assert_eq(SRPGLocalizationScript.translate("game.title", "zh_CN"), "江湖试锋")
	assert_eq(SRPGLocalizationScript.translate("management.camp", "en_US"), "Camp")
	assert_true(SRPGLocalizationScript.catalog_size("zh_CN") >= 8, "Localization catalog should contain production UI keys")

	_battle._toggle_menu()
	assert_true(_battle.get_audio_cue_history().has("menu"), "Opening the menu should play a UI cue")
	_battle.run_default_camp_plan()
	assert_true(_battle.get_audio_cue_history().has("camp"), "Running camp should play a camp cue")

func test_equipment_and_roster_tabs_expose_player_systems() -> void:
	_battle._toggle_menu()
	_battle.set_active_menu_tab("equipment")
	assert_true(_battle._menu_content_label.text.contains("青铜剑"), "Equipment tab should show equipped player gear")
	assert_true(_battle._menu_content_label.text.contains("斥候匕首"), "Equipment tab should show reserve gear")
	_battle.set_active_menu_tab("roster")
	assert_true(_battle._menu_content_label.text.contains("队伍："), "Roster tab should show party state")
	assert_true(_battle._menu_content_label.text.contains("退场："), "Roster tab should show departed state")

func test_chinese_locale_localizes_battle_hud_and_data_driven_names() -> void:
	assert_true(_battle._info_label.text.contains("我方回合"), "Turn prompt should use zh_CN copy")
	assert_true(_battle._objective_label.text.contains("首次游玩教学"), "Difficulty label should be localized")
	assert_true(_battle._objective_label.text.contains("击败两名袭击者"), "Objective text should be localized")
	assert_false(_battle._objective_label.text.contains("First Playthrough Tutorial"))
	assert_false(_battle._info_label.text.contains("Your turn"))

	_battle._toggle_menu()
	_battle.set_active_menu_tab("equipment")
	assert_true(_battle._menu_content_label.text.contains("青铜剑"), "Equipment names should be localized")
	assert_false(_battle._menu_content_label.text.contains("Bronze Sword"))

func test_boss_tab_exposes_phase_and_checkpoint_state() -> void:
	_battle._toggle_menu()
	_battle.set_active_menu_tab("boss")
	assert_true(_battle._menu_content_label.text.contains("袭击队长"), "Boss tab should show the active boss")
	assert_true(_battle._menu_content_label.text.contains("守备架势"), "Boss tab should show the active phase")
	assert_true(_battle._menu_content_label.text.contains("检查点"), "Boss tab should show checkpoint state")

func test_settlement_tab_exposes_empty_state_before_battle_end() -> void:
	_battle._toggle_menu()
	_battle.set_active_menu_tab("settlement")
	assert_true(
		_battle._menu_content_label.text.contains("暂无结算结果"),
		"Settlement tab should explain that rewards are generated after battle end"
	)

func test_skill_action_consumes_mp_and_damages_target() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var enemy: Unit = _first_enemy()
	var enemy_pos: Vector2i = _battle._unit_cells[enemy]
	_battle._move_unit_to_cell(actor, enemy_pos + Vector2i(-2, 0), false)
	var mp_before: int = _battle._actions.get_current_mp(actor)
	var hp_before: int = _battle._combat.get_unit_hp(enemy)

	_battle._selected_unit = actor
	_battle._targeting_skill_id = _battle._get_first_available_skill_id(actor)
	_battle._do_skill(enemy_pos)

	assert_true(_battle._actions.get_current_mp(actor) < mp_before, "Skill action should spend MP")
	assert_true(_battle._combat.get_unit_hp(enemy) < hp_before, "Skill action should damage the target")

func _first_enemy() -> Unit:
	for unit in _battle._unit_cells:
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			return unit
	return null
