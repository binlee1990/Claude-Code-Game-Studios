class_name ZoneSystemHost
extends Node

static var instance: ZoneSystemHost

var service := ZoneSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var data_host := DataConfigHost.get_instance()
	var enemy_host := EnemyDatabaseHost.get_instance()
	service = ZoneSystem.new(data_host.get_service() if data_host != null else null, enemy_host.get_service() if enemy_host != null else null)
	service.load_all()


static func get_instance() -> ZoneSystemHost:
	return instance


func get_service() -> ZoneSystem:
	return service
