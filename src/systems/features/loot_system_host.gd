class_name LootSystemHost
extends Node

static var instance: LootSystemHost

var service := LootSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var data_host := DataConfigHost.get_instance()
	var item_host := ItemRegistryHost.get_instance()
	service = LootSystem.new(data_host.get_service() if data_host != null else null, item_host.get_service() if item_host != null else null)


static func get_instance() -> LootSystemHost:
	return instance


func get_service() -> LootSystem:
	return service
