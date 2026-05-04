class_name OfflineSimulationCoreHost
extends Node

static var instance: OfflineSimulationCoreHost

var service := OfflineSimulationCore.new()


func _ready() -> void:
	if instance == null:
		instance = self


static func get_instance() -> OfflineSimulationCoreHost:
	return instance


func get_service() -> OfflineSimulationCore:
	return service
