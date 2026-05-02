class_name MapVariantManifest extends RefCounted

const DEFAULT_PATH := "res://assets/data/maps/map_variants.json"
const DEFAULT_MAP_NAME := "test_map"
const MAP_CSV_TEMPLATE := "res://assets/data/maps/%s.csv"

var default_map_name: String = DEFAULT_MAP_NAME
var _entries: Dictionary = {}

static func load_default():
	var script = load("res://src/map/map_variant_manifest.gd")
	var manifest = script.new()
	manifest.load_from_file(DEFAULT_PATH)
	return manifest

func load_from_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	default_map_name = str(parsed.get("default_map", DEFAULT_MAP_NAME))
	_entries.clear()
	for entry in parsed.get("maps", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var map_name := str(entry.get("name", "")).strip_edges()
		if map_name == "":
			continue
		_entries[map_name] = entry
	return true

func get_map_names() -> Array:
	var names := _entries.keys()
	names.sort()
	return names

func has_map(map_name: String) -> bool:
	var normalized := map_name.strip_edges()
	return _entries.has(normalized) and FileAccess.file_exists(MAP_CSV_TEMPLATE % normalized)

func resolve_map_name(raw_map_name: String) -> String:
	var requested := raw_map_name.strip_edges()
	if has_map(requested):
		return requested
	if has_map(default_map_name):
		return default_map_name
	return DEFAULT_MAP_NAME

func get_dimensions(map_name: String) -> Dictionary:
	var entry := _get_entry(map_name)
	return {
		"cols": int(entry.get("cols", 0)),
		"rows": int(entry.get("rows", 0)),
	}

func get_spawn_points_for_faction(map_name: String, faction: Faction.Type) -> Array:
	var key := _faction_key(faction)
	if key == "":
		return []

	var entry := _get_entry(map_name)
	var spawns = entry.get("spawns", {})
	if typeof(spawns) != TYPE_DICTIONARY:
		return []

	return _coords_from_pairs(spawns.get(key, []))

func _get_entry(map_name: String) -> Dictionary:
	var resolved := resolve_map_name(map_name)
	return _entries.get(resolved, {})

func _faction_key(faction: Faction.Type) -> String:
	if faction == Faction.Type.PLAYER:
		return "player"
	if faction == Faction.Type.ENEMY:
		return "enemy"
	return ""

func _coords_from_pairs(pairs: Array) -> Array:
	var result: Array = []
	for pair in pairs:
		if typeof(pair) != TYPE_ARRAY or pair.size() < 2:
			continue
		result.append(Vector2i(int(pair[0]), int(pair[1])))
	return result
