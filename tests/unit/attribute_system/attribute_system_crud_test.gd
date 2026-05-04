extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const AttributeSystemScript := preload("res://src/systems/gameplay/attribute_system.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")


func test_register_player_creates_six_attributes() -> void:
	var attrs := AttributeSystemScript.new()
	assert_bool(attrs.register_entity("player", {"category": "player", "attribute_set": "player_set"})).is_true()
	assert_bool(attrs.has_entity("player")).is_true()
	assert_int(attrs.get_attribute_set("player").size()).is_equal(6)


func test_duplicate_entity_register_returns_false() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set"})
	assert_bool(attrs.register_entity("player", {"category": "player", "attribute_set": "player_set"})).is_false()


func test_set_base_updates_value() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set", "attributes": {"atk": BigNumberScript.from_int(100)}})
	attrs.set_base("player", "atk", BigNumberScript.from_int(500))
	assert_int(attrs.get_base("player", "atk").to_int()).is_equal(500)


func test_unknown_attribute_rejects_write() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("player", {"category": "player", "attribute_set": "player_set"})
	attrs.set_base("player", "luck", BigNumberScript.from_int(1))
	assert_bool(attrs.get_base("player", "luck").is_zero()).is_true()


func test_unregister_returns_attribute_count() -> void:
	var attrs := AttributeSystemScript.new()
	attrs.register_entity("enemy_001", {"category": "enemy", "attribute_set": "enemy_basic_set"})
	assert_int(attrs.unregister_entity("enemy_001")).is_equal(6)
	assert_bool(attrs.has_entity("enemy_001")).is_false()

