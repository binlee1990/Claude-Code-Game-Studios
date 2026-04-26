# tests/integration/ui/base_hub_test.gd
# Regression coverage for the Sprint 004 base hub entry scene.

extends Gut

const TEST_SLOT := 4

var _base

func before_each() -> void:
	_remove_test_save()
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)
	SaveManager.clear_pending_loaded_data()
	SaveManager._current_slot = TEST_SLOT
	Inventory.reset()
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 500)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 12)
	var scene: PackedScene = load("res://src/ui/base/base_hub.tscn")
	_base = scene.instantiate()
	add_child(_base)

func after_each() -> void:
	if is_instance_valid(_base):
		_base.queue_free()
	SaveManager.clear_pending_loaded_data()
	SaveManager._current_slot = -1
	_remove_test_save()

func _remove_test_save() -> void:
	var relative_path := "user://saves/save_%d.tres" % TEST_SLOT
	if FileAccess.file_exists(relative_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(relative_path))

func test_base_hub_builds_training_and_market_tabs() -> void:
	var tabs := _base.find_child("TabContainer", true, false) as TabContainer
	assert_ne(tabs, null, "Base hub should expose a TabContainer")
	assert_true(tabs.tabs_visible, "Godot 4.6 TabContainer uses tabs_visible")
	assert_eq(tabs.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "Tab area should expand when the viewport grows")
	assert_eq(tabs.get_child_count(), 3, "Base hub should expose training, market, and management tabs")
	assert_eq(tabs.get_tab_title(0), "训练场")
	assert_eq(tabs.get_tab_title(1), "市集")
	assert_eq(tabs.get_tab_title(2), "管理")

func test_base_hub_exposes_continue_campaign_for_cleared_battle_save() -> void:
	_write_cleared_tutorial_save()
	_recreate_base()

	var continue_button := _base.find_child("ContinueCampaignButton", true, false) as Button
	var status_label := _base.find_child("CampaignStatusLabel", true, false) as Label
	assert_ne(continue_button, null, "Base should expose a campaign continuation button")
	assert_false(continue_button.disabled, "Cleared battle save should allow continuing the campaign from base")
	assert_ne(status_label, null, "Base should explain the campaign resume state")
	assert_true(status_label.text.contains("下一战已就绪"), "Base should show the next battle is ready")

func test_base_save_preserves_cleared_battle_resume_state() -> void:
	_write_cleared_tutorial_save()
	_recreate_base()

	assert_true(SaveManager.save_game(TEST_SLOT), "Base saves should succeed after party edits")
	var saved := SaveManager.peek_save(TEST_SLOT)
	assert_ne(saved, null, "Saved base state should be readable")
	assert_eq(saved.battle_state.get("battle_id", ""), "chapter_01_tutorial", "Base save must preserve the cleared battle id")
	assert_true(saved.story_progress.get("tutorial_complete", false), "Base save must preserve victory story progress")
	var summary: Dictionary = saved.battle_state.get("settlement_reward_summary", {})
	assert_true(summary.get("rewards_enabled", false), "Base save must preserve settlement rewards for next-battle gating")
	assert_false(saved.ui_preferences.has("advance_after_base"), "Regular base edits should not force auto-advance")

func test_continue_campaign_uses_base_edited_party_for_next_battle() -> void:
	_write_cleared_tutorial_save()
	_recreate_base()

	assert_true(_base._roster.set_party([&"R1", &"P1", &"R2", &"R4"]), "Base party edit should be accepted before continuing")
	_base._advance_after_base_requested = true
	assert_true(SaveManager.save_game(TEST_SLOT), "Continue campaign should save edited base party")

	var saved := SaveManager.peek_save(TEST_SLOT)
	assert_eq(_party_ids_from_save(saved.party_units), [&"R1", &"P1", &"R2", &"R4"], "Save should contain edited base party order")
	if is_instance_valid(_base):
		_base.queue_free()
		_base = null

	assert_true(SaveManager.load_game(TEST_SLOT), "Edited base save should load for battle resume")
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var battle = scene.instantiate()
	add_child(battle)

	assert_eq(battle.get_battle_id(), "chapter_01_crossroads", "Base continue should advance to the next battle")
	var active_players := _active_player_ids(battle)
	assert_true(active_players.has("R1"), "Next battle should deploy the edited reserve unit")
	assert_true(active_players.has("P1"), "Next battle should preserve the selected veteran unit")
	assert_true(active_players.has("R2"), "Next battle should deploy extra edited party members near player spawn cells")
	assert_true(active_players.has("R4"), "Next battle should deploy the fourth edited party member")
	assert_false(active_players.has("P2"), "Unselected default unit should not be forced into the next battle")
	assert_eq(battle._roster.get_party()[0], &"R1", "Battle roster should keep edited party order")
	battle.queue_free()

