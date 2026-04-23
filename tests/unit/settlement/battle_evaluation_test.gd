# tests/unit/settlement/battle_evaluation_test.gd
# Story BS-003: Battle Evaluation
# Validates AC.3.1 (Excellent), AC.3.2 (Perfect), AC.3.3 (Normal), FAIL path, and defensives.
# GDD reference: battle-settlement.md C.5, D.2.

extends Gut

# ---------------------------------------------------------------------------
# AC.3.2 — Perfect rating (GDD C.5)
# ---------------------------------------------------------------------------

func test_ac_3_2_perfect_no_deaths_no_damage_returns_perfect() -> void:
	# Arrange
	var deaths: int = 0
	var damage: int = 0

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.PERFECT,
		"AC.3.2: 0 deaths + 0 damage must classify as PERFECT (GDD C.5)")


func test_ac_3_2_perfect_bonus_is_50_percent() -> void:
	# Arrange / Act
	var bonus: float = BattleEvaluation.bonus_for(BattleEvaluation.Rating.PERFECT)

	# Assert
	assert_almost_eq(bonus, 0.5, 0.0001,
		"AC.3.2: PERFECT bonus must be 0.5 (+50% EXP) (GDD C.5, D.2)")

# ---------------------------------------------------------------------------
# AC.3.1 — Excellent rating (GDD C.5)
# ---------------------------------------------------------------------------

func test_ac_3_1_excellent_no_deaths_with_damage_returns_excellent() -> void:
	# Arrange
	var deaths: int = 0
	var damage: int = 100

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.EXCELLENT,
		"AC.3.1: 0 deaths + damage taken must classify as EXCELLENT (GDD C.5)")


func test_ac_3_1_excellent_bonus_is_20_percent() -> void:
	# Arrange / Act
	var bonus: float = BattleEvaluation.bonus_for(BattleEvaluation.Rating.EXCELLENT)

	# Assert
	assert_almost_eq(bonus, 0.2, 0.0001,
		"AC.3.1: EXCELLENT bonus must be 0.2 (+20% EXP) (GDD C.5, D.2)")


func test_ac_3_1_excellent_edge_minimal_damage_still_excellent() -> void:
	# Arrange — GDD edge case: 1 HP lost still counts as damage taken, not Perfect
	var deaths: int = 0
	var damage: int = 1

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.EXCELLENT,
		"AC.3.1 edge: 1 damage taken must be EXCELLENT, not PERFECT (GDD C.5 QA)")

# ---------------------------------------------------------------------------
# AC.3.3 — Normal rating (GDD C.5)
# ---------------------------------------------------------------------------

func test_ac_3_3_normal_one_death_returns_normal() -> void:
	# Arrange — death even with 0 damage (e.g. instant-kill mechanic)
	var deaths: int = 1
	var damage: int = 0

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.NORMAL,
		"AC.3.3: Any death must classify as NORMAL, death check precedes damage check (GDD C.5)")


func test_ac_3_3_normal_multiple_deaths_and_damage_returns_normal() -> void:
	# Arrange
	var deaths: int = 3
	var damage: int = 500

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.NORMAL,
		"AC.3.3: Multiple deaths + heavy damage must classify as NORMAL (GDD C.5)")


func test_ac_3_3_normal_bonus_is_zero() -> void:
	# Arrange / Act
	var bonus: float = BattleEvaluation.bonus_for(BattleEvaluation.Rating.NORMAL)

	# Assert
	assert_almost_eq(bonus, 0.0, 0.0001,
		"AC.3.3: NORMAL bonus must be 0.0 (no EXP modifier) (GDD C.5)")

# ---------------------------------------------------------------------------
# FAIL rating — defeat path (GDD C.5)
# ---------------------------------------------------------------------------

func test_fail_is_defeat_flag_true_returns_fail() -> void:
	# Arrange — is_defeat=true overrides even perfect-looking inputs
	var deaths: int = 0
	var damage: int = 0

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage, true)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.FAIL,
		"FAIL: is_defeat=true must force FAIL regardless of deaths/damage (GDD C.5)")


func test_fail_bonus_is_zero() -> void:
	# Arrange / Act
	var bonus: float = BattleEvaluation.bonus_for(BattleEvaluation.Rating.FAIL)

	# Assert
	assert_almost_eq(bonus, 0.0, 0.0001,
		"FAIL: FAIL rating bonus must be 0.0 (defeat yields no EXP) (GDD C.5)")

# ---------------------------------------------------------------------------
# evaluate — orchestration helper
# ---------------------------------------------------------------------------

func test_evaluate_returns_rating_and_bonus_dict_for_perfect() -> void:
	# Arrange
	var deaths: int = 0
	var damage: int = 0

	# Act
	var result: Dictionary = BattleEvaluation.evaluate(deaths, damage)

	# Assert
	assert_eq(result["rating"], BattleEvaluation.Rating.PERFECT,
		"evaluate: perfect inputs must yield rating=PERFECT in dict")
	assert_almost_eq(result["bonus"], 0.5, 0.0001,
		"evaluate: perfect inputs must yield bonus=0.5 in dict")


func test_evaluate_defeat_flag_returns_fail_dict() -> void:
	# Arrange — is_defeat overrides all inputs
	var deaths: int = 0
	var damage: int = 0

	# Act
	var result: Dictionary = BattleEvaluation.evaluate(deaths, damage, true)

	# Assert
	assert_eq(result["rating"], BattleEvaluation.Rating.FAIL,
		"evaluate: is_defeat=true must yield rating=FAIL in dict")
	assert_almost_eq(result["bonus"], 0.0, 0.0001,
		"evaluate: is_defeat=true must yield bonus=0.0 in dict")

# ---------------------------------------------------------------------------
# Defensive — unknown rating
# ---------------------------------------------------------------------------

func test_bonus_for_unknown_rating_returns_zero() -> void:
	# Arrange — sentinel value outside enum range
	var unknown_rating: int = 999

	# Act
	var bonus: float = BattleEvaluation.bonus_for(unknown_rating)

	# Assert
	assert_almost_eq(bonus, 0.0, 0.0001,
		"bonus_for: unknown rating int must return 0.0 defensively (Dictionary.get fallback)")

# ---------------------------------------------------------------------------
# Priority order — death check precedes damage check (GDD C.5)
# ---------------------------------------------------------------------------

func test_classify_death_beats_zero_damage_confirms_priority() -> void:
	# Arrange — death=1, damage=0: if damage were checked first this would be PERFECT
	var deaths: int = 1
	var damage: int = 0

	# Act
	var result: int = BattleEvaluation.classify(deaths, damage)

	# Assert
	assert_eq(result, BattleEvaluation.Rating.NORMAL,
		"Priority: death check must precede damage check — 1 death + 0 damage = NORMAL, not PERFECT")
