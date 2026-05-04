class_name ResourceSystemHost
extends Node

static var instance: ResourceSystemHost

var service := ResourceSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	_register_mvp_resources()


## Returns the active ResourceSystemHost autoload instance.
static func get_instance() -> ResourceSystemHost:
	return instance


## Returns the ResourceSystem service.
func get_service() -> ResourceSystem:
	return service


func _register_mvp_resources() -> void:
	var definitions := [
		{"id": "lingqi", "category": "regenerative", "has_cap": true, "reset_scope": "breakthrough", "cap": BigNumber.from_int(1000)},
		{"id": "xiuwei", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumber.MAX},
		{"id": "lingshi", "category": "currency", "has_cap": false, "reset_scope": "ascension", "cap": BigNumber.MAX},
		{"id": "herb", "category": "material", "has_cap": true, "reset_scope": "ascension", "cap": BigNumber.from_int(500)},
		{"id": "exp", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumber.MAX},
	]
	for definition in definitions:
		service.register(definition)

