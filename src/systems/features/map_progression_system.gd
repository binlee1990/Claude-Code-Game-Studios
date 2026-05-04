class_name MapProgressionSystem
extends RefCounted

var zone_system: ZoneSystem
var level_system: LevelSystem
var cleared := {}
var farmable := {}
var unlocked := {}


func _init(zones: ZoneSystem = null, levels: LevelSystem = null) -> void:
	zone_system = zones
	level_system = levels


func evaluate_unlocks(entity_id: String = "player") -> Array:
	var newly := []
	if zone_system == null:
		return newly
	for zone in zone_system.get_sorted_zones():
		var unlock: Dictionary = zone.get("unlock", {})
		var required_level := int(unlock.get("required_level", 1))
		var prereq := str(unlock.get("prerequisite", ""))
		var level_ok := level_system == null or level_system.get_level(entity_id) >= required_level
		var prereq_ok := prereq.is_empty() or bool(cleared.get(prereq, false))
		if level_ok and prereq_ok and not bool(zone.get("unlocked", false)):
			zone_system.unlock_zone(str(zone["id"]))
			unlocked[str(zone["id"])] = true
			newly.append(str(zone["id"]))
	return newly


func on_combat_finished(payload: Dictionary) -> void:
	if not bool(payload.get("victory", false)):
		return
	var zone_id := str(payload.get("zone_id", ""))
	if zone_id.is_empty() or bool(cleared.get(zone_id, false)):
		return
	cleared[zone_id] = true
	_emit("zone.first_cleared", {"zone_id": zone_id})


func mark_farmable(zone_id: String, win_rate: float) -> void:
	farmable[zone_id] = win_rate >= 0.80


func select_zone(zone_id: String) -> Dictionary:
	if zone_system == null:
		return {"ok": false, "reason": "zone_system_missing"}
	return zone_system.select_zone(zone_id)


func snapshot() -> Dictionary:
	return {"unlocked": unlocked.duplicate(), "cleared": cleared.duplicate(), "farmable": farmable.duplicate()}


func restore(data: Dictionary) -> void:
	unlocked = data.get("unlocked", {}).duplicate()
	cleared = data.get("cleared", {}).duplicate()
	farmable = data.get("farmable", {}).duplicate()
	if zone_system != null:
		for zone_id in unlocked.keys():
			zone_system.unlock_zone(str(zone_id))


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
