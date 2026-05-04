extends GdUnitTestSuite

const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")


func test_loads_five_mvp_material_items() -> void:
	var registry := _registry_with(_mvp_items())
	assert_int(registry.get_count()).is_equal(5)
	assert_array(registry.get_all_ids()).contains(["lingqi", "xiuwei", "lingshi", "herb", "exp"])
	var herb := registry.get_item("herb")
	assert_str(str(herb["name"])).is_equal("药材")
	assert_str(str(herb["item_class"])).is_equal("resource_material")
	assert_str(str(herb["rarity"])).is_equal("fanpin")
	assert_array(herb["tags"]).contains(["herb"])


func test_defaults_optional_fields() -> void:
	var registry := _registry_with({
		"herb": {"name": "药材", "item_class": "resource_material", "rarity": "fanpin", "tags": ["herb"]},
	})
	var herb := registry.get_item("herb")
	assert_str(str(herb["description"])).is_equal("")
	assert_int(int(herb["stack_limit"])).is_equal(-1)
	assert_bool(bool(herb["stackable"])).is_true()


func test_rejects_invalid_class_and_empty_name_but_defaults_bad_rarity() -> void:
	var registry := _registry_with({
		"bad_class": {"name": "bad", "item_class": "unknown_cat", "rarity": "fanpin", "tags": []},
		"empty_name": {"name": "", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
		"bad_rarity": {"name": "bad rarity", "item_class": "resource_material", "rarity": "unknown_rarity", "tags": []},
	})
	assert_bool(registry.has_item("bad_class")).is_false()
	assert_bool(registry.has_item("empty_name")).is_false()
	assert_bool(registry.has_item("bad_rarity")).is_true()
	assert_str(str(registry.peek_field("bad_rarity", "rarity"))).is_equal("fanpin")


func test_missing_or_null_table_degrades_to_empty_registry() -> void:
	var missing := ItemRegistryScript.new()
	missing.set_data_config(null)
	missing._initialize()
	assert_bool(missing.is_loaded()).is_true()
	assert_int(missing.get_count()).is_equal(0)
	assert_bool(missing.has_item("herb")).is_false()


func _registry_with(items: Dictionary) -> ItemRegistry:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("items", items)
	var registry := ItemRegistryScript.new(data_config)
	registry._initialize()
	return registry


func _mvp_items() -> Dictionary:
	return {
		"lingqi": {"name": "灵气", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"xiuwei": {"name": "修为", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"lingshi": {"name": "灵石", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
		"herb": {"name": "药材", "item_class": "resource_material", "rarity": "fanpin", "tags": ["herb", "low_tier"]},
		"exp": {"name": "经验", "item_class": "resource_material", "rarity": "fanpin", "tags": ["resource"]},
	}
