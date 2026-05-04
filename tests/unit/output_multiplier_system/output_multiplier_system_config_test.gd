extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")


func test_loads_production_config_and_initial_rates() -> void:
	var system := _system_with(_config())
	assert_int(int(system.get_production_rate("lingqi") * 1000.0)).is_equal(1000)
	assert_int(int(system.get_production_rate("xiuwei") * 1000.0)).is_equal(100)
	assert_int(int(system.get_production_rate("lingshi") * 1000.0)).is_equal(100)
	assert_int(int(system.get_production_rate("herb") * 1000.0)).is_equal(20)
	assert_int(int(system.get_production_rate("exp") * 1000.0)).is_equal(0)
	assert_int(int(system.fractional_carry["lingqi"] * 1000.0)).is_equal(0)


func test_exp_passive_disabled_ignores_modifier_and_activation() -> void:
	var engine := ModifierEngineScript.new()
	var system := _system_with(_config(), engine)
	engine.register({"target": "exp_production", "type": ModifierEngineScript.MULT, "value": 1.0, "pool": "realm", "source": "realm"})
	assert_int(int(system.get_production_rate("exp") * 1000.0)).is_equal(0)
	assert_bool(system.get_tick_amount("exp", 10.0).equals(BigNumberScript.ZERO)).is_true()
	assert_str(system.activate_source({"resource_id": "exp", "source_type": "equipment", "value": 0.15, "source_id": "exp_src"})).is_equal("")


func test_empty_config_degrades_to_zero_resources() -> void:
	var system := _system_with({})
	assert_int(system.base_rates.size()).is_equal(0)
	assert_int(int(system.get_production_rate("lingqi") * 1000.0)).is_equal(0)
	assert_str(system.activate_source({"resource_id": "lingqi", "source_type": "equipment", "value": 0.15, "source_id": "x"})).is_equal("")


func _system_with(config: Dictionary, engine: ModifierEngine = null) -> OutputMultiplierSystem:
	var data_config := DataConfigScript.new()
	data_config.load_table_data("production_config", config)
	var system := OutputMultiplierSystemScript.new(engine if engine != null else ModifierEngineScript.new(), data_config)
	system.load_config()
	return system


func _config() -> Dictionary:
	return {
		"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"xiuwei": {"base_rate_per_second": "0.1", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"lingshi": {"base_rate_per_second": "0.1", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"herb": {"base_rate_per_second": "0.02", "allows_passive": true, "passive_sources": ["realm", "equipment", "zone", "buff"]},
		"exp": {"base_rate_per_second": "0", "allows_passive": false, "passive_sources": []},
	}
