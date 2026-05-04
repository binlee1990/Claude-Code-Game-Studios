extends GdUnitTestSuite

const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")


func test_query_and_peek_contracts() -> void:
	var registry := _registry_with(_items())
	assert_bool(registry.has_item("herb")).is_true()
	assert_bool(registry.has_item("nonexistent")).is_false()
	assert_bool(registry.get_item("nonexistent").is_empty()).is_true()
	assert_str(str(registry.peek_field("herb", "name"))).is_equal("药材")
	assert_bool(registry.peek_field("nonexistent", "name") == null).is_true()
	assert_bool(registry.peek_field("herb", "nonexistent_field") == null).is_true()


func test_query_by_item_class_and_tag() -> void:
	var registry := _registry_with(_items())
	assert_int(registry.query_by_item_class("resource_material").size()).is_equal(5)
	assert_int(registry.query_by_item_class("equipment").size()).is_equal(0)
	assert_int(registry.query_by_item_class("unknown_cat").size()).is_equal(0)
	var herbs := registry.query_by_tag("herb")
	assert_int(herbs.size()).is_equal(1)
	assert_str(str(herbs[0]["id"])).is_equal("herb")
	assert_int(registry.query_by_tag("nonexistent_tag").size()).is_equal(0)
	assert_int(registry.query_by_tag("").size()).is_equal(0)


func test_get_and_query_results_are_deep_copies() -> void:
	var registry := _registry_with(_items())
	var herb := registry.get_item("herb")
	herb["name"] = "fake"
	assert_str(str(registry.get_item("herb")["name"])).is_equal("药材")
	var query := registry.query_by_item_class("resource_material")
	for item in query:
		if str(item["id"]) == "herb":
			item["name"] = "fake"
	assert_str(str(registry.get_item("herb")["name"])).is_equal("药材")
	var name = registry.peek_field("herb", "name")
	name = "fake"
	assert_str(str(registry.peek_field("herb", "name"))).is_equal("药材")


func _registry_with(items: Dictionary) -> ItemRegistry:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("items", items)
	var registry := ItemRegistryScript.new(data_config)
	registry._initialize()
	return registry


func _items() -> Dictionary:
	return {
		"lingqi": {"name": "灵气", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"xiuwei": {"name": "修为", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"lingshi": {"name": "灵石", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"herb": {"name": "药材", "item_class": "resource_material", "rarity": "fanpin", "tags": ["herb", "low_tier"]},
		"exp": {"name": "经验", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
	}
