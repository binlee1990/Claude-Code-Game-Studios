extends GdUnitTestSuite

const RNGManagerScript := preload("res://src/systems/foundation/rng_manager.gd")


func test_save_load_restores_next_sequence() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(98765)
	for i in range(25):
		rng.rand_int(RNGManagerScript.CoreStream.COMBAT, 1, 100)
	var saved := rng.save_states()
	var expected := []
	for i in range(10):
		expected.append(rng.rand_int(RNGManagerScript.CoreStream.COMBAT, 1, 100))

	rng.load_states(saved)
	var actual := []
	for i in range(10):
		actual.append(rng.rand_int(RNGManagerScript.CoreStream.COMBAT, 1, 100))

	assert_array(actual).is_equal(expected)


func test_state_copy_does_not_consume_online_rng() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(555)
	var online_state := rng.save_states()
	var expected := rng.rand_float(RNGManagerScript.CoreStream.LOOT)
	rng.load_states(online_state)

	var simulation_state := rng.save_states()
	rng.run_with_state_copy(simulation_state, func(sim_rng):
		for i in range(20):
			sim_rng.rand_float(RNGManagerScript.CoreStream.LOOT)
		return true
	)
	var actual := rng.rand_float(RNGManagerScript.CoreStream.LOOT)
	assert_bool(abs(actual - expected) < 0.000001).is_true()


func test_pick_random_empty_array_returns_null() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(12345)
	assert_bool(rng.pick_random(RNGManagerScript.CoreStream.LOOT, []) == null).is_true()

