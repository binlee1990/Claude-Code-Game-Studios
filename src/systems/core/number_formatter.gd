class_name NumberFormatter
extends RefCounted

const CHINESE_UNITS := ["万", "亿", "兆", "京", "垓", "秭", "穰", "沟", "涧", "正", "载", "极"]
const SCIENTIFIC_THRESHOLD := 52
const THOUSAND_SEPARATOR := ","


## Formats a BigNumber using direct, Chinese-unit, or scientific notation.
static func format(value: BigNumber) -> String:
	if value == null or is_nan(value.mantissa) or is_inf(value.mantissa):
		return "0"
	if value.is_zero():
		return "0"
	if value.is_max():
		return "MAX"
	if value.exponent < 4:
		var plain_value := int(round(value.mantissa * pow(10.0, value.exponent)))
		if plain_value >= 10000:
			return format(BigNumber.from_int(plain_value))
		return _add_thousand_separators(plain_value)
	return _format_large(value)


## Formats a BigNumber using scientific notation regardless of size.
static func format_scientific(value: BigNumber) -> String:
	if value == null or value.is_zero():
		return "0"
	if value.is_max():
		return "MAX"
	return "%.2fe%d" % [value.mantissa, value.exponent]


## Formats a small BigNumber as raw direct digits; large values fall back to scientific notation.
static func format_raw(value: BigNumber) -> String:
	if value == null or value.is_zero():
		return "0"
	if value.exponent >= 15:
		return format_scientific(value)
	return _add_thousand_separators(int(round(value.to_float())))


## Returns the display unit suffix for a BigNumber.
static func get_display_unit(value: BigNumber) -> String:
	if value == null or value.is_zero() or value.is_max():
		return ""
	if value.exponent < 4:
		return ""
	if value.exponent >= SCIENTIFIC_THRESHOLD:
		return "e"
	var threshold := int(floor(float(value.exponent) / 4.0)) * 4
	if threshold < 4:
		return ""
	if threshold > 48:
		return "e"
	return CHINESE_UNITS[int((threshold - 4) / 4)]


static func _format_large(value: BigNumber) -> String:
	if value.exponent >= SCIENTIFIC_THRESHOLD:
		return format_scientific(value)
	var threshold := int(floor(float(value.exponent) / 4.0)) * 4
	var display_mantissa := value.mantissa * pow(10.0, value.exponent - threshold)
	var decimals := _decimals_for(display_mantissa)
	var rounded := _round_to_decimals(display_mantissa, decimals)
	if rounded >= 10000.0:
		threshold += 4
		if threshold > 48:
			return "1.00e%d" % threshold
		display_mantissa = max(1.0, value.mantissa * pow(10.0, value.exponent - threshold))
		decimals = _decimals_for(display_mantissa)
	if threshold < 4:
		return format(BigNumber.from_int(int(round(value.to_float()))))
	var unit_index := int((threshold - 4) / 4)
	var unit: String = CHINESE_UNITS[unit_index]
	return _format_with_decimals(display_mantissa, decimals) + unit


static func _decimals_for(display_mantissa: float) -> int:
	if display_mantissa < 10.0:
		return 2
	if display_mantissa < 100.0:
		return 1
	return 0


static func _format_with_decimals(value: float, decimals: int) -> String:
	match decimals:
		0:
			return str(int(round(value)))
		1:
			return "%.1f" % value
		_:
			return "%.2f" % value


static func _round_to_decimals(value: float, decimals: int) -> float:
	var scale := pow(10.0, decimals)
	return round(value * scale) / scale


static func _add_thousand_separators(value: int) -> String:
	var text := str(value)
	var result := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = THOUSAND_SEPARATOR + result
		result = text.substr(i, 1) + result
		count += 1
	return result
