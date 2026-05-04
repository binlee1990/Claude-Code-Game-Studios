extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")


func test_from_float_normalizes_mantissa_and_exponent() -> void:
	var value := BigNumberScript.from_float(123.456)
	assert_bool(value.mantissa >= 1.0 and value.mantissa < 10.0).is_true()
	assert_int(value.exponent).is_equal(2)


func test_multiply_returns_expected_mantissa_and_exponent() -> void:
	var a := BigNumberScript.new(2.0, 5)
	var b := BigNumberScript.new(3.0, 3)
	var result := a.multiply(b)
	assert_bool(abs(result.mantissa - 6.0) < 0.001).is_true()
	assert_int(result.exponent).is_equal(8)


func test_log10_returns_expected_float() -> void:
	var value := BigNumberScript.new(3.16, 5)
	assert_bool(abs(value.log10() - 5.5) < 0.01).is_true()


func test_subtract_negative_result_clamps_to_zero() -> void:
	var a := BigNumberScript.new(2.0, 3)
	var b := BigNumberScript.new(5.0, 3)
	assert_bool(a.subtract(b).is_zero()).is_true()


func test_exponent_underflow_clamps_to_zero() -> void:
	var a := BigNumberScript.new(5.0, 0)
	var b := BigNumberScript.new(7.0, 0)
	assert_bool(a.divide(b).is_zero()).is_true()


func test_divide_by_zero_returns_max() -> void:
	var a := BigNumberScript.new(2.0, 3)
	assert_bool(a.divide(BigNumberScript.zero()).is_max()).is_true()


func test_overflow_returns_max() -> void:
	var a := BigNumberScript.new(9.9, 308)
	var b := BigNumberScript.new(9.9, 10)
	assert_bool(a.multiply(b).is_max()).is_true()


func test_from_int_42_has_expected_components() -> void:
	var value := BigNumberScript.from_int(42)
	assert_bool(abs(value.mantissa - 4.2) < 0.001).is_true()
	assert_int(value.exponent).is_equal(1)


func test_to_int_returns_plain_integer() -> void:
	var value := BigNumberScript.new(1.0, 2)
	assert_int(value.to_int()).is_equal(100)


func test_to_string_formats_scientific_notation() -> void:
	var value := BigNumberScript.new(1.23, 150)
	assert_str(value.as_string()).is_equal("1.23e150")


func test_comparison_helpers_return_true_for_equal_bounds() -> void:
	var a := BigNumberScript.new(2.0, 3)
	var b := BigNumberScript.new(2.0, 3)
	assert_bool(a.less_or_equal(b)).is_true()
	assert_bool(a.greater_or_equal(b)).is_true()


func test_max_constant_is_saturated() -> void:
	assert_bool(BigNumberScript.MAX.is_max()).is_true()
