extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")


func test_set_max_clamps_current_when_cap_shrinks() -> void:
	var system := ResourceSystemScript.new()
	system.register({"id": "lingqi", "has_cap": true, "reset_scope": "breakthrough", "cap": BigNumberScript.from_int(1000)})
	system.set_value("lingqi", BigNumberScript.from_int(800))
	system.set_max("lingqi", BigNumberScript.from_int(500))
	assert_int(system.get_value("lingqi").to_int()).is_equal(500)
	assert_int(system.get_max("lingqi").to_int()).is_equal(500)


func test_reset_by_scope_breakthrough_resets_three_resources() -> void:
	var system := ResourceSystemScript.new()
	for id in ["lingqi", "xiuwei", "exp"]:
		system.register({"id": id, "has_cap": false, "reset_scope": "breakthrough", "cap": BigNumberScript.MAX})
		system.set_value(id, BigNumberScript.from_int(10))
	system.register({"id": "lingshi", "has_cap": false, "reset_scope": "ascension", "cap": BigNumberScript.MAX})
	system.set_value("lingshi", BigNumberScript.from_int(10))
	assert_int(system.reset_by_scope("breakthrough")).is_equal(3)
	assert_bool(system.get_value("lingqi").is_zero()).is_true()
	assert_int(system.get_value("lingshi").to_int()).is_equal(10)


func test_snapshot_restore_preserves_cap_before_current() -> void:
	var system := ResourceSystemScript.new()
	system.register({"id": "lingqi", "has_cap": true, "reset_scope": "breakthrough", "cap": BigNumberScript.from_int(500)})
	var snapshot := {"version": 1, "resources": {"lingqi": {"cap": BigNumberScript.from_int(1000).to_dict(), "current": BigNumberScript.from_int(800).to_dict()}}}
	system.restore(snapshot)
	assert_int(system.get_max("lingqi").to_int()).is_equal(1000)
	assert_int(system.get_value("lingqi").to_int()).is_equal(800)

