extends GdUnitTestSuite

const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")


func test_activation_duplicate_and_source_guards() -> void:
	var system := _system()
	var id: String = system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.15, "source_id": "equip_ring_001"})
	assert_bool(id.is_empty()).is_false()
	assert_int(int(round(system.get_multiplier("lingqi") * 100.0))).is_equal(115)
	assert_str(system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.25, "source_id": "equip_ring_001"})).is_equal("")
	assert_str(system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.0, "source_id": "zero"})).is_equal("")
	assert_str(system.activate_source({"resource_id": "lingqi", "source_type": "skill", "value": 0.15, "source_id": "skill"})).is_equal("")


func test_pool_math_tick_amount_and_breakdown() -> void:
	var system := _system()
	system.activate_source({"resource_id": "lingqi", "source_type": "realm", "value": 1.0, "source_id": "realm_lianqi"})
	system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.15, "source_id": "equip_a"})
	system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.10, "source_id": "equip_b"})
	system.activate_source({"resource_id": "lingqi", "source_type": "zone", "value": 0.10, "source_id": "zone_a"})
	system.activate_source({"resource_id": "lingqi", "source_type": "buff", "value": 0.20, "source_id": "buff_a"})
	assert_int(int(round(system.get_multiplier("lingqi") * 100.0))).is_equal(330)
	assert_int(int(round(system.get_production_rate("lingqi") * 100.0))).is_equal(330)
	var breakdown: Dictionary = system.get_breakdown("lingqi")
	assert_int(int(round(breakdown["pools"]["equipment"] * 100.0))).is_equal(125)
	assert_int(int(round(breakdown["pools"]["realm"] * 100.0))).is_equal(200)
	assert_int(int(round(breakdown["final_multiplier"] * 100.0))).is_equal(330)
	var lingshi := _system()
	lingshi.activate_source({"resource_id": "lingshi", "source_type": "realm", "value": 1.0, "source_id": "r"})
	lingshi.activate_source({"resource_id": "lingshi", "source_type": "equipment", "value": 0.25, "source_id": "e"})
	lingshi.activate_source({"resource_id": "lingshi", "source_type": "zone", "value": 0.10, "source_id": "z"})
	lingshi.activate_source({"resource_id": "lingshi", "source_type": "buff", "value": 0.20, "source_id": "b"})
	assert_bool(lingshi.get_tick_amount("lingshi", 0.5).is_zero()).is_true()
	assert_int(int(round(lingshi.fractional_carry["lingshi"] * 1000.0))).is_equal(165)
	assert_int(lingshi.get_tick_amount("lingshi", 1800.0).to_int()).is_equal(594)


func test_deactivation_returns_multiplier_to_base() -> void:
	var system := _system()
	system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.15, "source_id": "equip_ring_001"})
	assert_int(system.deactivate_source("equip_ring_001")).is_equal(1)
	assert_int(int(system.get_multiplier("lingqi") * 100.0)).is_equal(100)
	assert_int(int(system.get_production_rate("lingqi") * 100.0)).is_equal(100)
	assert_bool(system.get_tick_amount("lingqi", 0.0).is_zero()).is_true()


func _system() -> OutputMultiplierSystem:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("production_config", {
		"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"lingshi": {"base_rate_per_second": "0.1", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"exp": {"base_rate_per_second": "0", "allows_passive": false, "passive_sources": []},
	})
	var system := OutputMultiplierSystemScript.new(ModifierEngineScript.new(), data_config)
	system.load_config()
	return system
