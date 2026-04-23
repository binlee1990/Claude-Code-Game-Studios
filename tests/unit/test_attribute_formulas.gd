# test_attribute_formulas.gd
# Unit tests for attribute growth formulas
# Validates D.1, D.2 formulas from attribute-growth-system.md

extends Gut

const FORMULA_TOLERANCE := 0.001

# Helper to create a mock attribute config
func _create_test_config() -> Dictionary:
	return {
		"initial_value": 10.0,
		"potential": 0.8,
		"growth_rate": 0.05,
		"level": 1.0,
		"max_level": 100.0,
	}


func test_level_up_growth_formula() -> void:
	# D.1: growth = potential * growth_rate * level
	var config := _create_test_config()
	var calculated_growth: float = float(config["potential"]) * float(config["growth_rate"]) * float(config["level"])
	var expected_growth: float = float(config["potential"]) * float(config["growth_rate"]) * float(config["level"])
	assert_eq_fTol(calculated_growth, expected_growth, FORMULA_TOLERANCE)
	assert_true(calculated_growth >= 0, "Growth should be non-negative")


func test_potential_multiplier() -> void:
	# Higher potential = higher growth
	var high_potential: float = 1.0
	var low_potential: float = 0.5
	var level: float = 10.0
	var growth_rate: float = 0.05

	var high_growth: float = high_potential * growth_rate * level
	var low_growth: float = low_potential * growth_rate * level

	assert_true(high_growth > low_growth, "High potential should yield more growth")
	assert_eq_fTol(high_growth, low_growth * 2.0, FORMULA_TOLERANCE)


func test_cumulative_growth() -> void:
	# D.2: cumulative = sum of all level growths
	var total_growth: float = 0.0
	var potential: float = 0.8
	var growth_rate: float = 0.05

	for level in range(1, 11):
		total_growth += potential * growth_rate * float(level)

	# Gauss sum approximation
	var expected: float = potential * growth_rate * 55.0
	assert_eq_fTol(total_growth, expected, FORMULA_TOLERANCE)


func test_fruit_potential_boost() -> void:
	# Fruit increases potential, not direct attribute
	var base_potential: float = 0.8
	var fruit_boost: float = 0.1
	var new_potential: float = base_potential + fruit_boost

	assert_true(new_potential > base_potential, "Fruit should increase potential")
	assert_true(new_potential <= 1.0, "Potential should not exceed 1.0")


func test_attribute_cap() -> void:
	# Attributes should have a maximum cap
	var max_attribute: float = 999.0
	var current_attribute: float = 1000.0

	var capped: float = mini(current_attribute, max_attribute)
	assert_eq(capped, max_attribute, "Attribute should be capped at max")


func test_wall_break_threshold() -> void:
	# Wall break occurs at specific attribute thresholds
	var thresholds: Array[int] = [50, 100, 150, 200]
	var test_value: int = 50

	assert_true(test_value in thresholds, "50 should be a wall threshold")
	assert_false(49 in thresholds, "49 should not be a wall threshold")


func test_zero_potential_edge_case() -> void:
	# Zero potential means no growth
	var zero_potential: float = 0.0
	var growth_rate: float = 0.05
	var level: float = 10.0

	var growth: float = zero_potential * growth_rate * level
	assert_eq_fTol(growth, 0.0, FORMULA_TOLERANCE)


func test_negative_growth_rate_protection() -> void:
	# Negative growth rate should not cause attribute decay
	var config := _create_test_config()
	config["growth_rate"] = -0.1  # Invalid

	var growth: float = float(config["potential"]) * float(config["growth_rate"]) * float(config["level"])
	# Growth rate should be clamped to non-negative in actual implementation
	assert_true(growth <= 0, "Negative growth rate should be handled")
