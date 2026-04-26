# tests/integration/ui/base_hub_test.gd
# Regression coverage for the Sprint 004 base hub entry scene.

extends Gut

var _base

func before_each() -> void:
	Inventory.reset()
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 500)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 12)
	var scene: PackedScene = load("res://src/ui/base/base_hub.tscn")
	_base = scene.instantiate()
	add_child(_base)

func after_each() -> void:
	if is_instance_valid(_base):
		_base.queue_free()

func test_base_hub_builds_training_and_market_tabs() -> void:
	var tabs := _base.find_child("TabContainer", true, false) as TabContainer
	assert_ne(tabs, null, "Base hub should expose a TabContainer")
	assert_true(tabs.tabs_visible, "Godot 4.6 TabContainer uses tabs_visible")
	assert_eq(tabs.get_child_count(), 2, "Base hub should expose training and market tabs")
	assert_eq(tabs.get_tab_title(0), "训练场")
	assert_eq(tabs.get_tab_title(1), "市集")

func test_base_hub_resource_rows_update_by_name() -> void:
	var gold_row = _base.find_child("GoldRow", true, false)
	var material_row = _base.find_child("MaterialRow", true, false)
	assert_ne(gold_row, null, "Gold row should be findable by name")
	assert_ne(material_row, null, "Material row should be findable by name")
	assert_true((gold_row.get_child(1) as Label).text.contains("500"))
	assert_true((material_row.get_child(1) as Label).text.contains("12"))

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

func _find_first_color_rect(node: Node) -> ColorRect:
	if node is ColorRect:
		return node as ColorRect
	for child in node.get_children():
		var found := _find_first_color_rect(child)
		if found != null:
			return found
	return null
