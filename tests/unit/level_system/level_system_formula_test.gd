extends GdUnitTestSuite

const LevelSystemScript := preload("res://src/systems/features/level_system.gd")


func before_test() -> void:
	FormulaEngine.clear_all()
	LevelSystemScript.new()


func test_default_level_and_growth_formulas() -> void:
	assert_int(int(round(FormulaEngine.evaluate("level_exp", {"level": 1}) * 10.0))).is_equal(104)
	var high_exp := FormulaEngine.evaluate("level_exp", {"level": 99})
	assert_bool(high_exp > 1900000.0 and high_exp < 2900000.0).is_true()
	assert_int(int(round(FormulaEngine.evaluate("hp_max_growth", {"level": 1, "realm_id": 0})))).is_equal(100)
	var hp_high := FormulaEngine.evaluate("hp_max_growth", {"level": 200, "realm_id": 6})
	assert_bool(hp_high >= 100000.0 and hp_high <= 150000.0).is_true()
	var crit := FormulaEngine.evaluate("crit_rate_growth", {"level": 200, "realm_id": 6})
	assert_bool(crit >= 0.30 and crit <= 0.45 and crit <= 1.0).is_true()
