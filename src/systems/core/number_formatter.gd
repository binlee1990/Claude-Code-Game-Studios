class_name NumberFormatter
extends RefCounted

const CHINESE_UNITS := ["万", "亿", "兆", "京", "垓", "秭", "穰", "沟", "涧", "正", "载", "极"]
const SCIENTIFIC_THRESHOLD := 52
const THOUSAND_SEPARATOR := ","
const MAX_FORMAT_CACHE_SIZE := 2048
const SMALL_POWERS := [1.0, 10.0, 100.0, 1000.0]

static var _format_cache := {}


## Formats a BigNumber using direct, Chinese-unit, or scientific notation.
static func format(value: BigNumber) -> String:
	if value == null or is_nan(value.mantissa) or is_inf(value.mantissa):
		return "0"
	if value.is_zero():
		return "0"
	if value.is_max():
		return "MAX"
	var cache_key := Vector2(value.mantissa, float(value.exponent))
	var cached: Variant = _format_cache.get(cache_key)
	if cached != null:
		return cached
	var formatted := ""
	if value.exponent < 4:
		var plain_value := int(round(value.mantissa * SMALL_POWERS[value.exponent]))
		if plain_value >= 10000:
			formatted = _format_plain_large_int(plain_value)
		else:
			formatted = _add_thousand_separators(plain_value)
	else:
		formatted = _format_large(value)
	_store_format_cache(cache_key, formatted)
	return formatted


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
	var threshold := int(value.exponent / 4) * 4
	if threshold < 4:
		return ""
	if threshold > 48:
		return "e"
	return CHINESE_UNITS[int((threshold - 4) / 4)]


static func _format_large(value: BigNumber) -> String:
	if value.exponent >= SCIENTIFIC_THRESHOLD:
		return format_scientific(value)
	var threshold := int(value.exponent / 4) * 4
	var display_mantissa := value.mantissa * _small_power_of_ten(value.exponent - threshold)
	var decimals := _decimals_for(display_mantissa)
	var rounded := _round_to_decimals(display_mantissa, decimals)
	if rounded >= 10000.0:
		threshold += 4
		if threshold > 48:
			return "1.00e%d" % threshold
		display_mantissa = max(1.0, value.mantissa * _small_power_of_ten(value.exponent - threshold))
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
	var scale := _small_power_of_ten(decimals)
	return round(value * scale) / scale


static func _small_power_of_ten(exponent: int) -> float:
	if exponent >= 0 and exponent < SMALL_POWERS.size():
		return SMALL_POWERS[exponent]
	return pow(10.0, exponent)


static func _format_plain_large_int(value: int) -> String:
	var exponent := 0
	var mantissa := float(value)
	while mantissa >= 10.0:
		mantissa /= 10.0
		exponent += 1
	return _format_large(BigNumber.new(mantissa, exponent))


static func _add_thousand_separators(value: int) -> String:
	var text := str(value)
	var length := text.length()
	if length <= 3:
		return text
	var first_group := length % 3
	var parts := []
	if first_group > 0:
		parts.append(text.substr(0, first_group))
	for index in range(first_group, length, 3):
		parts.append(text.substr(index, 3))
	return THOUSAND_SEPARATOR.join(parts)


static func _store_format_cache(key: Variant, value: String) -> void:
	if _format_cache.size() >= MAX_FORMAT_CACHE_SIZE:
		_format_cache.clear()
	_format_cache[key] = value
