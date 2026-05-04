extends GdUnitTestSuite

const FormulaEngineScript := preload("res://src/systems/core/formula_engine.gd")


func before_test() -> void:
	FormulaEngineScript.clear_all()


func test_registered_formula_returns_expected_value() -> void:
	FormulaEngineScript.register_formula("lingqi_rate", "base_rate * (1.0 + level * 0.1)", ["base_rate", "level"])
	assert_bool(abs(FormulaEngineScript.evaluate("lingqi_rate", {"base_rate": 10.0, "level": 5.0}) - 15.0) < 0.001).is_true()


func test_raw_expression_respects_operator_precedence() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("a + b * c", {"a": 1.0, "b": 2.0, "c": 3.0}) - 7.0) < 0.001).is_true()


func test_extra_variables_are_ignored() -> void:
	FormulaEngineScript.register_formula("atk_only", "atk + 20.0", ["atk"])
	assert_bool(abs(FormulaEngineScript.evaluate("atk_only", {"atk": 100.0, "spd": 50.0}) - 120.0) < 0.001).is_true()


func test_bad_formula_returns_zero_and_is_cached_as_error() -> void:
	FormulaEngineScript.register_formula("bad", "a + * b", ["a", "b"])
	assert_bool(abs(FormulaEngineScript.evaluate("bad", {"a": 1.0, "b": 2.0}) - 0.0) < 0.001).is_true()
	assert_bool(abs(FormulaEngineScript.evaluate("bad", {"a": 1.0, "b": 2.0}) - 0.0) < 0.001).is_true()


func test_boolean_result_converts_to_float() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("x > 5", {"x": 10.0}) - 1.0) < 0.001).is_true()


func test_softcap_returns_expected_value() -> void:
	assert_bool(abs(FormulaEngineScript.evaluate_raw("softcap(value, threshold, power)", {"value": 500.0, "threshold": 100.0, "power": 0.5}) - 120.0) < 0.001).is_true()

