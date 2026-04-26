# tests/integration/ui/base_hub_test.gd
# Regression coverage for the Sprint 004 base hub entry scene.

extends Gut

const TEST_SLOT := 4

var _base

func before_each() -> void:
	_remove_test_save()
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
	var item_button := _base.find_child("Item_基础材料", true, false) as Button
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
