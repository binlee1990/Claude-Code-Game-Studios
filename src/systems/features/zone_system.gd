class_name ZoneSystem
extends RefCounted

var data_config: Object
var enemy_database: EnemyDatabase
var _zones := {}
var current_zone_id := ""
var degraded_warnings := []


func _init(config: Object = null, enemies: EnemyDatabase = null) -> void:
	data_config = config
	enemy_database = enemies


func load_all() -> void:
	_zones.clear()
	degraded_warnings.clear()
	var table = {}
	if data_config != null and data_config.has_method("get_all"):
		table = data_config.call("get_all", "zones")
	if typeof(table) != TYPE_DICTIONARY:
		table = {}
	for id in table.keys():
		var zone: Dictionary = table[id]
		var pool := []
		for entry in zone.get("enemy_pool", []):
			var enemy_id := str(entry.get("enemy_id", ""))
			if enemy_database != null and not enemy_database.has_enemy(enemy_id):
				degraded_warnings.append("%s missing enemy %s" % [str(id), enemy_id])
				continue
			pool.append({"enemy_id": enemy_id, "weight": float(entry.get("weight", 1.0))})
		_zones[str(id)] = {
			"id": str(id),
			"name": str(zone.get("name", id)),
			"order": int(zone.get("order", 0)),
			"unlocked": bool(zone.get("unlocked", false)),
			"enemy_pool": pool,
			"unlock": zone.get("unlock", {}),
			"background_path": str(zone.get("background_path", "")),
			"transition_vfx_path": str(zone.get("transition_vfx_path", "")),
		}
	if current_zone_id.is_empty() and not get_sorted_zones().is_empty():
		current_zone_id = get_sorted_zones()[0]["id"]


func get_zone(zone_id: String) -> Dictionary:
	return _zones.get(zone_id, {}).duplicate(true)


func get_sorted_zones() -> Array:
	var zones := _zones.values()
	zones.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))
	return zones


func select_zone(zone_id: String) -> Dictionary:
	if not _zones.has(zone_id):
		return {"ok": false, "reason": "missing_zone", "current_zone": current_zone_id}
	if not bool(_zones[zone_id]["unlocked"]):
		return {"ok": false, "reason": "locked", "current_zone": current_zone_id}
	current_zone_id = zone_id
	_emit("zone.changed", {"zone_id": zone_id})
	return {"ok": true, "zone_id": zone_id}


func unlock_zone(zone_id: String) -> bool:
	if not _zones.has(zone_id):
		return false
	_zones[zone_id]["unlocked"] = true
	return true


func get_enemy_pool(zone_id: String = "") -> Array:
	var id := zone_id if not zone_id.is_empty() else current_zone_id
	return _zones.get(id, {}).get("enemy_pool", []).duplicate(true)


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
