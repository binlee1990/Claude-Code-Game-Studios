extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const AttributeSystemScript := preload("res://src/systems/gameplay/attribute_system.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")


func test_get_final_passthrough_without_modifiers() -> void:
	var engine := ModifierEngineScript.new()
	var attrs := AttributeSystemScript.new(engine)
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set", "attributes": {"atk": BigNumberScript.from_int(1000)}})
	assert_int(attrs.get_final("player", "atk").to_int()).is_equal(1000)


func test_get_final_applies_modifier_engine() -> void:
	var engine := ModifierEngineScript.new()
	var attrs := AttributeSystemScript.new(engine)
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set", "attributes": {"atk": BigNumberScript.from_int(1000)}})
	engine.register({"target": "player.atk", "type": ModifierEngineScript.ADD, "value": 200.0})
	engine.register({"target": "player.atk", "type": ModifierEngineScript.MULT, "value": 0.5, "pool": "equipment"})
	assert_int(attrs.get_final("player", "atk").to_int()).is_equal(1800)


func test_make_target_returns_canonical_string_name() -> void:
	var attrs := AttributeSystemScript.new()
	var first := attrs.make_target("player", "atk")
	var second := attrs.make_target("player", "atk")
	assert_str(str(first)).is_equal("player.atk")
	assert_str(str(second)).is_equal("player.atk")

