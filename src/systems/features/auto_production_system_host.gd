class_name AutoProductionSystemHost
extends Node

static var instance: AutoProductionSystemHost

var service := AutoProductionSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var output_host := OutputMultiplierSystemHost.get_instance()
	var resource_host := ResourceSystemHost.get_instance()
	service = AutoProductionSystem.new(TimeManager.get_instance(), output_host.get_service() if output_host != null else null, resource_host.get_service() if resource_host != null else null)


func _process(_delta: float) -> void:
	service.tick()


static func get_instance() -> AutoProductionSystemHost:
	return instance


func get_service() -> AutoProductionSystem:
	return service
