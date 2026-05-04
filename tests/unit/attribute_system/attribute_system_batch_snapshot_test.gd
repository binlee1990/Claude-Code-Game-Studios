extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const AttributeSystemScript := preload("res://src/systems/gameplay/attribute_system.gd")
const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")

var _events := []


func before_test() -> void:
	_events.clear()
	EventBusScript.instance = EventBusScript.new()
	EventBusScript.instance.clear_all()


func after_test() -> void:
	if EventBusScript.instance != null:
		EventBusScript.instance.clear_all()
	EventBusScript.instance = null


func test_set_base_batch_updates_all_valid_attributes_and_emits_events() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set"})
	EventBusScript.instance.subscribe_pattern("attribute.player.", _on_attribute_event)
	attrs.set_base_batch("player", {
		"atk": BigNumberScript.from_int(500),
		"def": BigNumberScript.from_int(200),
		"spd": BigNumberScript.from_int(80),
	})
	assert_int(attrs.get_base("player", "atk").to_int()).is_equal(500)
	assert_int(attrs.get_base("player", "def").to_int()).is_equal(200)
	assert_int(attrs.get_base("player", "spd").to_int()).is_equal(80)
	assert_int(_events.size()).is_equal(3)


func test_snapshot_contains_player_and_five_disciples() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set", "attributes": {"atk": BigNumberScript.from_int(100)}})
	for i in range(5):
		attrs.register_entity("disciple_%03d" % [i + 1], {"category": "disciple", "attribute_set": "player_set", "attributes": {"atk": BigNumberScript.from_int(10 + i)}})
	var snapshot := attrs.snapshot()
	assert_int(int(snapshot["version"])).is_equal(1)
	assert_int(snapshot["entities"].size()).is_equal(6)
	var restored := BigNumberScript.from_dict(snapshot["entities"]["player"]["attributes"]["atk"])
	assert_int(restored.to_int()).is_equal(100)


func test_restore_skips_deprecated_schema_and_restores_other_entities() -> void:
	var attrs := AttributeSystemScript.new()
	var snapshot := {
		"version": 1,
		"entities": {
			"player": {
				"meta": {"category": "player", "attribute_set": "player_set"},
				"attributes": {"atk": {"m": 9.0, "e": 2}},
			},
			"deprecated_disciple": {
				"meta": {"category": "disciple", "attribute_set": "removed_set"},
				"attributes": {"atk": {"m": 5.0, "e": 2}},
			},
		},
	}
	attrs.restore(snapshot)
	assert_bool(attrs.has_entity("player")).is_true()
	assert_bool(attrs.has_entity("deprecated_disciple")).is_false()
	assert_int(attrs.get_base("player", "atk").to_int()).is_equal(900)


func test_restore_suppresses_base_changed_events() -> void:
	var attrs := AttributeSystemScript.new()
	EventBusScript.instance.subscribe_pattern("attribute.", _on_attribute_event)
	attrs.restore({
		"version": 1,
		"entities": {
			"player": {
				"meta": {"category": "player", "attribute_set": "player_set"},
				"attributes": {"atk": {"m": 1.0, "e": 3}, "def": {"m": 2.0, "e": 2}},
			},
		},
	})
	assert_int(_events.size()).is_equal(0)
	assert_int(attrs.get_base("player", "atk").to_int()).is_equal(1000)


func _on_attribute_event(event_name: String, payload: Dictionary) -> void:
	_events.append({"event": event_name, "payload": payload})
