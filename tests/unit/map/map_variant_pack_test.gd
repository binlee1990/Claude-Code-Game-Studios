extends RefCounted

const MANIFEST_PATH := "res://assets/data/maps/map_variants.json"

var _loaded_maps: Array = []

func after() -> void:
	for map in _loaded_maps:
		if is_instance_valid(map):
			map.free()
	_loaded_maps = []

func test_manifest_lists_three_new_variant_maps() -> void:
	var manifest := _load_manifest()
	var variants := _variant_entries(manifest)

	assert(manifest["default_map"] == "test_map")
	assert(variants.size() == 3)
	for entry in variants:
		assert(FileAccess.file_exists("res://assets/data/maps/%s.csv" % entry["name"]))
		assert(entry["spawns"]["player"].size() == 2)
		assert(entry["spawns"]["enemy"].size() == 2)

func test_variant_maps_load_and_match_declared_dimensions() -> void:
	for entry in _load_manifest()["maps"]:
		var map := _load_map(entry["name"])
		var dimensions := map.get_dimensions()

		assert(dimensions["cols"] == entry["cols"])
		assert(dimensions["rows"] == entry["rows"])
		assert(dimensions["cols"] >= 8 and dimensions["cols"] <= 32)
		assert(dimensions["rows"] >= 8 and dimensions["rows"] <= 32)

func test_variant_spawns_are_unique_walkable_and_in_bounds() -> void:
	for entry in _load_manifest()["maps"]:
		var map := _load_map(entry["name"])
		var seen: Dictionary = {}
		var spawns := _all_spawns(entry)

		assert(spawns.size() == 4)
		for coord in spawns:
			assert(not seen.has(coord))
			seen[coord] = true
			assert(map.is_coord_in_bounds(coord))
			assert(map.get_tile_state(coord) == Map.TileState.WALKABLE)
			assert(map.is_walkable(coord))

func test_variant_maps_have_player_to_enemy_connectivity() -> void:
	for entry in _load_manifest()["maps"]:
		var map := _load_map(entry["name"])
		var enemy_spawns := _coords_from_pairs(entry["spawns"]["enemy"])

		for player_spawn in _coords_from_pairs(entry["spawns"]["player"]):
			assert(_has_path_to_any(map, player_spawn, enemy_spawns))

func test_variant_blocked_and_obstacle_tiles_are_not_walkable() -> void:
	var saw_blocked := false
	var saw_obstacle := false

	for entry in _load_manifest()["maps"]:
		var map := _load_map(entry["name"])
		var dimensions := map.get_dimensions()
		for row in range(dimensions["rows"]):
			for col in range(dimensions["cols"]):
				var coord := Vector2i(row, col)
				var state := map.get_tile_state(coord)
				if state == Map.TileState.BLOCKED:
					saw_blocked = true
					assert(not map.is_walkable(coord))
				elif state == Map.TileState.OBSTACLE:
					saw_obstacle = true
					assert(not map.is_walkable(coord))

	assert(saw_blocked)
	assert(saw_obstacle)

func _load_manifest() -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null)
	var parsed = JSON.parse_string(file.get_as_text())
	assert(typeof(parsed) == TYPE_DICTIONARY)
	assert(parsed.has("maps"))
	return parsed

func _variant_entries(manifest: Dictionary) -> Array:
	var variants: Array = []
	for entry in manifest["maps"]:
		if entry.get("role", "") == "variant":
			variants.append(entry)
	return variants

func _load_map(map_name: String) -> Map:
	var map := Map.new()
	map.emit_warnings = false
	map.initialize(GridSpace.new(), map_name)
	_loaded_maps.append(map)
	return map

func _all_spawns(entry: Dictionary) -> Array:
	var result := _coords_from_pairs(entry["spawns"]["player"])
	result.append_array(_coords_from_pairs(entry["spawns"]["enemy"]))
	return result

func _coords_from_pairs(pairs: Array) -> Array:
	var result: Array = []
	for pair in pairs:
		result.append(Vector2i(int(pair[0]), int(pair[1])))
	return result

func _has_path_to_any(map: Map, start: Vector2i, goals: Array) -> bool:
	var frontier: Array = [start]
	var visited: Dictionary = {start: true}

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current in goals:
			return true

		for neighbor in map.get_neighbors(current):
			if visited.has(neighbor):
				continue
			if map.get_tile_state(neighbor) != Map.TileState.WALKABLE:
				continue
			visited[neighbor] = true
			frontier.append(neighbor)

	return false
