class_name EnemyDatabaseHost
extends Node

static var instance: EnemyDatabaseHost

var service := EnemyDatabase.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var data_host := DataConfigHost.get_instance()
	service = EnemyDatabase.new(data_host.get_service() if data_host != null else null)
	service.load_all()


static func get_instance() -> EnemyDatabaseHost:
	return instance


func get_service() -> EnemyDatabase:
	return service
