# Mock helpers for SRPG test suite.
# Preload in test files: const Mock = preload("res://tests/helpers/mock_helpers.gd")

class_name MockHelpers
extends RefCounted

## SignalTracker — lightweight signal emission counter for testing.
## Usage:
##   var tracker := Mock.SignalTracker.new()
##   obj.some_signal.connect(tracker._on_signal)
##   ...trigger...
##   assert_eq(tracker.emit_count("some_signal"), 1)
class SignalTracker:
	extends RefCounted

	var _counts: Dictionary = {}

	func _on_signal(signal_name: String = "") -> void:
		if signal_name == "":
			return
		_counts[signal_name] = _counts.get(signal_name, 0) + 1

	func emit_count(signal_name: String) -> int:
		return _counts.get(signal_name, 0)

	func has_been_emitted(signal_name: String) -> bool:
		return _counts.get(signal_name, 0) > 0

	func reset() -> void:
		_counts.clear()


## StubProvider — returns canned values for dependency injection.
## Usage:
##   var stub := Mock.StubProvider.new()
##   stub.add("get_enemy_count", 5)
##   assert_eq(stub.call("get_enemy_count"), 5)
class StubProvider:
	extends RefCounted

	var _stubs: Dictionary = {}

	func add(method: String, value: Variant) -> void:
		_stubs[method] = value

	func call(method: String) -> Variant:
		return _stubs.get(method, null)

	func clear() -> void:
		_stubs.clear()
