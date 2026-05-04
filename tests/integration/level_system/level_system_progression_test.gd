extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const AttributeSystemScript := preload("res://src/systems/gameplay/attribute_system.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const LevelSystemScript := preload("res://src/systems/features/level_system.gd")


func test_register_gain_exp_and_realm_modifiers() -> void:
	var deps := _deps()
	var level = deps["level"]
	assert_bool(level.register_entity("player")).is_true()
	assert_bool(level.register_entity("player")).is_false()
	deps["resources"].add("exp", BigNumberScript.from_int(100))
	assert_int(level.gain_exp("player", BigNumberScript.from_int(100))).is_equal(3)
	assert_int(level.get_level("player")).is_equal(4)
	assert_int(deps["resources"].get_value("exp").to_int()).is_equal(38)
	deps["resources"].add("exp", BigNumberScript.from_string("1e8"))
	level.gain_exp("player", BigNumberScript.from_string("1e8"))
	assert_bool(level.get_level("player") >= 10).is_true()
	assert_bool(level.get_realm("player") != "fanren").is_true()
	assert_bool(deps["attributes"].get_base("player", "atk").to_int() > 100).is_true()


func test_restore_save_loaded_reset_and_unregister_contracts() -> void:
	var deps := _deps()
	var level = deps["level"]
	level.register_entity("player")
	level.restore({"entities": {"player": {"level": 30, "realm": "zhuji", "current_realm_id": 2}}})
	assert_int(deps["attributes"].modifier_engine.get_all_targets().size()).is_equal(0)
	level._on_save_loaded({})
	assert_int(deps["attributes"].modifier_engine.unregister_by_source("level_system.realm.player.zhuji")).is_equal(6)
	level._on_save_loaded({})
	assert_int(level.unregister_entity("player")).is_equal(10)
	level.register_entity("player")
	level.restore({"entities": {"player": {"level": 30, "realm": "zhuji", "current_realm_id": 2}}})
	level._on_save_loaded({})
	level.reset("player", "breakthrough")
	assert_int(level.get_level("player")).is_equal(1)
	assert_str(level.get_realm("player")).is_equal("fanren")


func _deps() -> Dictionary:
	FormulaEngine.clear_all()
	var resources := ResourceSystemScript.new()
	for definition in [
		{"id": "exp", "category": "progress", "has_cap": false},
		{"id": "lingqi", "category": "regenerative", "has_cap": true, "cap": BigNumberScript.from_int(1000)},
	]:
		resources.register(definition)
	var attributes := AttributeSystemScript.new()
	attributes.register_entity("player", {"category": "player", "attribute_set": "player_set"})
	var data_config := DataConfigScript.new()
	data_config.load_table_data("production_config", {"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": ["realm"]}})
	var output := OutputMultiplierSystemScript.new(ModifierEngineScript.new(), data_config)
	output.load_config()
	return {"resources": resources, "attributes": attributes, "output": output, "level": LevelSystemScript.new(resources, attributes, output)}
