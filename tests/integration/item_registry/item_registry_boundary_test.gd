extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")


func test_item_registry_and_resource_system_share_ids_without_coupling() -> void:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("items", {
		"a": {"name": "A", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
		"b": {"name": "B", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
	})
	var registry := ItemRegistryScript.new(data_config)
	registry._initialize()
	var resources := ResourceSystemScript.new()
	resources.register({"id": "b", "category": "material", "has_cap": false})
	resources.register({"id": "c", "category": "material", "has_cap": false})
	assert_bool(registry.has_item("c")).is_false()
	assert_bool(resources.has_resource("a")).is_false()
	assert_bool(registry.get_item("c").is_empty()).is_true()
	assert_bool(resources.get_value("a").equals(BigNumberScript.ZERO)).is_true()


func test_item_registry_internal_consistency_across_classes() -> void:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("items", {
		"a": {"name": "A", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
		"b": {"name": "B", "item_class": "equipment", "rarity": "jingliang", "tags": []},
		"c": {"name": "C", "item_class": "consumable", "rarity": "fanpin", "tags": []},
	})
	var registry := ItemRegistryScript.new(data_config)
	registry._initialize()
	var union := {}
	for item_class in ItemRegistryScript.ITEM_CLASSES:
		for item in registry.query_by_item_class(item_class):
			union[item["id"]] = true
	assert_int(registry.get_all_ids().size()).is_equal(registry.get_count())
	assert_int(union.size()).is_equal(registry.get_count())
