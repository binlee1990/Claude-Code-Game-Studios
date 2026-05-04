extends GdUnitTestSuite

const TimeManagerScript := preload("res://src/systems/foundation/time_manager.gd")


func test_speed_sources_multiply() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	time.add_speed_source("A", 1.5)
	time.add_speed_source("B", 2.0)
	assert_bool(abs(time.get_effective_speed() - 3.0) < 0.001).is_true()


func test_effective_speed_clamps_to_max() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	time.add_speed_source("A", 10.0)
	time.add_speed_source("B", 20.0)
	assert_bool(abs(time.get_effective_speed() - 100.0) < 0.001).is_true()


func test_invalid_speed_source_clamps_to_one() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	time.add_speed_source("bad", -1.0)
	assert_bool(abs(time.get_effective_speed() - 1.0) < 0.001).is_true()


func test_remove_missing_speed_source_is_noop() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	time.remove_speed_source("missing")
	assert_bool(abs(time.get_effective_speed() - 1.0) < 0.001).is_true()

