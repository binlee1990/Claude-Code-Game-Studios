extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const NumberFormatterScript := preload("res://src/systems/core/number_formatter.gd")


func test_one_thousand_format_calls_stay_under_one_ms() -> void:
	var values := []
	for i in range(1000):
		values.append(BigNumberScript.new(1.234 + float(i % 8), i % 80))
	var start := Time.get_ticks_usec()
	for value in values:
		NumberFormatterScript.format(value)
	var elapsed_ms := float(Time.get_ticks_usec() - start) / 1000.0
	assert_bool(elapsed_ms < 1.0).is_true()

