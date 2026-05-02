extends Gut

# Frame-time baseline performance test.
# Asserts that core operations complete within budget thresholds.
# These are microbenchmarks — run with `--headless` for consistent results.

const ITERATIONS := 1000
const FRAME_BUDGET_USEC := 16667  # 16.667ms = 60 FPS budget

# Preloaded resources
const BossActionPattern = preload("res://src/core/boss/boss_action_pattern.gd")
const BossProfile = preload("res://src/core/boss/boss_profile.gd")
const BossPhase = preload("res://src/core/boss/boss_phase.gd")
const BossCheckpoint = preload("res://src/core/boss/boss_checkpoint.gd")


func _measure_usec(fn: Callable) -> int:
	var start := Time.get_ticks_usec()
	fn.call()
	return Time.get_ticks_usec() - start


# --- resource instantiation ---

func test_boss_action_pattern_instantiation_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		for _i in ITERATIONS:
			var ap := BossActionPattern.new()
			ap.free()
	)
	var per_instance := elapsed / ITERATIONS
	assert_true(per_instance < 1000, "instantiation per instance should be < 1000 usec, got %d" % per_instance)

func test_boss_profile_instantiation_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		for _i in ITERATIONS:
			var bp := BossProfile.new()
			bp.free()
	)
	var per_instance := elapsed / ITERATIONS
	assert_true(per_instance < 1000, "instantiation should be < 1000 usec, got %d" % per_instance)

func test_boss_phase_instantiation_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		for _i in ITERATIONS:
			var phase := BossPhase.new()
			phase.free()
	)
	var per_instance := elapsed / ITERATIONS
	assert_true(per_instance < 1000, "instantiation should be < 1000 usec, got %d" % per_instance)

func test_boss_checkpoint_instantiation_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		for _i in ITERATIONS:
			var cp := BossCheckpoint.new()
			cp.free()
	)
	var per_instance := elapsed / ITERATIONS
	assert_true(per_instance < 1000, "instantiation should be < 1000 usec, got %d" % per_instance)

func test_boss_profile_full_composition_under_5ms() -> void:
	var elapsed := _measure_usec(func():
		for _i in ITERATIONS:
			var bp := BossProfile.new()
			bp.boss_id = "perf_test"
			bp.boss_type = 3
			bp.display_name = "Perf Test"
			var phase := BossPhase.new()
			phase.phase_index = 0
			bp.phases.append(phase)
			var ap := BossActionPattern.new()
			ap.pattern_id = "perf_attack"
			bp.action_patterns.append(ap)
			bp.free()
	)
	var per_instance := elapsed / ITERATIONS
	assert_true(per_instance < 5000, "full composition should be < 5000 usec, got %d" % per_instance)


# --- dictionary operations (common in game logic) ---

func test_dictionary_read_1000_keys_under_1ms() -> void:
	var d: Dictionary = {}
	for i in ITERATIONS:
		d[str(i)] = i
	var elapsed := _measure_usec(func():
		for i in ITERATIONS:
			var _v = d[str(i)]
	)
	assert_true(elapsed < 1000, "read 1000 dict keys should be < 1000 usec, got %d" % elapsed)

func test_array_append_1000_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		var arr: Array[int] = []
		for i in ITERATIONS:
			arr.append(i)
	)
	assert_true(elapsed < 1000, "append 1000 ints should be < 1000 usec, got %d" % elapsed)

func test_array_iteration_1000_under_1ms() -> void:
	var arr: Array[int] = []
	for i in ITERATIONS:
		arr.append(i)
	var elapsed := _measure_usec(func():
		for item in arr:
			var _v = item * 2
	)
	assert_true(elapsed < 1000, "iterate 1000 items should be < 1000 usec, got %d" % elapsed)


# --- math operations ---

func test_float_operations_1000_under_1ms() -> void:
	var elapsed := _measure_usec(func():
		var acc: float = 0.0
		for i in ITERATIONS:
			acc += sin(float(i) * 0.01) * cos(float(i) * 0.01)
	)
	assert_true(elapsed < 1000, "1000 float ops should be < 1000 usec, got %d" % elapsed)
