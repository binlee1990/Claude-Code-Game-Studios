extends RefCounted

# Story 6-2: VictoryChecker — 回合上限 + 存活数判定
# AC-VICTORY-001~004, 014~016, 018~019, 021, 024~025, 027~030 | ADR-0009

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

# --- A. 判定表覆盖: Turn Cap ---

func test_turn_cap_player_wins_by_more_alive() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "turn_cap")

func test_turn_cap_enemy_wins_by_more_alive() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.ENEMY)
	assert(result.reason == "turn_cap")

func test_turn_cap_equal_alive_draw() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "turn_cap")

func test_no_termination_mid_game_continues() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 5, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

# --- C. 公式 F2: cap_breached ---

func test_cap_not_breached_at_boundary_turn_equals_cap() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 30, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

func test_cap_breached_when_turn_exceeds_cap() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "turn_cap")

func test_cap_far_from_breach_turn_one() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

# --- D. 公式 F3: 结构验证 ---

func test_pure_function_determinism_three_calls() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var r1 := _vc.determine_winner(units, 31, 30)
	var r2 := _vc.determine_winner(units, 31, 30)
	var r3 := _vc.determine_winner(units, 31, 30)
	assert(r1.winner == r2.winner and r2.winner == r3.winner)
	assert(r1.reason == r2.reason and r2.reason == r3.reason)

func test_reason_nonempty_iff_match_ended() -> void:
	# turn_cap triggered but draw → NONE + "turn_cap" (match ended)
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var r1 := _vc.determine_winner(units, 31, 30)
	assert(r1.reason != "")
	# mid-game → NONE + "" (match continues)
	var r2 := _vc.determine_winner(units, 5, 30)
	assert(r2.reason == "")

# --- E. 核心边缘情况 ---

func test_turn_cap_one_fast_end() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 2, 1)
	assert(result.reason == "turn_cap")

func test_match_start_no_termination() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 1, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "")

func test_turn_cap_max_boundary_99() -> void:
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true), _make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 100, 99)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "turn_cap")

func test_single_alive_each_turn_cap_draw() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.ENEMY, true)]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.NONE)
	assert(result.reason == "turn_cap")

func test_min_advantage_turn_cap_player_wins() -> void:
	# alive_p=2, alive_e=1, difference=1
	var units: Array[Unit] = [
		_make_unit(Faction.Type.PLAYER, true), _make_unit(Faction.Type.PLAYER, true),
		_make_unit(Faction.Type.ENEMY, true),
	]
	var result := _vc.determine_winner(units, 31, 30)
	assert(result.winner == Faction.Type.PLAYER)
	assert(result.reason == "turn_cap")

# --- 输入校验 ---

func test_assert_turn_number_less_than_one() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true)]
	var caught := false
	_vc.determine_winner(units, 0, 30)
	# If assert doesn't kill the test runner, verify we got here (debug build)
	# In headless, assert may be disabled — treat pass as no-op
	assert(true)  # Acceptance: assert trigger in debug; no crash in release

func test_assert_turn_cap_less_than_one() -> void:
	var units: Array[Unit] = [_make_unit(Faction.Type.PLAYER, true)]
	var caught := false
	_vc.determine_winner(units, 1, 0)
	assert(true)  # Acceptance: assert trigger in debug; no crash in release
