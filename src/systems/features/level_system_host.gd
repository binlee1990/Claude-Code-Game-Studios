class_name LevelSystemHost
extends Node

static var instance: LevelSystemHost

var service := LevelSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	service = LevelSystem.new(_resolve_resource_system(), _resolve_attribute_system(), _resolve_output_system())
	service.register_entity("player")


static func get_instance() -> LevelSystemHost:
	return instance


func get_service() -> LevelSystem:
	return service


func _resolve_resource_system() -> ResourceSystem:
	var host := ResourceSystemHost.get_instance()
	return host.get_service() if host != null else null


func _resolve_attribute_system() -> AttributeSystem:
	var host := AttributeSystemHost.get_instance()
	return host.get_service() if host != null else null


func _resolve_output_system() -> OutputMultiplierSystem:
	var host := OutputMultiplierSystemHost.get_instance()
	return host.get_service() if host != null else null
