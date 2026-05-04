class_name CultivationSystem
extends RefCounted

const STANCE_MEDITATE := "meditate"
const STANCE_CONDENSE := "condense"

var resource_system: ResourceSystem
var time_manager: TimeManager
var manual_lingqi_gain := BigNumber.from_int(1)
var condense_cost := BigNumber.from_int(1)
var condense_gain := BigNumber.from_int(1)
var stance := STANCE_MEDITATE
var last_shortage := false


func _init(resources: ResourceSystem = null, time: TimeManager = null) -> void:
	resource_system = resources
	time_manager = time


func manual_cultivate() -> bool:
	if _is_frozen() or resource_system == null:
		return false
	resource_system.add("lingqi", manual_lingqi_gain)
	return true


func set_stance(next_stance: String) -> bool:
	if next_stance == stance:
		return true
	stance = next_stance
	_emit("cultivation.stance_changed", {"stance": stance})
	return true


func tick_condense() -> bool:
	if _is_frozen() or resource_system == null or stance != STANCE_CONDENSE:
		return false
	if not resource_system.spend("lingqi", condense_cost):
		last_shortage = true
		return false
	last_shortage = false
	resource_system.add("xiuwei", condense_gain)
	return true


func get_hud_state() -> Dictionary:
	return {"stance": stance, "shortage": last_shortage}


func _is_frozen() -> bool:
	return time_manager != null and bool(time_manager.collect_save_data().get("frozen", false))


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
