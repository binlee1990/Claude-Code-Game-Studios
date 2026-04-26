# tests/unit/chapter02/guard_stance_test.gd
# Story CH2-c-003: Guard Stance Damage Share
# Validates AC-CH2-003 (damage split with guard_transfer_ratio = 0.30)

extends Gut

var _guard: GuardStance

func before_each() -> void:
	_guard = GuardStance.new()

func after_each() -> void:
	_guard = null

# --- AC-CH2-003.1: Guard active, 20 damage → NPC 14, guardian 6 ---

func test_ac_ch2_003_1_guard_active_splits_20_damage() -> void:
	# Arrange: incoming_damage=20, has_guardian=true, ratio=0.30
	var result := _guard.evaluate(20, true, 1)

	assert_eq(result.npc_damage, 14,
		"NPC should take 14 damage (20 × 0.70)")
	assert_eq(result.guardian_damage, 6,
		"Guardian should take 6 damage (20 × 0.30)")
	assert_true(result.was_guard_active,
		"Guard should be active")

func test_ac_ch2_003_1_guardian_speed_rank_irrelevant_to_split() -> void:
	# Arrange: verify the speed rank parameter doesn't affect damage split
	var result_low := _guard.evaluate(20, true, 10)  # slow (rank 10)
	var result_high := _guard.evaluate(20, true, 1)  # fast (rank 1)

	assert_eq(result_low.npc_damage, result_high.npc_damage,
		"Speed rank should not affect damage split")
	assert_eq(result_low.guardian_damage, result_high.guardian_damage,
		"Speed rank should not affect guardian damage")

# --- AC-CH2-003.2: No guardian, 20 damage → NPC 20, guardian 0 ---

func test_ac_ch2_003_2_no_guardian_full_damage_to_npc() -> void:
	# Arrange: incoming_damage=20, has_guardian=false
	var result := _guard.evaluate(20, false, 0)

	assert_eq(result.npc_damage, 20,
		"NPC should take full 20 damage when no guardian")
	assert_eq(result.guardian_damage, 0,
		"Guardian should take 0 damage when none exists")
	assert_false(result.was_guard_active,
		"Guard should not be active")

# --- Edge cases ---

func test_zero_damage_no_guard() -> void:
	var result := _guard.evaluate(0, true, 1)
	assert_eq(result.npc_damage, 0,
		"Zero damage should result in 0 NPC damage")
	assert_eq(result.guardian_damage, 0,
		"Zero damage should result in 0 guardian damage")
	assert_false(result.was_guard_active,
		"Guard should not activate for 0 damage")

func test_33_damage_rounds_to_11_and_22() -> void:
	# 33 × 0.30 = 9.9 → rounds to 10, NPC = 23
	var result := _guard.evaluate(33, true, 1)
	assert_eq(result.guardian_damage, 10,
		"33 × 0.30 = 9.9 → rounds to 10")
	assert_eq(result.npc_damage, 23,
		"NPC takes remainder: 33 - 10 = 23")

func test_1_damage_rounds_to_0_and_1() -> void:
	# 1 × 0.30 = 0.3 → rounds to 0, NPC = 1
	var result := _guard.evaluate(1, true, 1)
	assert_eq(result.guardian_damage, 0,
		"Small damage rounds guardian portion to 0")
	assert_eq(result.npc_damage, 1,
		"NPC takes full 1 when guardian portion rounds to 0")

func test_negative_damage_treated_as_zero() -> void:
	# Negative incoming damage (e.g. heal) → no guard activation
	var result := _guard.evaluate(-10, true, 1)
	assert_eq(result.npc_damage, -10,
		"Negative damage should pass through unchanged")
	assert_eq(result.guardian_damage, 0,
		"Guardian should not take negative damage")

# --- Config: load custom ratio ---

func test_load_config_sets_custom_ratio() -> void:
	var config := {"guard_transfer_ratio": 0.50}
	_guard.load_config(config)

	# With 50% ratio, 20 damage splits to 10/10
	var result := _guard.evaluate(20, true, 1)
	assert_eq(result.guardian_damage, 10,
		"Custom 50% ratio: 20 × 0.50 = 10")
	assert_eq(result.npc_damage, 10,
		"NPC takes remainder: 20 - 10 = 10")

func test_load_config_defaults_if_missing() -> void:
	_guard.load_config({})  # empty config

	var result := _guard.evaluate(20, true, 1)
	assert_eq(result.guardian_damage, 6,
		"Missing config should default to 30%: 20 × 0.30 = 6")