func test_base_hub_uses_viewport_density_scale() -> void:
	assert_almost_eq(_base.call("_calculate_ui_scale_for_size", Vector2(1280, 720)), 1.0, 0.001)
	assert_almost_eq(_base.call("_calculate_ui_scale_for_size", Vector2(1920, 1080)), 1.15, 0.001)
	assert_almost_eq(_base.call("_calculate_ui_scale_for_size", Vector2(2560, 1440)), 1.3, 0.001)

func test_base_hub_resource_rows_update_by_name() -> void:
	var gold_row = _base.find_child("GoldRow", true, false)
	var material_row = _base.find_child("MaterialRow", true, false)
	assert_ne(gold_row, null, "Gold row should be findable by name")
	assert_ne(material_row, null, "Material row should be findable by name")
	assert_true((gold_row.get_child(1) as Label).text.contains("500"))
	assert_true((material_row.get_child(1) as Label).text.contains("12"))

func test_market_buy_updates_resources_and_inventory_panel() -> void:
	var inventory_list := _base.find_child("InventoryList", true, false) as VBoxContainer
	assert_ne(inventory_list, null, "Market should expose a visible inventory list")

	_base.call("_select_market_item", {
		"id": ResourceTypes.ResourceId.BASIC_MATERIAL,
		"name": "基础材料",
		"buy": 50,
		"sell": 25,
	})
	_base.call("_on_market_confirm")

	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.GOLD), 450)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 13)

	var gold_row = _base.find_child("GoldRow", true, false)
	var material_row = _base.find_child("MaterialRow", true, false)
	assert_true((gold_row.get_child(1) as Label).text.contains("450"))
	assert_true((material_row.get_child(1) as Label).text.contains("13"))

	var inventory_text := _collect_label_text(inventory_list)
	assert_true(inventory_text.contains("BASIC_MATERIAL"))
	assert_true(inventory_text.contains("13"))

func test_market_item_list_keeps_buy_and_sell_prices_visible() -> void:
	var item_button := _base.find_child("Item_%s" % ResourceTypes.ResourceId.BASIC_MATERIAL, true, false) as Button
	assert_ne(item_button, null)
	assert_true(item_button.text.contains("买50"))
	assert_true(item_button.text.contains("卖25"))

	_base.call("_set_trade_mode", false)

	assert_true(item_button.text.contains("买50"), "Sell mode should not make the item look like its price mutated")
	assert_true(item_button.text.contains("卖25"))

func test_training_ground_skill_row_uses_godot4_offsets() -> void:
	var training = _base.find_child("TrainingGround", true, false)
	assert_ne(training, null, "Training ground should be embedded in the base hub")
	training.call("_add_skill_row", {
		"name": "Regression Slash",
		"level": 3,
		"proficiency": 40,
		"max_proficiency": 100,
		"rank": SkillDefinitions.Rank.BASIC,
	})

	var fill := _find_first_color_rect(training)
	assert_ne(fill, null, "Skill proficiency fill should be created")
	assert_eq(fill.offset_top, 1.0)
	assert_eq(fill.offset_right, -2.0)
	assert_eq(fill.offset_bottom, -1.0)

