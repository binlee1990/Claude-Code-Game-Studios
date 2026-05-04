extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")


func test_add_sum_returns_250() -> void:
	var engine := ModifierEngineScript.new()
	engine.register({"target": "atk", "type": ModifierEngineScript.ADD, "value": 200.0, "source": "sword"})
	engine.register({"target": "atk", "type": ModifierEngineScript.ADD, "value": 50.0, "source": "ring"})
	assert_bool(abs(engine.get_add_sum("atk") - 250.0) < 0.001).is_true()


func test_same_pool_multipliers_add_before_multiply() -> void:
	var engine := ModifierEngineScript.new()
	engine.register({"target": "atk", "type": ModifierEngineScript.MULT, "value": 0.10, "pool": "equipment"})
	engine.register({"target": "atk", "type": ModifierEngineScript.MULT, "value": 0.15, "pool": "equipment"})
	engine.register({"target": "atk", "type": ModifierEngineScript.MULT, "value": 0.05, "pool": "equipment"})
	assert_bool(abs(engine.get_pool_multiplier("atk", "equipment") - 1.30) < 0.001).is_true()


func test_apply_returns_big_number_2500() -> void:
	var engine := ModifierEngineScript.new()
	engine.register({"target": "atk", "type": ModifierEngineScript.ADD, "value": 250.0})
	engine.register({"target": "atk", "type": ModifierEngineScript.MULT, "value": 1.0, "pool": "buff"})
	var result := engine.apply("atk", BigNumberScript.from_int(1000))
	assert_int(result.to_int()).is_equal(2500)


func test_unregister_returns_true_then_false() -> void:
	var engine := ModifierEngineScript.new()
	var id := engine.register({"target": "atk", "type": ModifierEngineScript.ADD, "value": 1.0})
	assert_bool(engine.unregister(id)).is_true()
	assert_bool(engine.unregister(id)).is_false()


func test_missing_target_register_returns_empty_id() -> void:
	var engine := ModifierEngineScript.new()
	assert_str(engine.register({"type": ModifierEngineScript.ADD, "value": 1.0})).is_equal("")


func test_zero_value_modifier_registers() -> void:
	var engine := ModifierEngineScript.new()
	var id := engine.register({"target": "atk", "type": ModifierEngineScript.ADD, "value": 0.0})
	assert_bool(not id.is_empty()).is_true()
	assert_bool(abs(engine.get_add_sum("atk") - 0.0) < 0.001).is_true()


func test_get_all_targets_is_unique() -> void:
	var engine := ModifierEngineScript.new()
	engine.register({"target": "player.atk", "type": ModifierEngineScript.ADD, "value": 1.0})
	engine.register({"target": "player.atk", "type": ModifierEngineScript.ADD, "value": 2.0})
	engine.register({"target": "lingqi_production", "type": ModifierEngineScript.MULT, "value": 0.5, "pool": "realm"})
	var targets := engine.get_all_targets()
	assert_int(targets.size()).is_equal(2)
	assert_array(targets).contains(["player.atk", "lingqi_production"])

