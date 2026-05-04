extends GdUnitTestSuite

const FormulaEngineScript := preload("res://src/systems/core/formula_engine.gd")


func before_test() -> void:
	FormulaEngineScript.clear_all()


func test_value_below_softcap_returns_original_value() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("softcap(value, threshold, power)", {"value": 50.0, "threshold": 100.0, "power": 0.5}) - 50.0) < 0.001).is_true()


func test_lerp_returns_expected_value() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("lerp(a, b, t)", {"a": 0.0, "b": 100.0, "t": 0.3}) - 30.0) < 0.001).is_true()


func test_invalidate_all_clears_cache() -> void:
	FormulaEngineScript.register_formula("simple", "a + 1.0", ["a"])
	assert_bool(abs(FormulaEngineScript.evaluate("simple", {"a": 1.0}) - 2.0) < 0.001).is_true()
	FormulaEngineScript.invalidate_all()
	assert_bool(abs(FormulaEngineScript.evaluate("simple", {"a": 2.0}) - 3.0) < 0.001).is_true()


func test_negative_results_are_allowed() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("a - b", {"a": 3.0, "b": 10.0}) - -7.0) < 0.001).is_true()


func test_softcap_invalid_threshold_degrades_without_crash() -> void:
	var result := FormulaEngineScript.evaluate_raw("softcap(value, threshold, power)", {"value": 200.0, "threshold": -5.0, "power": 1.0})
	assert_bool(result >= 1.0).is_true()

