class_name IdleExplorationSystem
extends RefCounted

var zone_system: ZoneSystem
var active_zone_id := ""
var state := "Ready"
var blocked_reason := ""
var last_session_summary := {}


func _init(zones: ZoneSystem = null) -> void:
	zone_system = zones


func initialize() -> void:
	if zone_system == null:
		state = "Blocked"
		blocked_reason = "zone_system_missing"
		return
	for zone in zone_system.get_sorted_zones():
		if bool(zone.get("unlocked", false)):
			active_zone_id = str(zone["id"])
			state = "Ready"
			return
	state = "Blocked"
	blocked_reason = "no_unlocked_zone"


func get_recommended_target() -> String:
	return active_zone_id


func assign_target(zone_id: String) -> bool:
	if zone_system == null:
		return false
	var result := zone_system.select_zone(zone_id)
	if not bool(result.get("ok", false)):
		state = "Blocked"
		blocked_reason = str(result.get("reason", "selection_failed"))
		return false
	active_zone_id = zone_id
	state = "Ready"
	_emit("exploration.target_changed", {"zone_id": zone_id})
	return true


func validate_target() -> bool:
	if zone_system == null or zone_system.get_zone(active_zone_id).is_empty():
		state = "Blocked"
		blocked_reason = "invalid_zone"
		return false
	return true


func apply_offline_summary(summary: Dictionary) -> void:
	last_session_summary = summary.duplicate(true)
	if float(summary.get("capacity_factor", 1.0)) < 0.2:
		last_session_summary["recommendation"] = "capacity_pressure"


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
