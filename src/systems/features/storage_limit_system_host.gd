class_name StorageLimitSystemHost
extends Node

static var instance: StorageLimitSystemHost

var service := StorageLimitSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var resource_host := ResourceSystemHost.get_instance()
	service = StorageLimitSystem.new(resource_host.get_service() if resource_host != null else null)
	service.initialize()


static func get_instance() -> StorageLimitSystemHost:
	return instance


func get_service() -> StorageLimitSystem:
	return service
