extends RefCounted

# Story 6-1: VictoryChecker — 全灭判定
# AC-VICTORY-005~007, 010~013, 017, 020, 022~023, 026 | ADR-0009

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

# --- A. 判定表覆盖 ---

func test_elimination_player_wins_when_enemy_all_dead() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, false),
	]
	var result := _vc.determine_winner(units, 10, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_elimination_enemy_wins_when_player_all_dead() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.ENEMY, true),
		_make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 10, 30)
	assert(result.winner == Faction.Type.ENEMY)
	assert(result.reason == "elimination")

func test_mutual_destruction_player_wins_fallback() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.ENEMY, false),
	]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

# --- B. 公式 F1: alive_count 基础计数 ---

func test_alive_count_mixed_alive_and_dead() -> void:
	# P1(alive), P2(dead), P3(alive), E1(dead), E2(alive)
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, false),
		_make_unit(Faction.Type.ENEMY, true),
	]
	# alive_p=2, alive_e=1 → PLAYER wins by elimination when ENEMY dead
	# But ENEMY still has E2 alive, so no elimination
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

func test_alive_count_empty_units_array() -> void:
	var units: Array[Unit] = []
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_alive_count_only_player_units() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, true),
	]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_alive_count_all_dead() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.PLAYER, false),
		_make_unit(Faction.Type.ENEMY, false),
	]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

# --- C. 核心边缘情况 ---

func test_elimination_overrides_turn_cap() -> void:
	# Elimination AND turn_cap both satisfied → elimination wins
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, false),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_freed_unit_reference_skipped_in_alive_count() -> void:
	var freed := Unit.new()
	var stats := UnitStats.new()
	freed.initialize(stats, Faction.Type.PLAYER)
	freed.free()
	var alive_enemy := _make_unit(Faction.Type.ENEMY, true)
	var units: Array = [freed, alive_enemy]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.ENEMY)
	assert(result.reason == "elimination")

func test_all_units_freed_returns_player_elimination() -> void:
	var freed1 := Unit.new()
	var stats1 := UnitStats.new()
	freed1.initialize(stats1, Faction.Type.PLAYER)
	freed1.free()
	var freed2 := Unit.new()
	var stats2 := UnitStats.new()
	freed2.initialize(stats2, Faction.Type.ENEMY)
	freed2.free()
	var units: Array = [freed1, freed2]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "elimination")

func test_unknown_faction_not_counted_in_either() -> void:
	var u := Unit.new()
	var stats := UnitStats.new()
	u.initialize(stats, Faction.Type.NONE)
	var units: Array[Unit] = [
		u,
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

# --- D. 公式 F3: 结构验证 ---

func test_return_structure_has_only_winner_and_reason_keys() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true)]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.has("winner"))
	assert(result.has("reason"))
	assert(result.keys().size() == 2)
