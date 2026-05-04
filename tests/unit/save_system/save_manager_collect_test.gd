extends GdUnitTestSuite

const SaveManagerScript := preload("res://src/systems/core/save_manager.gd")

var restored_payload := {}


func before_test() -> void:
	restored_payload = {}


func test_collect_save_data_contains_meta_and_systems() -> void:
	var manager := SaveManagerScript.new()
	manager.register_provider("time_manager", Callable(self, "_save_time"), Callable(self, "_restore_time"))
	var data := manager.collect_save_data()
	assert_bool(data.has("meta")).is_true()
	assert_bool(data.has("systems")).is_true()
	assert_bool(data["systems"].has("time_manager")).is_true()
	assert_bool(data["systems"]["time_manager"].has("exit_real_timestamp")).is_true()


func test_invalid_provider_data_becomes_null() -> void:
	var manager := SaveManagerScript.new()
	manager.register_provider("system_a", Callable(self, "_save_invalid"), Callable(self, "_restore_time"))
	manager.register_provider("system_b", Callable(self, "_save_time"), Callable(self, "_restore_time"))
	var data := manager.collect_save_data()
	assert_bool(data["systems"]["system_a"] == null).is_true()
	assert_bool(data["systems"]["system_b"] != null).is_true()


func test_missing_namespace_restore_receives_empty_dictionary() -> void:
	var manager := SaveManagerScript.new()
	manager.register_provider("new_system", Callable(self, "_save_time"), Callable(self, "_restore_time"))
	manager._restore_providers({"systems": {}})
	assert_int(restored_payload.size()).is_equal(0)


func _save_time() -> Dictionary:
	return {"exit_real_timestamp": 123.0, "game_ref": 10.0}


func _save_invalid():
	return null


func _restore_time(data: Dictionary) -> bool:
	restored_payload = data
	return true

