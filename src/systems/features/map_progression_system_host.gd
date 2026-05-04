class_name MapProgressionSystemHost
extends Node

static var instance: MapProgressionSystemHost

var service := MapProgressionSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var zone_host := ZoneSystemHost.get_instance()
	var level_host := LevelSystemHost.get_instance()
	service = MapProgressionSystem.new(zone_host.get_service() if zone_host != null else null, level_host.get_service() if level_host != null else null)


static func get_instance() -> MapProgressionSystemHost:
	return instance


func get_service() -> MapProgressionSystem:
	return service
