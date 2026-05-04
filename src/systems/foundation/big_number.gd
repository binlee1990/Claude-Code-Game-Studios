class_name BigNumber
extends RefCounted

const MAX_EXPONENT := 308
const MAX_MANTISSA := 9.999999999999999
const ADDITION_PRECISION_DIGITS := 15
const POWER_EXPONENT_CAP := 100.0
const EPSILON := 0.000001

static var ZERO: BigNumber = BigNumber.new(0.0, 0)
static var ONE: BigNumber = BigNumber.new(1.0, 0)
static var MAX: BigNumber = BigNumber.new(MAX_MANTISSA, MAX_EXPONENT)

var mantissa: float = 0.0
var exponent: int = 0


func _init(initial_mantissa: float = 0.0, initial_exponent: int = 0) -> void:
	_apply_normalized(initial_mantissa, initial_exponent)


## Creates a zero BigNumber value.
static func zero() -> BigNumber:
	return BigNumber.new(0.0, 0)


## Creates a one BigNumber value.
static func one() -> BigNumber:
	return BigNumber.new(1.0, 0)


## Creates the saturated maximum BigNumber value.
static func max_value() -> BigNumber:
	return BigNumber.new(MAX_MANTISSA, MAX_EXPONENT)


## Creates a BigNumber from a non-negative integer.
static func from_int(value: int) -> BigNumber:
	if value <= 0:
		return BigNumber.zero()
	return BigNumber.from_float(float(value))


## Creates a BigNumber from a non-negative float.
static func from_float(value: float) -> BigNumber:
	if is_nan(value) or value <= 0.0:
		return BigNumber.zero()
	if value < 1.0:
		return BigNumber.zero()
	if is_inf(value):
		return BigNumber.max_value()
	var calculated_exponent := int(floor(log(value) / log(10.0)))
	var calculated_mantissa := value / pow(10.0, calculated_exponent)
	return BigNumber.new(calculated_mantissa, calculated_exponent)


## Parses decimal or scientific notation into a BigNumber.
static func from_string(value: String) -> BigNumber:
	var text := value.strip_edges().replace(",", "")
	if text.is_empty() or text.begins_with("-"):
		return BigNumber.zero()
	var lower := text.to_lower()
	if lower.find("e") >= 0:
		var parts := lower.split("e", false)
		if parts.size() != 2 or not parts[0].is_valid_float() or not parts[1].is_valid_int():
			return BigNumber.zero()
		var parsed_mantissa := parts[0].to_float()
		var parsed_exponent := parts[1].to_int()
		return BigNumber.new(parsed_mantissa, parsed_exponent)
	if not text.is_valid_float():
		return BigNumber.zero()
	return BigNumber.from_float(text.to_float())


## Restores a BigNumber from the canonical dictionary shape {"m": float, "e": int}.
static func from_dict(data: Dictionary) -> BigNumber:
	if not data.has("m") or not data.has("e"):
		return BigNumber.zero()
	return BigNumber.new(float(data["m"]), int(data["e"]))


## Returns the lower of two BigNumber values.
static func min_value(a: BigNumber, b: BigNumber) -> BigNumber:
	if a.compare(b) <= 0:
		return a.copy()
	return b.copy()


## Returns the higher of two BigNumber values.
static func max_pair(a: BigNumber, b: BigNumber) -> BigNumber:
	if a.compare(b) >= 0:
		return a.copy()
	return b.copy()


## Returns an immutable copy of this value.
func copy() -> BigNumber:
	return BigNumber.new(mantissa, exponent)


## Adds another BigNumber using exponent alignment and saturated arithmetic.
func add(other: BigNumber) -> BigNumber:
	if is_max() or other.is_max():
		return BigNumber.max_value()
	if is_zero():
		return other.copy()
	if other.is_zero():
		return copy()
	var diff := exponent - other.exponent
	if abs(diff) > ADDITION_PRECISION_DIGITS:
		if compare(other) >= 0:
			return copy()
		return other.copy()
	if diff >= 0:
		return BigNumber.new(mantissa + other.mantissa * pow(10.0, -diff), exponent)
	return BigNumber.new(other.mantissa + mantissa * pow(10.0, diff), other.exponent)


## Subtracts another BigNumber and clamps negative results to ZERO.
func subtract(other: BigNumber) -> BigNumber:
	if compare(other) <= 0:
		return BigNumber.zero()
	var diff := exponent - other.exponent
	if abs(diff) > ADDITION_PRECISION_DIGITS:
		return copy()
	return BigNumber.new(mantissa - other.mantissa * pow(10.0, -diff), exponent)


## Multiplies two BigNumber values and saturates overflow to MAX.
func multiply(other: BigNumber) -> BigNumber:
	if is_zero() or other.is_zero():
		return BigNumber.zero()
	if is_max() or other.is_max():
		return BigNumber.max_value()
	return BigNumber.new(mantissa * other.mantissa, exponent + other.exponent)


