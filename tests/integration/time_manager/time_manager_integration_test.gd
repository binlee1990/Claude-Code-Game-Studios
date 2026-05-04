extends GdUnitTestSuite

const TimeManagerScript := preload("res://src/systems/foundation/time_manager.gd")


func test_get_real_time_uses_unix_timestamp_source() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(123456.0)
	assert_bool(abs(time.get_real_time() - 123456.0) < 0.001).is_true()


func test_frozen_game_delta_returns_zero() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	var last_game_time := time.get_game_time()
	time.freeze()
	time.set_test_real_time(1030.0)
	assert_bool(abs(time.get_game_delta_since(last_game_time) - 0.0) < 0.001).is_true()


func test_speed_changes_while_frozen_apply_after_unfreeze() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(1000.0)
	time.freeze()
	time.add_speed_source("debug", 3.0)
	time.set_test_real_time(1010.0)
	assert_bool(abs(time.get_game_time() - 0.0) < 0.001).is_true()
	time.unfreeze()
	time.set_test_real_time(1020.0)
	assert_bool(abs(time.get_game_time() - 30.0) < 0.001).is_true()


func test_offline_delta_clamps_to_max_seconds() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(40000.0)
	var payload := time.calculate_offline_delta(0.0)
	assert_bool(abs(payload["real_delta"] - 28800.0) < 0.001).is_true()


func test_clock_rollback_returns_zero_delta() -> void:
	var time := TimeManagerScript.new()
	time.reset_for_test(100.0)
	var payload := time.calculate_offline_delta(200.0)
	assert_bool(abs(payload["real_delta"] - 0.0) < 0.001).is_true()