func test_base_hub_training_tab_expands_with_viewport() -> void:
	var training := _base.find_child("TrainingGround", true, false) as Control
	assert_ne(training, null, "Training ground should be embedded in the base hub")
	assert_eq(training.anchor_right, 1.0)
	assert_eq(training.anchor_bottom, 1.0)

	var main_hbox := training.find_child("MainHBox", true, false) as HBoxContainer
	assert_ne(main_hbox, null, "Training ground should use a full-size layout root")
	assert_eq(main_hbox.anchor_right, 1.0)
	assert_eq(main_hbox.anchor_bottom, 1.0)
	assert_eq(main_hbox.offset_bottom, -38.0)

	var character_panel := training.find_child("CharacterPanel", true, false) as Panel
	assert_ne(character_panel, null, "Character list column should be present")
	assert_eq(character_panel.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_almost_eq(character_panel.size_flags_stretch_ratio, 0.25, 0.001)

	var detail_panel := training.find_child("SkillDetailPanel", true, false) as Panel
	assert_ne(detail_panel, null, "Skill detail panel should be present")
	assert_eq(detail_panel.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_almost_eq(detail_panel.size_flags_stretch_ratio, 0.75, 0.001)

	var hint := training.find_child("HintBar", true, false) as Panel
	assert_ne(hint, null, "Training hint bar should be present")
	assert_eq(hint.anchor_top, 1.0)
	assert_eq(hint.anchor_bottom, 1.0)
	assert_eq(hint.offset_top, -30.0)

func test_training_ground_scales_dense_viewports() -> void:
	var training := TrainingGround.new()
	training.set_ui_scale(1.3)
	add_child(training)

	var character_panel := training.find_child("CharacterPanel", true, false) as Panel
	var hint := training.find_child("HintBar", true, false) as Panel
	assert_ne(character_panel, null)
	assert_ne(hint, null)
	assert_true(character_panel.custom_minimum_size.x >= 494.0, "Large viewport roster column should grow")
	assert_eq(hint.offset_top, -39.0)
	training.queue_free()

func test_training_ground_trains_roster_skill() -> void:
	var roster := CharacterRoster.new()
	add_child(roster)
	var unit := Unit.new()
	unit.unit_id = &"trainee"
	unit.display_name = "Trainee"
	roster.add_character(unit, CharacterRoster.Status.DEPLOYED)
	assert_true(unit.learn_skill(&"defend"))

	var training := TrainingGround.new()
	training.initialize(roster)
	add_child(training)
	training.call("_on_character_selected", 0)

	assert_ne(training._detail_class_label.text, "Unknown", "Roster-backed training should read ClassComponent directly")
	var skill := unit.get_skill(&"defend")
	var before := skill.proficiency
	var train_button := training.find_child("TrainButton_defend", true, false) as Button
	assert_ne(train_button, null, "Skill row should expose a training action")
	assert_false(train_button.disabled)

	train_button.pressed.emit()

	assert_eq(skill.proficiency, before + 10)
	training.queue_free()
	roster.queue_free()

func _find_first_color_rect(node: Node) -> ColorRect:
	if node is ColorRect:
		return node as ColorRect
	for child in node.get_children():
		var found := _find_first_color_rect(child)
		if found != null:
			return found
	return null

func _collect_label_text(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + "\n"
	for child in node.get_children():
		out += _collect_label_text(child)
	return out

func _recreate_base() -> void:
	if is_instance_valid(_base):
		_base.queue_free()
	var scene: PackedScene = load("res://src/ui/base/base_hub.tscn")
	_base = scene.instantiate()
	add_child(_base)

func _write_cleared_tutorial_save() -> void:
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	var battle = scene.instantiate()
	add_child(battle)
	var actor: Unit = battle._combat.get_current_actor()
	for unit in battle._unit_cells.keys():
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			battle._combat.apply_damage(unit, 999, actor)
	battle._check_battle_end()
	var runtime: Dictionary = battle.capture_runtime_state()
	var save_data := SaveData.new()
	save_data.timestamp = Time.get_unix_time_from_system()
	save_data.locale = SRPGLocalization.get_locale()
	save_data.current_scene_key = battle.get_scene_key()
	save_data.party_units = runtime.get("party_units", [])
	save_data.inventory_items = runtime.get("inventory_items", [])
	save_data.settings = runtime.get("settings", {})
	save_data.battle_state = runtime.get("battle_state", {})
	save_data.camera_preferences = runtime.get("camera_preferences", {})
	save_data.ui_preferences = runtime.get("ui_preferences", {})
	save_data.inventory_state = runtime.get("inventory_state", {})
	save_data.battle_history = runtime.get("battle_history", {})
	save_data.story_progress = runtime.get("story_progress", {})
	assert_eq(ResourceSaver.save(save_data, "user://saves/save_%d.tres" % TEST_SLOT), OK)
	battle.queue_free()

func _party_ids_from_save(entries: Array) -> Array[StringName]:
	var rows: Array[Dictionary] = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var party_index := int(entry.get("party_index", -1))
		if party_index < 0:
			continue
		var payload: Dictionary = entry.get("unit", {})
		rows.append({"index": party_index, "unit_id": StringName(payload.get("unit_id", ""))})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["index"]) < int(b["index"])
	)
	var ids: Array[StringName] = []
	for row in rows:
		ids.append(StringName(row["unit_id"]))
	return ids

func _active_player_ids(battle) -> Array[String]:
	var ids: Array[String] = []
	for unit in battle._unit_cells.keys():
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
			ids.append(String(unit.unit_id))
	ids.sort()
	return ids
