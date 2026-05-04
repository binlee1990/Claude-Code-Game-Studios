class_name CombatCalculatorHost
extends Node

static var instance: CombatCalculatorHost

var service := CombatCalculator.new()


func _ready() -> void:
	if instance == null:
		instance = self


static func get_instance() -> CombatCalculatorHost:
	return instance


func get_service() -> CombatCalculator:
	return service
