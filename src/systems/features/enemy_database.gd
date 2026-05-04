class_name EnemyDatabase
extends RefCounted

const REQUIRED_ATTRS := ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"]

var data_config: Object
var _enemies := {}
var _loaded := false


func _init(config: Object = null) -> void:
	data_config = config


func load_all() -> void:
	_enemies.clear()
	var table = {}
	if data_config != null and data_config.has_method("get_all"):
		table = data_config.call("get_all", "enemies")
	if typeof(table) != TYPE_DICTIONARY:
		table = {}
	for id in table.keys():
		var enemy := _normalize_enemy(str(id), table[id])
		if not enemy.is_empty():
			_enemies[str(id)] = enemy
	_loaded = true


func reload() -> void:
	if data_config != null and data_config.has_method("reload_table"):
		data_config.call("reload_table", "enemies")
	load_all()


func get_count() -> int:
	return _enemies.size()


func has_enemy(enemy_id: String) -> bool:
	return _enemies.has(enemy_id)


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {}).duplicate(true)


func get_by_zone_tag(tag: String) -> Array:
	var result := []
	for id in _enemies.keys():
		if _enemies[id].get("zone_tags", []).has(tag):
			result.append(get_enemy(str(id)))
	return result


func create_combat_snapshot(enemy_id: String, instance_id: String = "") -> Dictionary:
	if not _enemies.has(enemy_id):
		return {}
	var enemy: Dictionary = _enemies[enemy_id]
	var attrs: Dictionary = enemy["base_attributes"]
	var snapshot := {"id": enemy_id, "instance_id": instance_id, "level": enemy["level"]}
	for attr_id in REQUIRED_ATTRS:
		snapshot[attr_id] = _to_number(attrs[attr_id])
	return snapshot


func _normalize_enemy(id: String, raw_value: Variant) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = raw_value
	var attrs: Dictionary = raw.get("base_attributes", {})
	for attr_id in attrs.keys():
		if not REQUIRED_ATTRS.has(str(attr_id)):
			push_warning("EnemyDatabase: invalid attribute id '%s' in enemy '%s'" % [str(attr_id), id])
			return {}
	for attr_id in REQUIRED_ATTRS:
		if not attrs.has(attr_id):
			push_warning("EnemyDatabase: missing attribute '%s' in enemy '%s'" % [attr_id, id])
			return {}
	return {
		"id": id,
		"name": str(raw.get("name", id)),
		"level": max(1, int(raw.get("level", 1))),
		"attribute_set": str(raw.get("attribute_set", "enemy_basic_set")),
		"base_attributes": attrs.duplicate(true),
		"loot_table_id": str(raw.get("loot_table_id", "")),
		"zone_tags": raw.get("zone_tags", []).duplicate(),
		"combat_tags": raw.get("combat_tags", []).duplicate(),
		"weight": max(0.0, float(raw.get("weight", 1.0))),
	}


func _to_number(value: Variant) -> float:
	if typeof(value) == TYPE_STRING:
		return str(value).to_float()
	return float(value)
