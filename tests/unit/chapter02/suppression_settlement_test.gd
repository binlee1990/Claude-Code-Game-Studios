# tests/unit/chapter02/suppression_settlement_test.gd
# Story CH2-c-004: Suppression Battle Settlement
# Validates AC-CH2-004.3~5 (kill comparison + partial failure)

extends Gut

var _settle: SuppressionBattleSettlement

func before_each() -> void:
	_settle = SuppressionBattleSettlement.new()

func after_each() -> void:
	_settle = null

# --- AC-CH2-004.3: NPC kills > player kills → yi+10, zhi-5 ---

func test_ac_ch2_004_3_npc_kills_more_yi_plus_10_zhi_minus_5() -> void:
	_settle.record_npc_kill()
	_settle.record_npc_kill()
	_settle.record_player_kill()  # player=1, npc=2

	var result := _settle.evaluate()

	assert_eq(result.belief_yi_delta, 10,
		"NPC > player → yi+10")
	assert_eq(result.belief_zhi_delta, -5,
		"NPC > player → zhi-5")
	assert_eq(result.settlement_type, "victory",
		"Should still be victory despite partial failure condition")

# --- AC-CH2-004.4: Player kills >= NPC kills → yi+3, zhi+2 ---

func test_ac_ch2_004_4_player_kills_more_yi_plus_3_zhi_plus_2() -> void:
	_settle.record_player_kill()
	_settle.record_player_kill()
	_settle.record_npc_kill()  # player=2, npc=1

	var result := _settle.evaluate()

	assert_eq(result.belief_yi_delta, 3,
		"Player > NPC → yi+3")
	assert_eq(result.belief_zhi_delta, 2,
		"Player > NPC → zhi+2")

func test_ac_ch2_004_4_equal_kills_yields_player_branch() -> void:
	_settle.record_player_kill()
	_settle.record_npc_kill()  # equal

	var result := _settle.evaluate()

	assert_eq(result.belief_yi_delta, 3,
		"Equal kills → player branch: yi+3")

# --- AC-CH2-004.5: Flee count > 4 → partial_failure, yi-5 ---

func test_ac_ch2_004_5_flee_5_partial_failure_yi_minus_5() -> void:
	# Simulate 5 fleeing civilians
	_settle.record_flee()
	_settle.record_flee()
	_settle.record_flee()
	_settle.record_flee()
	_settle.record_flee()
	# flee_limit=4, so 5 > 4 → partial failure

	assert_true(_settle.is_partial_failure(),
		"Flee count 5 > limit 4 → partial failure")
	assert_eq(_settle.get_flee_count(), 5,
		"Flee count should be 5")

	var result := _settle.evaluate()

	assert_eq(result.settlement_type, "partial_failure",
		"Settlement type should be partial_failure")
	assert_eq(result.belief_yi_delta, -5,
		"Partial failure → yi-5")

func test_ac_ch2_004_5_flee_4_no_partial_failure() -> void:
	_settle.record_flee()  # 1
	_settle.record_flee()  # 2
	_settle.record_flee()  # 3
	_settle.record_flee()  # 4

	assert_false(_settle.is_partial_failure(),
		"Flee count 4 == limit → not partial failure (upper bound)")

# --- Edge cases ---

func test_zero_kills_equals() -> void:
	var result := _settle.evaluate()
	assert_eq(result.belief_yi_delta, 3,
		"Zero kills = equal → player branch: yi+3")
	assert_eq(result.belief_zhi_delta, 2)

func test_reset_clears_counters() -> void:
	_settle.record_player_kill()
	_settle.record_npc_kill()
	_settle.reset()

	var result := _settle.evaluate()
	assert_eq(result.belief_yi_delta, 3,
		"After reset, zero kills = equal → yi+3")

func test_load_config_custom_flee_limit() -> void:
	_settle.load_config({"suppression_flee_limit": 2})

	_settle.record_flee()  # 1
	_settle.record_flee()  # 2
	_settle.record_flee()  # 3 → > 2

	assert_true(_settle.is_partial_failure(),
		"3 > custom limit 2 → partial failure")
