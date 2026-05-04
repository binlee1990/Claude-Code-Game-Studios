class_name DataConfigHost
extends Node

static var instance: DataConfigHost

var service: DataConfig


func _ready() -> void:
	if instance == null:
		instance = self
	service = DataConfig.new()
	service.load_all()


## Returns the active DataConfigHost autoload instance.
static func get_instance() -> DataConfigHost:
	return instance


## Returns the DataConfig service held by this host.
func get_service() -> DataConfig:
	return service

