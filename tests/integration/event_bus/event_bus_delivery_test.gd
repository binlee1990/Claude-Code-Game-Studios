extends GdUnitTestSuite

const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")

var exact_payloads := []
var pattern_events := []
var recursive_bus


func before_test() -> void:
	exact_payloads = []
	pattern_events = []
	recursive_bus = null


func test_exact_subscribe_emit_and_unsubscribe() -> void:
	var bus := EventBusScript.new()
	bus.subscribe("test.event", Callable(self, "_record_exact"))
	bus.emit("test.event", {"key": "value"})
	bus.unsubscribe("test.event", Callable(self, "_record_exact"))
	bus.emit("test.event", {"key": "ignored"})
	assert_int(exact_payloads.size()).is_equal(1)
	assert_str(exact_payloads[0]["key"]).is_equal("value")


func test_subscribe_once_only_fires_once() -> void:
	var bus := EventBusScript.new()
	bus.subscribe_once("test.event", Callable(self, "_record_exact"))
	bus.emit("test.event", {"n": 1})
	bus.emit("test.event", {"n": 2})
	assert_int(exact_payloads.size()).is_equal(1)
	assert_int(exact_payloads[0]["n"]).is_equal(1)


func test_pattern_subscriber_receives_event_name_and_payload() -> void:
	var bus := EventBusScript.new()
	bus.subscribe_pattern("resource", Callable(self, "_record_pattern"))
	bus.emit("resource.lingqi.changed", {"amount": 10})
	bus.emit("attribute.player.atk.base_changed", {"amount": 20})
	assert_int(pattern_events.size()).is_equal(1)
	assert_str(pattern_events[0]["event"]).is_equal("resource.lingqi.changed")
	assert_int(pattern_events[0]["payload"]["amount"]).is_equal(10)


func test_exact_and_pattern_subscriptions_are_independent() -> void:
	var bus := EventBusScript.new()
	bus.subscribe("test.event", Callable(self, "_record_exact"))
	bus.subscribe_pattern("test", Callable(self, "_record_pattern"))
	bus.unsubscribe("test", Callable(self, "_record_pattern"))
	bus.emit("test.event", {"ok": true})
	assert_int(exact_payloads.size()).is_equal(1)
	assert_int(pattern_events.size()).is_equal(1)


func test_coalesced_event_delivers_latest_payload_once() -> void:
	var bus := EventBusScript.new()
	bus.subscribe("ui.hud.refresh", Callable(self, "_record_exact"))
	for i in range(10):
		bus.emit_coalesced("ui.hud.refresh", {"index": i}, "resource_panel")
	bus.flush_coalesced()
	assert_int(exact_payloads.size()).is_equal(1)
	assert_int(exact_payloads[0]["index"]).is_equal(9)


func test_recursive_same_event_emit_is_ignored() -> void:
	var bus := EventBusScript.new()
	recursive_bus = bus
	bus.subscribe("loop.event", Callable(self, "_recursive_emit"))
	bus.emit("loop.event", {"depth": 0})
	assert_int(exact_payloads.size()).is_equal(1)


func _record_exact(payload: Dictionary) -> void:
	exact_payloads.append(payload)


func _record_pattern(event_name: String, payload: Dictionary) -> void:
	pattern_events.append({"event": event_name, "payload": payload})


func _recursive_emit(payload: Dictionary) -> void:
	exact_payloads.append(payload)
	recursive_bus.emit("loop.event", {"depth": 1})

