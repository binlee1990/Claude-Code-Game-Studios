class_name CultivationSystemHost
extends Node

static var instance: CultivationSystemHost

var service := CultivationSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var resource_host := ResourceSystemHost.get_instance()
	service = CultivationSystem.new(resource_host.get_service() if resource_host != null else null, TimeManager.get_instance())


static func get_instance() -> CultivationSystemHost:
	return instance


func get_service() -> CultivationSystem:
	return service
