extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")


func _make_system() -> ResourceSystem:
	var system := ResourceSystemScript.new()
	system.register({"id": "lingqi", "category": "regenerative", "has_cap": true, "reset_scope": "breakthrough", "cap": BigNumberScript.from_int(1000)})
	system.register({"id": "lingshi", "category": "currency", "has_cap": false, "reset_scope": "ascension", "cap": BigNumberScript.MAX})
	system.register({"id": "herb", "category": "material", "has_cap": true, "reset_scope": "ascension", "cap": BigNumberScript.from_int(500)})
	system.register({"id": "xiuwei", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumberScript.MAX})
	system.register({"id": "exp", "category": "progress", "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumberScript.MAX})
	return system


func test_register_five_mvp_resources() -> void:
	var system := _make_system()
	assert_int(system.get_all_ids().size()).is_equal(5)
	assert_bool(system.get_value("lingqi").is_zero()).is_true()


func test_duplicate_register_returns_false() -> void:
	var system := _make_system()
	assert_bool(system.register({"id": "lingqi"})).is_false()


func test_capped_add_returns_actual_added() -> void:
	var system := _make_system()
	system.set_value("lingqi", BigNumberScript.from_int(800))
	var actual := system.add("lingqi", BigNumberScript.from_int(300))
	assert_int(actual.to_int()).is_equal(200)
	assert_int(system.get_value("lingqi").to_int()).is_equal(1000)


func test_uncapped_add_returns_full_amount() -> void:
	var system := _make_system()
	system.set_value("lingshi", BigNumberScript.from_int(500))
	var actual := system.add("lingshi", BigNumberScript.from_int(9999))
	assert_int(actual.to_int()).is_equal(9999)
	assert_int(system.get_value("lingshi").to_int()).is_equal(10499)


func test_spend_rejects_insufficient_balance() -> void:
	var system := _make_system()
	system.set_value("herb", BigNumberScript.from_int(300))
	assert_bool(system.spend("herb", BigNumberScript.from_int(301))).is_false()
	assert_int(system.get_value("herb").to_int()).is_equal(300)


func test_batch_add_returns_each_actual_added() -> void:
	var system := _make_system()
	var result := system.batch_add({"lingqi": BigNumberScript.from_int(100), "herb": BigNumberScript.from_int(50), "exp": BigNumberScript.from_int(200)})
	assert_int(result.size()).is_equal(3)
	assert_int(system.get_value("exp").to_int()).is_equal(200)

