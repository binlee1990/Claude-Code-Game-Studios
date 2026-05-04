class_name UIManagerHost
extends Node

static var instance: UIManagerHost

var service := UIManager.new()


func _ready() -> void:
	if instance == null:
		instance = self
	service.register_screen("hud", "res://src/ui/hud/hud.tscn", true)


static func get_instance() -> UIManagerHost:
	return instance


func get_service() -> UIManager:
	return service
