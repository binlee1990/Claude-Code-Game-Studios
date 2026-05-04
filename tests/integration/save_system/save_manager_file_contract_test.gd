extends GdUnitTestSuite

const SaveManagerScript := preload("res://src/systems/core/save_manager.gd")


func test_save_manager_exposes_configurable_save_dir() -> void:
	var manager := SaveManagerScript.new()
	manager.save_dir = "user://test_save/"
	assert_str(manager.save_dir).is_equal("user://test_save/")


func test_idle_state_reports_not_saving_or_loading() -> void:
	var manager := SaveManagerScript.new()
	assert_bool(manager.is_saving()).is_false()
	assert_bool(manager.is_loading()).is_false()

