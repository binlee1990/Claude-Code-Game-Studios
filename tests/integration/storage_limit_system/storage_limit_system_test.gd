extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const StorageLimitSystemScript := preload("res://src/systems/features/storage_limit_system.gd")


func test_storage_limits_initialize_and_report_capacity_state() -> void:
	var resources := _resources()
	var storage := StorageLimitSystemScript.new(resources)
	storage.initialize()
	assert_int(resources.get_max("lingqi").to_int()).is_equal(1000)
	resources.add("lingqi", BigNumberScript.from_int(900))
	var state := storage.get_capacity_state("lingqi")
	assert_str(str(state["state"])).is_equal("warning")
	assert_int(int(round(float(state["fill_ratio"]) * 10.0))).is_equal(9)
	assert_str(str(storage.get_capacity_state("lingshi")["state"])).is_equal("uncapped")


func test_recompute_applies_realm_multiplier_and_resource_clamps() -> void:
	var resources := _resources()
	var storage := StorageLimitSystemScript.new(resources)
	storage.initialize()
	storage.set_realm_cap_multiplier(2.0)
	assert_int(resources.get_max("lingqi").to_int()).is_equal(2000)
	resources.add("lingqi", BigNumberScript.from_int(1900))
	storage.set_realm_cap_multiplier(1.0)
	assert_int(resources.get_max("lingqi").to_int()).is_equal(1000)
	assert_int(resources.get_value("lingqi").to_int()).is_equal(1000)


func _resources() -> ResourceSystem:
	var resources := ResourceSystemScript.new()
	resources.register({"id": "lingqi", "category": "regenerative", "has_cap": true, "cap": BigNumberScript.from_int(1000)})
	resources.register({"id": "herb", "category": "material", "has_cap": true, "cap": BigNumberScript.from_int(500)})
	resources.register({"id": "lingshi", "category": "currency", "has_cap": false})
	return resources
