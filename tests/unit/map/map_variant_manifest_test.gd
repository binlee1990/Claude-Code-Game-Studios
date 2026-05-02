extends RefCounted

const MapVariantManifest = preload("res://src/map/map_variant_manifest.gd")

func test_load_default_manifest_exposes_default_map() -> void:
	var manifest = MapVariantManifest.load_default()

	assert(manifest.default_map_name == "test_map")
	assert(manifest.has_map("test_map"))

func test_manifest_lists_baseline_and_variant_maps() -> void:
	var manifest = MapVariantManifest.load_default()
	var names = manifest.get_map_names()

	assert(names.size() == 5)
	assert("test_map" in names)
	assert("crossroads" in names)
	assert("central_choke" in names)
	assert("split_lanes" in names)
	assert("rough_pass" in names)

func test_resolve_map_name_falls_back_to_default() -> void:
	var manifest = MapVariantManifest.load_default()

	assert(manifest.resolve_map_name("crossroads") == "crossroads")
	assert(manifest.resolve_map_name("does_not_exist") == "test_map")
	assert(manifest.resolve_map_name("") == "test_map")

func test_dimensions_are_available_for_selected_map() -> void:
	var manifest = MapVariantManifest.load_default()
	var dimensions = manifest.get_dimensions("split_lanes")

	assert(dimensions["cols"] == 16)
	assert(dimensions["rows"] == 12)

func test_spawn_points_preserve_row_col_order() -> void:
	var manifest = MapVariantManifest.load_default()
	var player_spawns = manifest.get_spawn_points_for_faction("crossroads", Faction.Type.PLAYER)
	var enemy_spawns = manifest.get_spawn_points_for_faction("crossroads", Faction.Type.ENEMY)

	assert(player_spawns == [Vector2i(5, 2), Vector2i(6, 2)])
	assert(enemy_spawns == [Vector2i(5, 13), Vector2i(6, 13)])

func test_unknown_map_spawn_query_uses_default_fixture() -> void:
	var manifest = MapVariantManifest.load_default()
	var player_spawns = manifest.get_spawn_points_for_faction("unknown", Faction.Type.PLAYER)

	assert(player_spawns == [Vector2i(5, 2), Vector2i(5, 4)])
