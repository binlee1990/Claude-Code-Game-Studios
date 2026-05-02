extends RefCounted

const Game = preload("res://src/game.gd")

var _previous_mode
var _games: Array = []

func before() -> void:
	_previous_mode = ProjectSettings.get_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_HOTSEAT)
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_HOTSEAT)
	_games = []

func after() -> void:
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, _previous_mode)
	for game in _games:
		if is_instance_valid(game):
			game.free()
	_games = []

func _make_game() -> Game:
	var game := Game.new()
	_games.append(game)
	return game

func test_hotseat_project_setting_creates_null_ai() -> void:
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_HOTSEAT)
	var game := _make_game()

	var ai := game._create_enemy_ai_controller([])

	assert(ai is NullAI)

func test_basic_project_setting_creates_basic_ai() -> void:
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_BASIC)
	var game := _make_game()

	var ai := game._create_enemy_ai_controller([])

	assert(ai is BasicAI)

func test_command_line_basic_overrides_hotseat_project_setting() -> void:
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_HOTSEAT)
	var game := _make_game()

	var ai := game._create_enemy_ai_controller(["--enemy-ai=basic"])

	assert(ai is BasicAI)

func test_command_line_hotseat_overrides_basic_project_setting() -> void:
	ProjectSettings.set_setting(Game.ENEMY_AI_MODE_SETTING, Game.ENEMY_AI_MODE_BASIC)
	var game := _make_game()

	var ai := game._create_enemy_ai_controller(["--enemy-ai", "hotseat"])

	assert(ai is NullAI)
