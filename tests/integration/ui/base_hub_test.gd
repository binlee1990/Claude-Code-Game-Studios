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
