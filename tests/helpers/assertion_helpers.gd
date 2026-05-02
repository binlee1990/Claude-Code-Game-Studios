# Assertion helpers for SRPG test suite.
# Preload in test files: const Assert = preload("res://tests/helpers/assertion_helpers.gd")

class_name AssertionHelpers
extends RefCounted

## Assert that two float values are approximately equal within epsilon.
static func assert_float_eq(a: float, b: float, epsilon: float = 0.0001, context: String = "") -> bool:
	var diff := abs(a - b)
	if diff > epsilon:
		var msg := "Expected %s ≈ %s, diff=%s" % [str(a), str(b), str(diff)]
		if context:
			msg += " [%s]" % context
		GutUtils.assertion_failed(msg)
		return false
	return true

## Assert that value is within [low, high] inclusive.
static func assert_in_range(value: float, low: float, high: float, context: String = "") -> bool:
	if value < low or value > high:
		var msg := "Expected %s in [%s, %s]" % [str(value), str(low), str(high)]
		if context:
			msg += " [%s]" % context
		GutUtils.assertion_failed(msg)
		return false
	return true

## Assert that two dictionaries have the same keys and values (shallow).
static func assert_dict_eq(a: Dictionary, b: Dictionary, context: String = "") -> bool:
	if a.keys() != b.keys():
		var msg := "Dict keys differ: %s vs %s" % [str(a.keys()), str(b.keys())]
		if context:
			msg += " [%s]" % context
		GutUtils.assertion_failed(msg)
		return false
	for key in a:
		if a[key] != b[key]:
			var msg := "Dict[%s] differs: %s vs %s" % [str(key), str(a[key]), str(b[key])]
			if context:
				msg += " [%s]" % context
			GutUtils.assertion_failed(msg)
			return false
	return true

## Assert that a signal was emitted (helper for signal tracking).
static func assert_signal_emitted(signal_tracker: Object, signal_name: String, context: String = "") -> bool:
	if not signal_tracker.has_signal_been_emitted(signal_name):
		var msg := "Signal '%s' was not emitted" % signal_name
		if context:
			msg += " [%s]" % context
		GutUtils.assertion_failed(msg)
		return false
	return true

## Assert that array has expected length.
static func assert_len(arr: Array, expected: int, context: String = "") -> bool:
	if arr.size() != expected:
		var msg := "Expected array length %d, got %d" % [expected, arr.size()]
		if context:
			msg += " [%s]" % context
		GutUtils.assertion_failed(msg)
		return false
	return true
