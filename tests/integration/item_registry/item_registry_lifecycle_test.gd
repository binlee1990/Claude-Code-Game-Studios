extends GdUnitTestSuite

const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")

class MockDataConfig:
	extends RefCounted

	var hot_reload_enabled := true
	var items := {}

	func get_all(table_name: String) -> Variant:
		if table_name != "items":
			return {}
		return items.duplicate(true)

	func reload_table(_table_name: String) -> void:
		pass

var _loaded_events := []
var _reloaded_events := []


func before_test() -> void:
	_loaded_events.clear()
	_reloaded_events.clear()
	EventBusScript.instance = EventBusScript.new()
	EventBusScript.instance.clear_all()
	EventBusScript.instance.subscribe("item_registry.loaded", _on_loaded)
	EventBusScript.instance.subscribe("item_registry.reloaded", _on_reloaded)


func after_test() -> void:
	if EventBusScript.instance != null:
		EventBusScript.instance.clear_all()
	EventBusScript.instance = null


func test_initialize_emits_loaded_payload() -> void:
	var registry := _registry_with({
		"herb": {"name": "药材", "item_class": "resource_material", "rarity": "fanpin", "tags": ["herb"]},
		"bad": {"name": "坏数据", "item_class": "unknown_cat", "rarity": "fanpin", "tags": []},
	})
	assert_int(registry.get_count()).is_equal(1)
	assert_int(_loaded_events.size()).is_equal(1)
	assert_int(int(_loaded_events[0]["count"])).is_equal(1)
	assert_int(int(_loaded_events[0]["item_classes"]["resource_material"])).is_equal(1)
	assert_bool(_loaded_events[0]["item_classes"].has("unknown_cat")).is_false()


func test_reload_refreshes_table_when_hot_reload_enabled() -> void:
	var data_config := MockDataConfig.new()
	data_config.items = {
		"old_item": {"name": "旧物", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
	}
	var registry: ItemRegistry = ItemRegistryScript.new(data_config)
	registry._initialize()
	data_config.items = {
		"x": {"name": "新物", "item_class": "consumable", "rarity": "fanpin", "tags": []},
	}
	registry.reload()
	assert_bool(registry.has_item("old_item")).is_false()
	assert_bool(registry.has_item("x")).is_true()
	assert_int(registry.query_by_item_class("resource_material").size()).is_equal(0)
	assert_int(registry.query_by_item_class("consumable").size()).is_equal(1)
	if OS.is_debug_build():
		assert_int(_reloaded_events.size()).is_equal(1)


func _registry_with(items: Dictionary) -> ItemRegistry:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("items", items)
	var registry := ItemRegistryScript.new(data_config)
	registry._initialize()
	return registry


func _on_loaded(payload: Dictionary) -> void:
	_loaded_events.append(payload)


func _on_reloaded(payload: Dictionary) -> void:
	_reloaded_events.append(payload)
