class_name BaseUpgradeModel
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://assets/data/economy/base-upgrade-costs.json"

var schema_version: int = 0
var _costs: Array[Dictionary] = []

static func default_state() -> Dictionary:
	return {
		"level": 1,
		"unlocks": [],
	}

func load_config(path: String = DEFAULT_CONFIG_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var root := parsed as Dictionary
	schema_version = int(root.get("schema_version", 0))
	_costs.clear()
	for entry in root.get("costs", []):
		if typeof(entry) == TYPE_DICTIONARY:
			_costs.append((entry as Dictionary).duplicate(true))
	_costs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("from_level", 0)) < int(b.get("from_level", 0))
	)
	return not _costs.is_empty()

func normalize_state(state: Dictionary) -> Dictionary:
	var out := default_state()
	out["level"] = maxi(1, int(state.get("level", 1)))
	var unlocks: Array[String] = []
	var raw_unlocks: Variant = state.get("unlocks", [])
	if typeof(raw_unlocks) == TYPE_ARRAY:
		for raw in raw_unlocks:
			var unlock_id := String(raw)
			if unlock_id != "" and not unlocks.has(unlock_id):
				unlocks.append(unlock_id)
	for row in _costs:
		if int(row.get("to_level", 0)) <= int(out["level"]):
			for raw_unlock in row.get("unlocks", []):
				var unlock := String(raw_unlock)
				if unlock != "" and not unlocks.has(unlock):
					unlocks.append(unlock)
	out["unlocks"] = unlocks
	return out

func get_entry_for_level(level: int) -> Dictionary:
	for row in _costs:
		if int(row.get("from_level", 0)) == level:
			return row.duplicate(true)
	return {}

func get_cost_for_level(level: int) -> Dictionary:
	var row := get_entry_for_level(level)
	if row.is_empty():
		return {}
	return {
		"gold": int(row.get("gold", 0)),
		"basic_material": int(row.get("basic_material", 0)),
		"rare_material": int(row.get("rare_material", 0)),
	}

func get_shortage(level: int, inventory) -> Dictionary:
	if inventory == null:
		return {"inventory": 1}
	var cost := get_cost_for_level(level)
	if cost.is_empty():
		return {}
	var shortage := {}
	_add_shortage(shortage, "gold", ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0)), inventory)
	_add_shortage(shortage, "basic_material", ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("basic_material", 0)), inventory)
	_add_shortage(shortage, "rare_material", ResourceTypes.ResourceId.RARE_MATERIAL, int(cost.get("rare_material", 0)), inventory)
	return shortage

func can_upgrade(state: Dictionary, inventory) -> bool:
	var normalized := normalize_state(state)
	return not get_entry_for_level(int(normalized["level"])).is_empty() and get_shortage(int(normalized["level"]), inventory).is_empty()

func apply_upgrade(state: Dictionary, inventory) -> Dictionary:
	var normalized := normalize_state(state)
	var level := int(normalized["level"])
	var row := get_entry_for_level(level)
	if row.is_empty():
		return {"success": false, "reason": "max_level", "state": normalized}
	var shortage := get_shortage(level, inventory)
	if not shortage.is_empty():
		return {"success": false, "reason": "insufficient_resources", "shortage": shortage, "state": normalized}
	var cost := get_cost_for_level(level)
	_spend(ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0)), inventory)
	_spend(ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("basic_material", 0)), inventory)
	_spend(ResourceTypes.ResourceId.RARE_MATERIAL, int(cost.get("rare_material", 0)), inventory)
	var unlocks: Array = (normalized.get("unlocks", []) as Array).duplicate()
	for raw_unlock in row.get("unlocks", []):
		var unlock := String(raw_unlock)
		if unlock != "" and not unlocks.has(unlock):
			unlocks.append(unlock)
	normalized["level"] = int(row.get("to_level", level + 1))
	normalized["unlocks"] = unlocks
	return {
		"success": true,
		"from_level": level,
		"to_level": int(normalized["level"]),
		"cost": cost,
		"unlocks": row.get("unlocks", []).duplicate(),
		"state": normalized,
	}

func is_unlocked(state: Dictionary, unlock_id: String) -> bool:
	var normalized := normalize_state(state)
	return (normalized.get("unlocks", []) as Array).has(unlock_id)

func _add_shortage(shortage: Dictionary, key: String, resource_id: int, required: int, inventory) -> void:
	if required <= 0:
		return
	if not inventory.has_resource(resource_id, required):
		shortage[key] = required - inventory.get_amount(resource_id)

func _spend(resource_id: int, amount: int, inventory) -> void:
	if amount > 0:
		inventory.remove_resource(resource_id, amount)
