class_name BondRegistry
extends RefCounted

const MAX_AFFINITY: int = 999
const DEFAULT_BOND_TYPE: String = "comrade"
const RANK_NONE: String = "None"

const RANK_THRESHOLDS: Array[Dictionary] = [
	{"rank": "S", "threshold": 600},
	{"rank": "A", "threshold": 350},
	{"rank": "B", "threshold": 150},
	{"rank": "C", "threshold": 50},
]

var _pairs: Dictionary = {}

static func make_pair_key(first_unit_id: String, second_unit_id: String) -> String:
	var first := first_unit_id.strip_edges()
	var second := second_unit_id.strip_edges()
	if first == "" or second == "" or first == second:
		return ""
	var ids := [first, second]
	ids.sort()
	return "%s::%s" % [ids[0], ids[1]]

static func rank_for_affinity(affinity: int) -> String:
	for row in RANK_THRESHOLDS:
		if affinity >= int(row["threshold"]):
			return String(row["rank"])
	return RANK_NONE

static func load_from_story_progress(story_progress: Dictionary) -> BondRegistry:
	var registry := BondRegistry.new()
	registry.deserialize(story_progress.get("bond_levels", {}))
	return registry

func save_to_story_progress(story_progress: Dictionary) -> Dictionary:
	var out := story_progress.duplicate(true)
	out["bond_levels"] = serialize()
	return out

func has_pair(first_unit_id: String, second_unit_id: String) -> bool:
	return _pairs.has(make_pair_key(first_unit_id, second_unit_id))

func ensure_pair(first_unit_id: String, second_unit_id: String, bond_type: String = DEFAULT_BOND_TYPE) -> Dictionary:
	var pair_key := make_pair_key(first_unit_id, second_unit_id)
	if pair_key == "":
		return {}
	if _pairs.has(pair_key):
		return (_pairs[pair_key] as Dictionary).duplicate(true)
	var ids := pair_key.split("::")
	var pair := {
		"pair_key": pair_key,
		"unit_a": String(ids[0]),
		"unit_b": String(ids[1]),
		"affinity": 0,
		"rank": RANK_NONE,
		"bond_type": bond_type if bond_type.strip_edges() != "" else DEFAULT_BOND_TYPE,
	}
	_pairs[pair_key] = pair
	return pair.duplicate(true)

func add_affinity(
	first_unit_id: String,
	second_unit_id: String,
	amount: int,
	bond_type: String = DEFAULT_BOND_TYPE,
	source: String = ""
) -> Dictionary:
	if amount <= 0:
		return {"success": false, "reason": "non_positive_amount"}
	var pair_key := make_pair_key(first_unit_id, second_unit_id)
	if pair_key == "":
		return {"success": false, "reason": "invalid_pair"}
	var pair := ensure_pair(first_unit_id, second_unit_id, bond_type)
	var old_rank := String(pair.get("rank", RANK_NONE))
	var old_affinity := int(pair.get("affinity", 0))
	var new_affinity := mini(old_affinity + amount, MAX_AFFINITY)
	pair["affinity"] = new_affinity
	pair["rank"] = rank_for_affinity(new_affinity)
	if source != "":
		pair["last_source"] = source
	_pairs[pair_key] = pair.duplicate(true)
	var new_rank := String(pair["rank"])
	var result := {
		"success": true,
		"pair_key": pair_key,
		"old_affinity": old_affinity,
		"new_affinity": new_affinity,
		"old_rank": old_rank,
		"new_rank": new_rank,
		"rank_changed": old_rank != new_rank,
		"pair": pair.duplicate(true),
	}
	if old_rank != new_rank and GameEvents != null:
		GameEvents.bond_level_up.emit(pair_key, old_rank, new_rank, new_affinity)
	return result

func top_bonds_for_unit(unit_id: StringName, limit: int = 3) -> Array[Dictionary]:
	var target := String(unit_id)
	var rows: Array[Dictionary] = []
	for pair_key in _pairs:
		var pair: Dictionary = (_pairs[pair_key] as Dictionary).duplicate(true)
		if String(pair.get("unit_a", "")) != target and String(pair.get("unit_b", "")) != target:
			continue
		rows.append(pair)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var affinity_delta := int(b.get("affinity", 0)) - int(a.get("affinity", 0))
		if affinity_delta != 0:
			return int(a.get("affinity", 0)) > int(b.get("affinity", 0))
		return String(a.get("pair_key", "")) < String(b.get("pair_key", ""))
	)
	if limit <= 0 or rows.size() <= limit:
		return rows
	return rows.slice(0, limit)

func serialize() -> Dictionary:
	var out := {}
	for pair_key in _pairs:
		out[pair_key] = (_pairs[pair_key] as Dictionary).duplicate(true)
	return out

func deserialize(data: Variant) -> void:
	_pairs.clear()
	if typeof(data) != TYPE_DICTIONARY:
		return
	for raw_key in (data as Dictionary):
		var entry: Variant = data[raw_key]
		var pair := _normalize_entry(String(raw_key), entry)
		if pair.is_empty():
			continue
		_pairs[String(pair["pair_key"])] = pair

func _normalize_entry(raw_key: String, entry: Variant) -> Dictionary:
	if typeof(entry) == TYPE_INT or typeof(entry) == TYPE_FLOAT:
		var key_pair := _pair_from_key(raw_key)
		if key_pair.is_empty():
			return {}
		key_pair["affinity"] = clampi(int(entry), 0, MAX_AFFINITY)
		key_pair["rank"] = rank_for_affinity(int(key_pair["affinity"]))
		key_pair["bond_type"] = DEFAULT_BOND_TYPE
		return key_pair
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	var source := (entry as Dictionary).duplicate(true)
	var unit_a := String(source.get("unit_a", ""))
	var unit_b := String(source.get("unit_b", ""))
	var pair_key := make_pair_key(unit_a, unit_b)
	if pair_key == "":
		pair_key = make_pair_key(String(source.get("first_unit_id", "")), String(source.get("second_unit_id", "")))
	if pair_key == "":
		pair_key = raw_key if raw_key.contains("::") else ""
	if pair_key == "":
		return {}
	var ids := pair_key.split("::")
	var affinity := clampi(int(source.get("affinity", 0)), 0, MAX_AFFINITY)
	return {
		"pair_key": pair_key,
		"unit_a": String(ids[0]),
		"unit_b": String(ids[1]),
		"affinity": affinity,
		"rank": rank_for_affinity(affinity),
		"bond_type": String(source.get("bond_type", DEFAULT_BOND_TYPE)),
	}

func _pair_from_key(pair_key: String) -> Dictionary:
	if not pair_key.contains("::"):
		return {}
	var ids := pair_key.split("::")
	if ids.size() != 2:
		return {}
	var normalized_key := make_pair_key(String(ids[0]), String(ids[1]))
	if normalized_key == "":
		return {}
	var normalized_ids := normalized_key.split("::")
	return {
		"pair_key": normalized_key,
		"unit_a": String(normalized_ids[0]),
		"unit_b": String(normalized_ids[1]),
	}
