class_name ResourceSystemHost
extends Node

static var instance: ResourceSystemHost

var service := ResourceSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	_register_mvp_resources()


## Returns the active ResourceSystemHost autoload instance.
static func get_instance() -> ResourceSystemHost:
	return instance


## Returns the ResourceSystem service.
func get_service() -> ResourceSystem:
	return service


func _register_mvp_resources() -> void:
	var definitions := _load_resource_definitions_from_config()
	if definitions.is_empty():
		definitions = [
			{"id": "lingqi", "category": "regenerative", "has_cap": true, "reset_scope": "breakthrough", "cap": BigNumber.from_int(1000)},
			{"id": "xiuwei", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumber.MAX},
			{"id": "lingshi", "category": "currency", "has_cap": false, "reset_scope": "ascension", "cap": BigNumber.MAX},
			{"id": "herb", "category": "material", "has_cap": true, "reset_scope": "ascension", "cap": BigNumber.from_int(500)},
			{"id": "exp", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumber.MAX},
		]
	for definition in definitions:
		service.register(definition)


func _load_resource_definitions_from_config() -> Array:
	var data_host := DataConfigHost.get_instance()
	if data_host == null:
		return []
	var config := data_host.get_service()
	if config == null or not config.has_method("has_table") or not config.has_table("resource_config"):
		return []
	var table: Dictionary = config.get_all("resource_config")
	var definitions := []
	for id in table.keys():
		if typeof(table[id]) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = table[id].duplicate(true)
		definition["id"] = str(definition.get("id", id))
		definitions.append(definition)
	return definitions
