extends GdUnitTestSuite

const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")


func test_mvp_query_matrix_contract() -> void:
	var registry: ItemRegistry = _registry_with(_items())
	for _i in range(100):
		registry.get_item("herb")
		registry.peek_field("herb", "name")
		registry.query_by_item_class("resource_material")
		registry.query_by_tag("herb")
	assert_int(registry.get_count()).is_equal(5)


func test_alpha_scale_query_contract() -> void:
	var items := {}
	for i in range(500):
		var item_class := "resource_material" if i < 50 else "consumable"
		items["item_%03d" % i] = {
			"name": "item_%03d" % i,
			"item_class": item_class,
			"rarity": "fanpin",
			"tags": ["low_tier"] if i < 50 else ["other"],
		}
	var registry: ItemRegistry = _registry_with(items)
	assert_int(registry.get_count()).is_equal(500)
	assert_int(registry.query_by_item_class("resource_material").size()).is_equal(50)
	assert_int(registry.query_by_tag("low_tier").size()).is_equal(50)


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
