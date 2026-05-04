extends GdUnitTestSuite

const RNGManagerScript := preload("res://src/systems/foundation/rng_manager.gd")


func test_combat_calls_do_not_change_next_loot_float() -> void:
	var control := RNGManagerScript.new()
	control.set_master_seed(12345)
	var expected := control.rand_float(RNGManagerScript.CoreStream.LOOT)

	var subject := RNGManagerScript.new()
	subject.set_master_seed(12345)
	for i in range(100):
		subject.rand_bool(RNGManagerScript.CoreStream.COMBAT, 0.5)
	var actual := subject.rand_float(RNGManagerScript.CoreStream.LOOT)

	assert_bool(abs(actual - expected) < 0.000001).is_true()


func test_weighted_pick_empty_or_zero_weights_returns_minus_one() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(12345)
	assert_int(rng.weighted_pick(RNGManagerScript.CoreStream.LOOT, [])).is_equal(-1)
	assert_int(rng.weighted_pick(RNGManagerScript.CoreStream.LOOT, [0.0, 0.0, 0.0])).is_equal(-1)


func test_rand_bool_probability_zero_returns_false_without_consuming() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(12345)
	var before: int = int(rng.get_stream_info(RNGManagerScript.CoreStream.COMBAT)["calls"])
	assert_bool(rng.rand_bool(RNGManagerScript.CoreStream.COMBAT, 0.0)).is_false()
	var after: int = int(rng.get_stream_info(RNGManagerScript.CoreStream.COMBAT)["calls"])
	assert_int(after).is_equal(before)


func test_rand_int_equal_bounds_returns_value_without_consuming() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(12345)
	var before: int = int(rng.get_stream_info(RNGManagerScript.CoreStream.COMBAT)["calls"])
	assert_int(rng.rand_int(RNGManagerScript.CoreStream.COMBAT, 7, 7)).is_equal(7)
	var after: int = int(rng.get_stream_info(RNGManagerScript.CoreStream.COMBAT)["calls"])
	assert_int(after).is_equal(before)
