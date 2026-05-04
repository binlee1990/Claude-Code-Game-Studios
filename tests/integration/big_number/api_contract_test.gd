extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")


func test_big_number_public_api_contract_exists() -> void:
	var value := BigNumberScript.from_int(42)
	assert_bool(value.has_method("add")).is_true()
	assert_bool(value.has_method("subtract")).is_true()
	assert_bool(value.has_method("multiply")).is_true()
	assert_bool(value.has_method("multiply_float")).is_true()
	assert_bool(value.has_method("divide")).is_true()
	assert_bool(value.has_method("power")).is_true()
	assert_bool(value.has_method("log10")).is_true()
	assert_bool(value.has_method("to_dict")).is_true()


func test_dict_round_trip_preserves_value() -> void:
	var original := BigNumberScript.new(1.23, 150)
	var restored := BigNumberScript.from_dict(original.to_dict())
	assert_bool(restored.equals(original)).is_true()

