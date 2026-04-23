# tests/unit/settlement/experience_distribution_test.gd
# Story BS-002: Experience Distribution
# Validates AC.2.1 (equal split), AC-E1 (evaluation bonus), AC-E2 (overflow / level-ups)
#
# Naming deviation note: story evidence field specifies exp_distribution_test.gd;
# this file uses experience_distribution_test.gd to match class_name ExperienceDistribution
# and the project convention [system]_[feature]_test.gd. Approved 2026-04-23.

extends Gut

# ---------------------------------------------------------------------------
# compute_total_exp — GDD C.2
# ---------------------------------------------------------------------------

func test_compute_total_exp_single_normal() -> void:
	# Arrange
	var tiers: Array = [ExperienceDistribution.EnemyTier.NORMAL]

	# Act
	var result: int = ExperienceDistribution.compute_total_exp(tiers)

	# Assert
	assert_eq(result, 50, "Single NORMAL enemy must yield 50 EXP (GDD C.2)")


func test_compute_total_exp_mixed_tiers() -> void:
	# Arrange — NORMAL(50) + ELITE(150) + BOSS(1000)
	var tiers: Array = [
		ExperienceDistribution.EnemyTier.NORMAL,
		ExperienceDistribution.EnemyTier.ELITE,
		ExperienceDistribution.EnemyTier.BOSS,
	]

	# Act
	var result: int = ExperienceDistribution.compute_total_exp(tiers)

	# Assert
	assert_eq(result, 1200, "NORMAL+ELITE+BOSS must total 1200 EXP (GDD C.2)")


func test_compute_total_exp_empty_list_is_zero() -> void:
	# Arrange
	var tiers: Array = []

	# Act
	var result: int = ExperienceDistribution.compute_total_exp(tiers)

	# Assert
	assert_eq(result, 0, "Empty enemy list must yield 0 total EXP")

# ---------------------------------------------------------------------------
# apply_evaluation_bonus — GDD D.2 / AC-E1
# ---------------------------------------------------------------------------

func test_apply_evaluation_bonus_normal_unchanged() -> void:
	# Arrange
	var base: int = 500
	var bonus: float = ExperienceDistribution.EVAL_BONUS["normal"]  # 0.0

	# Act
	var result: int = ExperienceDistribution.apply_evaluation_bonus(base, bonus)

	# Assert
	assert_eq(result, 500, "Normal evaluation (x1.0) must leave EXP unchanged (GDD D.2)")


func test_ac_e1_excellent_bonus_20_percent() -> void:
	# Arrange
	var base: int = 500
	var bonus: float = ExperienceDistribution.EVAL_BONUS["excellent"]  # 0.2

	# Act
	var result: int = ExperienceDistribution.apply_evaluation_bonus(base, bonus)

	# Assert — 500 x 1.2 = 600
	assert_eq(result, 600, "AC-E1: Excellent bonus must yield 500x1.2=600 EXP (GDD D.2)")


func test_ac_e1_perfect_bonus_50_percent() -> void:
	# Arrange — GDD QA example: 333 x 1.5 = 499.5 -> floor = 499
	var base: int = 333
	var bonus: float = ExperienceDistribution.EVAL_BONUS["perfect"]  # 0.5

	# Act
	var result: int = ExperienceDistribution.apply_evaluation_bonus(base, bonus)

	# Assert
	assert_eq(result, 499, "AC-E1: Perfect bonus on 333 must floor to 499 (GDD D.2, QA scenario)")


func test_apply_evaluation_bonus_zero_base_returns_zero() -> void:
	# Arrange
	var base: int = 0

	# Act
	var result: int = ExperienceDistribution.apply_evaluation_bonus(base, 0.5)

	# Assert
	assert_eq(result, 0, "Zero base EXP must always yield 0 regardless of bonus")

# ---------------------------------------------------------------------------
# per_unit_exp — GDD D.1 / AC.2.1
# ---------------------------------------------------------------------------

func test_ac_2_1_per_unit_exp_equal_split() -> void:
	# Arrange
	var total: int = 1000
	var survivors: int = 4

	# Act
	var result: int = ExperienceDistribution.per_unit_exp(total, survivors)

	# Assert
	assert_eq(result, 250, "AC.2.1: 1000 EXP / 4 survivors = 250 each (GDD D.1)")


func test_ac_2_1_per_unit_exp_integer_division_floor() -> void:
	# Arrange — GDD D.1 example: 1000 / 3 = 333 (floor)
	var total: int = 1000
	var survivors: int = 3

	# Act
	var result: int = ExperienceDistribution.per_unit_exp(total, survivors)

	# Assert
	assert_eq(result, 333, "AC.2.1: Integer division must floor (1000/3=333), not round (GDD D.1)")


