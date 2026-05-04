extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")


func test_big_number_bulk_arithmetic_stays_under_frame_budget() -> void:
	var values := []
	for i in range(1000):
		values.append(BigNumberScript.from_int(i + 1))
	var start := Time.get_ticks_usec()
	for value in values:
		var result := value.add(BigNumberScript.ONE)
		result = result.subtract(BigNumberScript.ONE)
		result = result.multiply(BigNumberScript.new(2.0, 0))
		result = result.divide(BigNumberScript.new(2.0, 0))
		result = result.power(1.0)
		assert_bool(result.greater_or_equal(BigNumberScript.ZERO)).is_true()
	var elapsed_ms := float(Time.get_ticks_usec() - start) / 1000.0
	assert_bool(elapsed_ms < 16.6).is_true()

