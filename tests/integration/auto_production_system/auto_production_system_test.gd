extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const TimeManagerScript := preload("res://src/systems/foundation/time_manager.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const AutoProductionSystemScript := preload("res://src/systems/features/auto_production_system.gd")


func test_tick_adds_nonzero_passive_resources_and_skips_fractional_zero() -> void:
	var deps := _deps()
	var auto = deps["auto"]
	deps["time"].set_test_real_time(1.0)
	auto.tick()
	assert_int(deps["resources"].get_value("lingqi").to_int()).is_equal(1)
	assert_bool(deps["resources"].get_value("herb").is_zero()).is_true()
	assert_bool(auto.passive_resource_ids.has("exp")).is_false()


func test_frozen_time_skips_tick_and_invalid_resource_does_not_block_valid() -> void:
	var deps := _deps()
	var auto = deps["auto"]
	auto.passive_resource_ids.append("invalid")
	deps["time"].freeze()
	deps["time"].set_test_real_time(1.0)
	auto.tick()
	assert_bool(deps["resources"].get_value("lingqi").is_zero()).is_true()
	deps["time"].unfreeze()
	deps["time"].set_test_real_time(2.0)
	auto.tick()
	assert_int(deps["resources"].get_value("lingqi").to_int()).is_equal(1)


func _deps() -> Dictionary:
	var time := TimeManagerScript.new()
	time.reset_for_test(0.0)
	var resources := ResourceSystemScript.new()
	resources.register({"id": "lingqi", "category": "regenerative", "has_cap": false})
	resources.register({"id": "xiuwei", "category": "progress", "has_cap": false})
	resources.register({"id": "lingshi", "category": "currency", "has_cap": false})
	resources.register({"id": "herb", "category": "material", "has_cap": false})
	var data_config := DataConfigScript.new()
	data_config.load_table_data("production_config", {
		"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": []},
		"xiuwei": {"base_rate_per_second": "0.0", "allows_passive": true, "passive_sources": []},
		"lingshi": {"base_rate_per_second": "0.0", "allows_passive": true, "passive_sources": []},
		"herb": {"base_rate_per_second": "0.02", "allows_passive": true, "passive_sources": []},
		"exp": {"base_rate_per_second": "0", "allows_passive": false, "passive_sources": []},
	})
	var output := OutputMultiplierSystemScript.new(ModifierEngineScript.new(), data_config)
	output.load_config()
	return {"time": time, "resources": resources, "output": output, "auto": AutoProductionSystemScript.new(time, output, resources)}
