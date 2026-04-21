# Minimal GUT stub — provides compile-time base class for test scripts.
# Delete this file after installing the real GUT addon (res://addons/gut/).
class_name Gut
extends Node

var _test_dirs: PackedStringArray = []

func add_directory(path: String) -> void:
	_test_dirs.append(path)

func set_include_subdirectories(_enabled: bool) -> void:
	pass

func run_tests() -> void:
	for dir in _test_dirs:
		print("GUT stub: would scan %s" % dir)

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		push_error("assert_eq failed: %s (got %s, expected %s)" % [msg, str(actual), str(expected)])

func assert_true(condition: bool, msg: String = "") -> void:
	if not condition:
		push_error("assert_true failed: %s" % msg)

func assert_false(condition: bool, msg: String = "") -> void:
	if condition:
		push_error("assert_false failed: %s" % msg)

func assert_almost_eq(actual: float, expected: float, tolerance: float, msg: String = "") -> void:
	if absf(actual - expected) > tolerance:
		push_error("assert_almost_eq failed: %s (got %s, expected %s ± %s)" % [msg, str(actual), str(expected), str(tolerance)])

func before_each() -> void:
	pass

func after_each() -> void:
	pass
