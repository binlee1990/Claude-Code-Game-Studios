class_name OutputMultiplierSystemHost
extends Node

static var instance: OutputMultiplierSystemHost

var service := OutputMultiplierSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	service = OutputMultiplierSystem.new(ModifierEngine.new(), _resolve_data_config())
	service.load_config()


static func get_instance() -> OutputMultiplierSystemHost:
	return instance


func get_service() -> OutputMultiplierSystem:
	return service


func _resolve_data_config() -> Object:
	var host := DataConfigHost.get_instance()
	if host == null:
		return null
	return host.get_service()
