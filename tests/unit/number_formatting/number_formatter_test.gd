extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const NumberFormatterScript := preload("res://src/systems/core/number_formatter.gd")


func test_zero_formats_as_zero() -> void:
	assert_str(NumberFormatterScript.format(BigNumberScript.ZERO)).is_equal("0")


func test_direct_number_uses_thousand_separator() -> void:
	assert_str(NumberFormatterScript.format(BigNumberScript.from_int(9999))).is_equal("9,999")


func test_chinese_unit_wan_without_decimals_for_hundreds() -> void:
	assert_str(NumberFormatterScript.format(BigNumberScript.from_int(5670000))).is_equal("567万")


func test_ji_unit_formats_1234() -> void:
	assert_bool(NumberFormatterScript.format(BigNumberScript.new(1.234, 51)) == "1234极").is_true()


func test_max_formats_as_max() -> void:
	assert_str(NumberFormatterScript.format(BigNumberScript.MAX)).is_equal("MAX")


func test_rounding_crosses_to_next_unit() -> void:
	assert_str(NumberFormatterScript.format(BigNumberScript.new(9.9999, 7))).is_equal("1.00亿")


func test_get_display_unit_returns_wan() -> void:
	assert_str(NumberFormatterScript.get_display_unit(BigNumberScript.from_int(15000))).is_equal("万")
