extends GdUnitTestSuite

const RNGManagerScript := preload("res://src/systems/foundation/rng_manager.gd")


func test_rng_calls_stay_under_one_percent_frame_budget() -> void:
	var rng := RNGManagerScript.new()
	rng.set_master_seed(12345)
	var start := Time.get_ticks_usec()
	for i in range(100):
		rng.rand_bool(RNGManagerScript.CoreStream.COMBAT, 0.5)
	var elapsed_ms := float(Time.get_ticks_usec() - start) / 1000.0
	assert_bool(elapsed_ms < 0.166).is_true()