func test_per_unit_exp_zero_survivors_returns_zero() -> void:
	# Arrange — defeat scenario: caller must not invoke on defeat, but defensive guard
	var total: int = 1000
	var survivors: int = 0

	# Act
	var result: int = ExperienceDistribution.per_unit_exp(total, survivors)

	# Assert
	assert_eq(result, 0, "Zero survivors must return 0 (defensive guard against divide-by-zero)")

# ---------------------------------------------------------------------------
# distribute — orchestration / end-to-end
# ---------------------------------------------------------------------------

func test_distribute_end_to_end_perfect_evaluation() -> void:
	# Arrange — BOSS(1000)+NORMAL(50)=1050 base, x1.5=1575, /3 survivors=525
	var tiers: Array = [
		ExperienceDistribution.EnemyTier.BOSS,
		ExperienceDistribution.EnemyTier.NORMAL,
	]
	var survivors: int = 3
	var bonus: float = ExperienceDistribution.EVAL_BONUS["perfect"]  # 0.5

	# Act
	var result: int = ExperienceDistribution.distribute(tiers, survivors, bonus)

	# Assert
	assert_eq(result, 525, "End-to-end: (1000+50)x1.5/3 = 525 per unit (GDD D.1, D.2)")


func test_distribute_defeat_zero_survivors_returns_zero() -> void:
	# Arrange — defeat: rewards_enabled=false, surviving_count=0
	var tiers: Array = [ExperienceDistribution.EnemyTier.NORMAL]
	var survivors: int = 0
	var bonus: float = 0.0

	# Act
	var result: int = ExperienceDistribution.distribute(tiers, survivors, bonus)

	# Assert
	assert_eq(result, 0, "Defeat (0 survivors) must yield 0 EXP per unit (GDD C.1)")

# ---------------------------------------------------------------------------
# apply_with_overflow — GDD E.4 / AC-E2
# ---------------------------------------------------------------------------

func test_ac_e2_overflow_triggers_single_level_up() -> void:
	# Arrange — unit at 900/1000; +500 -> total 1400 -> 1 level-up, 400 residual
	var current: int = 900
	var cap: int = 1000
	var incoming: int = 500

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 1,   "AC-E2: 900+500 against cap 1000 must trigger 1 level-up")
	assert_eq(result["current"],   400, "AC-E2: residual must be 400 after single level-up")
	assert_eq(result["applied"],   500, "AC-E2: applied must equal incoming (500)")


func test_ac_e2_overflow_triggers_multiple_level_ups() -> void:
	# Arrange — unit at 0/100; +250 -> 2 full levels (200), 50 residual
	var current: int = 0
	var cap: int = 100
	var incoming: int = 250

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 2,  "AC-E2: 250 EXP into cap-100 must trigger 2 level-ups")
	assert_eq(result["current"],   50, "AC-E2: residual must be 50 after two level-ups")


func test_ac_e2_no_level_up_when_incoming_fits() -> void:
	# Arrange — unit at 100/1000; +500 -> 600 total, no level-up
	var current: int = 100
	var cap: int = 1000
	var incoming: int = 500

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 0,   "No level-up when total < cap")
	assert_eq(result["current"],   600, "Current must be 600 when no level-up occurs")


func test_ac_e2_exactly_hits_cap_triggers_one_level_up() -> void:
	# Arrange — unit at 500/1000; +500 -> exactly 1000 -> 1 level-up, 0 residual
	var current: int = 500
	var cap: int = 1000
	var incoming: int = 500

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 1, "Exactly hitting cap must trigger 1 level-up")
	assert_eq(result["current"],   0, "Residual must be 0 when EXP lands exactly on cap")


func test_ac_e2_zero_cap_is_defensive_no_op() -> void:
	# Arrange — degenerate: cap=0 would divide by zero; defensive guard must fire
	var current: int = 50
	var cap: int = 0
	var incoming: int = 100

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 0, "cap=0 defensive guard: no level-ups")
	assert_eq(result["applied"],   0, "cap=0 defensive guard: applied must be 0")


func test_ac_e2_negative_incoming_is_defensive_no_op() -> void:
	# Arrange — negative EXP is invalid; must be a no-op
	var current: int = 50
	var cap: int = 100
	var incoming: int = -10

	# Act
	var result: Dictionary = ExperienceDistribution.apply_with_overflow(current, cap, incoming)

	# Assert
	assert_eq(result["level_ups"], 0,  "Negative incoming: no level-ups")
	assert_eq(result["applied"],   0,  "Negative incoming: applied must be 0")
	assert_eq(result["current"],   50, "Negative incoming: current must be unchanged")
