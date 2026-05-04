extends GdUnitTestSuite

const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")
const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")

var _events := []


func before_test() -> void:
	_events.clear()
	EventBusScript.instance = EventBusScript.new()
	EventBusScript.instance.clear_all()
	EventBusScript.instance.subscribe("production_multiplier_changed", _on_changed)


func after_test() -> void:
	if EventBusScript.instance != null:
		EventBusScript.instance.clear_all()
	EventBusScript.instance = null


func test_activation_and_deactivation_emit_changed_events() -> void:
	var system := _system()
	system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.15, "source_id": "equip_ring_001"})
	assert_int(_events.size()).is_equal(1)
	assert_str(str(_events[0]["action"])).is_equal("activated")
	assert_int(int(round(_events[0]["new_multiplier"] * 100.0))).is_equal(115)
	system.deactivate_source("equip_ring_001")
	assert_int(_events.size()).is_equal(2)
	assert_str(str(_events[1]["action"])).is_equal("deactivated")


func test_modifier_expiry_emits_deactivation_event() -> void:
	var engine := ModifierEngineScript.new()
	var system := _system(engine)
	system.activate_source({"resource_id": "lingqi", "source_type": "buff", "value": 0.20, "source_id": "buff_pill_001", "duration": 5.0})
	engine.update(6.0)
	var last_event: Dictionary = _events[_events.size() - 1]
	assert_str(str(last_event["source_id"])).is_equal("buff_pill_001")
	assert_str(str(last_event["action"])).is_equal("deactivated")
	assert_int(int(system.get_multiplier("lingqi") * 100.0)).is_equal(100)


func _system(engine: ModifierEngine = null) -> OutputMultiplierSystem:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("production_config", {
		"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
	})
	var system := OutputMultiplierSystemScript.new(engine if engine != null else ModifierEngineScript.new(), data_config)
	system.load_config()
	return system


func _on_changed(payload: Dictionary) -> void:
	_events.append(payload)
