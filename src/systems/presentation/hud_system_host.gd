class_name HUDSystemHost
extends Node

static var instance: HUDSystemHost

var service := HUDSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var resource_host := ResourceSystemHost.get_instance()
	var storage_host := StorageLimitSystemHost.get_instance()
	var level_host := LevelSystemHost.get_instance()
	var ui_host := UIManagerHost.get_instance()
	service = HUDSystem.new(resource_host.get_service() if resource_host != null else null, storage_host.get_service() if storage_host != null else null, level_host.get_service() if level_host != null else null, ui_host.get_service() if ui_host != null else null)


static func get_instance() -> HUDSystemHost:
	return instance


func get_service() -> HUDSystem:
	return service
