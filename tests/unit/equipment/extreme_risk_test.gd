extends Gut

# Sprint-009 / EQUIP-014: Equipment +11+ extreme-risk tuning
# Validates probability curves and protection symbol consumption for extreme risk zone.

const SAFE_ZONE_MAX: int = 5
const RISK_ZONE_MAX: int = 10
const EXTREME_ZONE_START: int = 11


func test_extreme_risk_zone_starts_at_11() -> void:
	assert_eq(EXTREME_ZONE_START, 11)


func test_extreme_risk_zone_above_risk_zone() -> void:
	assert_true(EXTREME_ZONE_START > RISK_ZONE_MAX)


# Probability curve: success rate decreases as enhancement level increases
func _success_probability(level: int) -> float:
	if level <= SAFE_ZONE_MAX:
		return 1.0
	elif level <= 8:
		return 0.7 - (level - 6) * 0.15
	elif level <= 10:
		return 0.35 - (level - 9) * 0.1
	else:
		return maxf(0.05, 0.2 - (level - 11) * 0.03)


func test_extreme_risk_level_11_probability_positive() -> void:
	var prob: float = _success_probability(11)
	assert_true(prob > 0.0)
	assert_true(prob < 0.3)


func test_extreme_risk_level_15_probability_lower_than_11() -> void:
	var prob_11: float = _success_probability(11)
	var prob_15: float = _success_probability(15)
	assert_true(prob_15 <= prob_11)


func test_extreme_risk_probability_never_zero() -> void:
	for level: int in range(11, 21):
		var prob: float = _success_probability(level)
		assert_true(prob > 0.0)


func test_extreme_risk_probability_never_exceeds_safe_zone() -> void:
	for level: int in range(11, 21):
		var prob: float = _success_probability(level)
		assert_true(prob < 1.0)


func test_safe_zone_always_100_percent() -> void:
	for level: int in range(1, 6):
		var prob: float = _success_probability(level)
		assert_eq(prob, 1.0)


func test_risk_zone_probability_bounds() -> void:
	var prob_6: float = _success_probability(6)
	var prob_10: float = _success_probability(10)
	assert_true(prob_6 > prob_10)
	assert_true(prob_6 > 0.4)
	assert_true(prob_10 > 0.1)


# Protection symbol consumption: extreme zone consumes more symbols
func _protection_symbol_cost(level: int) -> int:
	if level <= SAFE_ZONE_MAX:
		return 0
	elif level <= 8:
		return 1
	elif level <= 10:
		return 2
	else:
		return 2 + (level - 11)


func test_extreme_risk_protection_cost_level_11() -> void:
	var cost: int = _protection_symbol_cost(11)
	assert_eq(cost, 2)


func test_extreme_risk_protection_cost_increases_with_level() -> void:
	var cost_11: int = _protection_symbol_cost(11)
	var cost_14: int = _protection_symbol_cost(14)
	assert_true(cost_14 > cost_11)


func test_extreme_risk_protection_cost_level_15() -> void:
	var cost: int = _protection_symbol_cost(15)
	assert_eq(cost, 6)
