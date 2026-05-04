class_name AttributeSystemHost
extends Node

static var instance: AttributeSystemHost

var service := AttributeSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	service.register_entity("player", {
		"category": "player",
		"attribute_set": "player_set",
		"attributes": {
			"hp_max": BigNumber.from_int(100),
			"atk": BigNumber.from_int(100),
			"def": BigNumber.from_int(20),
			"spd": BigNumber.from_int(10),
			"crit_rate": BigNumber.from_float(1.0),
			"crit_dmg": BigNumber.from_float(2.0),
		},
	})


## Returns the active AttributeSystemHost autoload instance.
static func get_instance() -> AttributeSystemHost:
	return instance


## Returns the AttributeSystem service.
func get_service() -> AttributeSystem:
	return service