## Multiplies this BigNumber by a non-negative float.
func multiply_float(value: float) -> BigNumber:
	if _is_invalid_float(value) or value <= 0.0 or is_zero():
		return BigNumber.zero()
	if is_max():
		return BigNumber.max_value()
	return BigNumber.new(mantissa * value, exponent)


## Divides by another BigNumber; division by zero saturates to MAX.
func divide(other: BigNumber) -> BigNumber:
	if other.is_zero():
		return BigNumber.max_value()
	if is_zero():
		return BigNumber.zero()
	return BigNumber.new(mantissa / other.mantissa, exponent - other.exponent)


## Raises this BigNumber to a clamped non-negative exponent.
func power(power_value: float) -> BigNumber:
	if _is_invalid_float(power_value) or power_value < 0.0:
		return BigNumber.zero()
	if power_value > POWER_EXPONENT_CAP:
		power_value = POWER_EXPONENT_CAP
	if power_value == 0.0:
		return BigNumber.one()
	if power_value == 1.0:
		return copy()
	if is_zero():
		return BigNumber.zero()
	var total_log := log10() * power_value
	var result_exponent := int(floor(total_log))
	var result_mantissa := pow(10.0, total_log - result_exponent)
	return BigNumber.new(result_mantissa, result_exponent)


## Returns the base-10 logarithm as a float; zero maps to 0.0 for game logic.
func log10() -> float:
	if is_zero():
		return 0.0
	return log(mantissa) / log(10.0) + float(exponent)


## Compares this value with another BigNumber. Returns -1, 0, or 1.
func compare(other: BigNumber) -> int:
	if exponent < other.exponent:
		return -1
	if exponent > other.exponent:
		return 1
	if abs(mantissa - other.mantissa) <= EPSILON:
		return 0
	if mantissa < other.mantissa:
		return -1
	return 1


## Returns true when both values represent the same normalized quantity.
func equals(other: BigNumber) -> bool:
	return compare(other) == 0


## Returns true when this value is lower than another.
func less_than(other: BigNumber) -> bool:
	return compare(other) < 0


## Returns true when this value is greater than another.
func greater_than(other: BigNumber) -> bool:
	return compare(other) > 0


## Returns true when this value is lower than or equal to another.
func less_or_equal(other: BigNumber) -> bool:
	return compare(other) <= 0


## Returns true when this value is greater than or equal to another.
func greater_or_equal(other: BigNumber) -> bool:
	return compare(other) >= 0


## Serializes this value into the canonical dictionary shape.
func to_dict() -> Dictionary:
	return {"m": mantissa, "e": exponent}


## Converts this value to an int, saturating very large values.
func to_int() -> int:
	if is_zero():
		return 0
	if exponent > 18:
		return 9223372036854775807
	return int(round(to_float()))


## Converts this value to a float, using MAX for saturated values.
func to_float() -> float:
	if is_zero():
		return 0.0
	if is_max():
		return INF
	return mantissa * pow(10.0, exponent)


## Formats this value as plain text for small values or scientific notation for large values.
func as_string() -> String:
	if is_zero():
		return "0"
	if is_max():
		return "MAX"
	if exponent == 0:
		if abs(mantissa - round(mantissa)) <= EPSILON:
			return str(int(round(mantissa)))
		return "%.2f" % mantissa
	return "%.2fe%d" % [mantissa, exponent]


## Returns true when this value is exactly zero.
func is_zero() -> bool:
	return mantissa == 0.0 and exponent == 0


## Returns true when this value is the saturated maximum.
func is_max() -> bool:
	return exponent == MAX_EXPONENT and mantissa >= 9.998


## Returns the exponent magnitude used by display and comparison systems.
func magnitude() -> int:
	return exponent


## Clamps this value into the inclusive range.
func clamp_value(minimum: BigNumber, maximum: BigNumber) -> BigNumber:
	if compare(minimum) < 0:
		return minimum.copy()
	if compare(maximum) > 0:
		return maximum.copy()
	return copy()


func _apply_normalized(raw_mantissa: float, raw_exponent: int) -> void:
	if _is_invalid_float(raw_mantissa) or raw_mantissa <= 0.0:
		mantissa = 0.0
		exponent = 0
		return
	var next_mantissa := raw_mantissa
	var next_exponent := raw_exponent
	while next_mantissa >= 10.0:
		next_mantissa /= 10.0
		next_exponent += 1
	while next_mantissa < 1.0 and next_mantissa > 0.0:
		next_mantissa *= 10.0
		next_exponent -= 1
	if next_exponent > MAX_EXPONENT:
		mantissa = MAX_MANTISSA
		exponent = MAX_EXPONENT
		return
	if next_exponent < 0:
		mantissa = 0.0
		exponent = 0
		return
	mantissa = next_mantissa
	exponent = next_exponent


static func _is_invalid_float(value: float) -> bool:
	return is_nan(value) or is_inf(value)
