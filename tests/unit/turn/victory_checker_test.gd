extends RefCounted

# Story turn/003: VictoryChecker + Match End tests
# TR-turn-004, TR-turn-009, TR-turn-010, TR-vic-001~005 | ADR-0004, ADR-0009

var _vc: VictoryChecker

func before() -> void:
	_vc = VictoryChecker.new()

func _make_unit(faction: Faction.Type, alive: bool) -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	stats.max_hp = 10
	u.initialize(stats, faction)
	if not alive:
		u.hp = 0
	return u

func test_elimination_player_wins_when_all_enemies_dead() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, false)]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_elimination_enemy_wins_when_all_players_dead() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, false), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.ENEMY)
	assert(result.reason == "elimination")

func test_mutual_destruction_player_wins_fallback() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, false), _make_unit(Faction.Type.ENEMY, false)]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_turn_cap_player_wins_by_more_alive() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "turn_cap")

func test_turn_cap_enemy_wins_by_more_alive() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.ENEMY)
	assert(result.reason == "turn_cap")

func test_turn_cap_equal_alive_draw() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "turn_cap")

func test_no_winner_mid_game() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 5, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

func test_turn_cap_not_reached_returns_empty() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 30, 30)
	assert(result.winner == Faction.Type.NONE)

func test_elimination_overrides_turn_cap() -> void:
	# Turn cap reached AND enemy eliminated → elimination wins
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, false)]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_empty_units_returns_player_elimination() -> void:
	var units: Array[Unit] = []
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")
