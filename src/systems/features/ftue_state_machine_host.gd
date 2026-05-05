class_name FTUEStateMachineHost
extends Node

static var instance: FTUEStateMachineHost

var service: FTUEStateMachine


func _ready() -> void:
	if instance == null:
		instance = self
	var bus := _resolve_event_bus()
	service = FTUEStateMachine.new(bus)
	_register_save_provider()


func _register_save_provider() -> void:
	var sm := SaveManager.get_instance()
	if sm == null:
		return
	sm.register_provider("ftue_state_machine", service.collect_state, service.restore_state)


static func get_instance() -> FTUEStateMachineHost:
	return instance


func get_service() -> FTUEStateMachine:
	return service


func _resolve_event_bus() -> EventBus:
	return EventBus.get_instance()
