class_name ItemRegistryHost
extends Node

static var instance: ItemRegistryHost

var service := ItemRegistry.new()


func _ready() -> void:
	if instance == null:
		instance = self
	service = ItemRegistry.new(_resolve_data_config())
	service._initialize()


## Returns the active ItemRegistryHost autoload instance.
static func get_instance() -> ItemRegistryHost:
	return instance


## Returns the ItemRegistry service.
func get_service() -> ItemRegistry:
	return service


func _resolve_data_config() -> Object:
	var host := DataConfigHost.get_instance()
	if host == null:
		return null
	return host.get_service()
