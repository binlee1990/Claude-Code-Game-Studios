extends GdUnitTestSuite

const DataConfigScript := preload("res://src/systems/core/data_config.gd")


func test_get_returns_record() -> void:
	var config := DataConfigScript.new()
	config.load_table_data("enemies", {"slime": {"name": "史莱姆", "hp": "100"}})
	var record = config.get_record("enemies", "slime")
	assert_str(record["name"]).is_equal("史莱姆")
	assert_str(record["hp"]).is_equal("100")


func test_get_all_returns_three_keys() -> void:
	var config := DataConfigScript.new()
	config.load_table_data("enemies", {"a": {}, "b": {}, "c": {}})
	assert_int(config.get_all("enemies").size()).is_equal(3)


func test_missing_table_returns_empty_dictionary() -> void:
	var config := DataConfigScript.new()
	assert_int(config.get_all("missing").size()).is_equal(0)


func test_reload_table_noops_when_hot_reload_disabled() -> void:
	var config := DataConfigScript.new()
	config.load_table_data("enemies", {"slime": {"hp": "100"}})
	config.reload_table("enemies")
	assert_str(config.get_field("enemies", "slime", "hp")).is_equal("100")


func test_array_field_preserves_type() -> void:
	var config := DataConfigScript.new()
	config.load_table_data("enemies", {"slime": {"tags": ["beast", "slime"]}})
	assert_array(config.get_field("enemies", "slime", "tags")).is_equal(["beast", "slime"])
