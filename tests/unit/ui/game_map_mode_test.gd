extends RefCounted

const Game = preload("res://src/game.gd")

class ShortSpawnManifest:
	func get_spawn_points_for_faction(_map_name: String, _faction: Faction.Type) -> Array:
		return [Vector2i(0, 0)]

class DuplicateSpawnManifest:
	func get_spawn_points_for_faction(_map_name: String, _faction: Faction.Type) -> Array:
		return [Vector2i(5, 2), Vector2i(5, 2)]

class OutOfBoundsSpawnManifest:
	func get_spawn_points_for_faction(_map_name: String, _faction: Faction.Type) -> Array:
		return [Vector2i(-1, -1), Vector2i(5, 2)]

var _previous_map
var _games: Array = []

func before() -> void:
	_previous_map = ProjectSettings.get_setting(Game.MAP_NAME_SETTING, Game.DEFAULT_MAP_NAME)
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, Game.DEFAULT_MAP_NAME)
	_games = []

func after() -> void:
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, _previous_map)
	for game in _games:
		if is_instance_valid(game):
			game.free()
	_games = []

func test_default_project_setting_resolves_test_map() -> void:
	var game := _make_game()

	assert(game._resolve_map_name([]) == "test_map")

func test_project_setting_can_select_variant_map() -> void:
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, "central_choke")
	var game := _make_game()

	assert(game._resolve_map_name([]) == "central_choke")

func test_command_line_equals_overrides_project_setting() -> void:
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, "test_map")
	var game := _make_game()

	assert(game._resolve_map_name(["--map=crossroads"]) == "crossroads")

func test_command_line_space_overrides_project_setting() -> void:
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, "test_map")
	var game := _make_game()

	assert(game._resolve_map_name(["--map", "split_lanes"]) == "split_lanes")

func test_invalid_map_name_falls_back_to_test_map() -> void:
	ProjectSettings.set_setting(Game.MAP_NAME_SETTING, "does_not_exist")
	var game := _make_game()

	assert(game._resolve_map_name([]) == "test_map")
	assert(game._resolve_map_name(["--map=missing"]) == "test_map")

func test_default_spawn_fixture_preserves_existing_positions() -> void:
	var game := _make_game_with_map("test_map")
	var units := game._create_units("test_map")

	assert(_positions_for_faction(units, Faction.Type.PLAYER) == [Vector2i(5, 2), Vector2i(5, 4)])
	assert(_positions_for_faction(units, Faction.Type.ENEMY) == [Vector2i(5, 10), Vector2i(5, 12)])

func test_variant_spawn_fixture_places_units_from_manifest() -> void:
	var game := _make_game_with_map("crossroads")
	var units := game._create_units("crossroads")

	assert(_positions_for_faction(units, Faction.Type.PLAYER) == [Vector2i(5, 2), Vector2i(6, 2)])
	assert(_positions_for_faction(units, Faction.Type.ENEMY) == [Vector2i(5, 13), Vector2i(6, 13)])
	assert(game.map.get_unit_at(Vector2i(5, 2)) == units[0])
	assert(game.map.get_unit_at(Vector2i(6, 13)) == units[3])

func test_variant_spawn_fixture_keeps_unit_stats_unchanged() -> void:
	var game := _make_game_with_map("split_lanes")
	var units := game._create_units("split_lanes")
	var player: Unit = units[0]
	var enemy: Unit = units[2]

	assert(player.max_hp == 10)
	assert(player.atk == 5)
	assert(player.def == 2)
	assert(player.mov == 4)
	assert(player.rng == 1)
	assert(enemy.max_hp == 8)
	assert(enemy.atk == 4)
	assert(enemy.def == 1)
	assert(enemy.mov == 3)
	assert(enemy.rng == 1)

func test_short_spawn_fixture_falls_back_to_default_positions() -> void:
	var game := _make_game_with_map("test_map")
	game._map_variant_manifest = ShortSpawnManifest.new()

	assert(game._get_spawn_points("test_map", Faction.Type.PLAYER) == [Vector2i(5, 2), Vector2i(5, 4)])

func test_duplicate_spawn_fixture_falls_back_to_default_positions() -> void:
	var game := _make_game_with_map("test_map")
	game._map_variant_manifest = DuplicateSpawnManifest.new()

	assert(game._get_spawn_points("test_map", Faction.Type.PLAYER) == [Vector2i(5, 2), Vector2i(5, 4)])

func test_out_of_bounds_spawn_fixture_falls_back_to_default_positions() -> void:
	var game := _make_game_with_map("test_map")
	game._map_variant_manifest = OutOfBoundsSpawnManifest.new()

	assert(game._get_spawn_points("test_map", Faction.Type.PLAYER) == [Vector2i(5, 2), Vector2i(5, 4)])

func _make_game() -> Game:
	var game := Game.new()
	_games.append(game)
	return game

func _make_game_with_map(map_name: String) -> Game:
	var game := _make_game()
	game.grid_space = GridSpace.new()
	game.map = Map.new()
	game.map.emit_warnings = false
	game.add_child(game.map)
	game.map.initialize(game.grid_space, map_name)
	return game

func _positions_for_faction(units: Array, faction: Faction.Type) -> Array:
	var positions: Array = []
	for unit in units:
		if unit.faction == faction:
			positions.append(unit.grid_position)
	return positions
