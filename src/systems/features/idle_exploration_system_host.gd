class_name IdleExplorationSystemHost
extends Node

static var instance: IdleExplorationSystemHost

var service := IdleExplorationSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var zone_host := ZoneSystemHost.get_instance()
	service = IdleExplorationSystem.new(zone_host.get_service() if zone_host != null else null)
	service.initialize()


static func get_instance() -> IdleExplorationSystemHost:
	return instance


func get_service() -> IdleExplorationSystem:
	return service
