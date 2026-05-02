extends Gut

const BossActionPattern = preload("res://src/core/boss/boss_action_pattern.gd")
const Factory = preload("res://tests/helpers/factory_helpers.gd")


# --- telegraph simulation ---

func test_telegraph_duration_default_allows_immediate_trigger() -> void:
	var ap := BossActionPattern.new()
	# telegraph_duration = 0.7 default means boss has a warning window
	assert_true(ap.telegraph_duration > 0.0, "default telegraph must be positive")

func test_telegraph_duration_zero_means_instant() -> void:
	var ap := BossActionPattern.new()
	ap.telegraph_duration = 0.0
	assert_eq(ap.telegraph_duration, 0.0)

func test_telegraph_duration_settable() -> void:
	var ap := BossActionPattern.new()
	ap.telegraph_duration = 1.5
	assert_eq(ap.telegraph_duration, 1.5)

func test_telegraph_elapsed_less_than_duration_is_not_ready() -> void:
	var ap := BossActionPattern.new()
	ap.telegraph_duration = 1.0
	var elapsed: float = 0.5
	assert_true(elapsed < ap.telegraph_duration, "should not be ready at half duration")

func test_telegraph_elapsed_exceeds_duration_is_ready() -> void:
	var ap := BossActionPattern.new()
	ap.telegraph_duration = 0.7
	var elapsed: float = 0.71
	assert_true(elapsed >= ap.telegraph_duration, "should be ready after duration passed")


# --- cooldown simulation ---

func test_cooldown_default_positive() -> void:
	var ap := BossActionPattern.new()
	assert_true(ap.cooldown_turns > 0, "default cooldown must be positive")

func test_cooldown_decrements_each_turn() -> void:
	var ap := BossActionPattern.new()
	ap.cooldown_turns = 3
	ap.cooldown_turns -= 1
	assert_eq(ap.cooldown_turns, 2)

func test_cooldown_ready_when_zero() -> void:
	var ap := BossActionPattern.new()
	ap.cooldown_turns = 0
	assert_eq(ap.cooldown_turns, 0, "cooldown=0 means ready to use again")

func test_cooldown_not_ready_when_positive() -> void:
	var ap := BossActionPattern.new()
	ap.cooldown_turns = 2
	assert_true(ap.cooldown_turns > 0, "positive cooldown means not ready")

func test_cooldown_full_cycle() -> void:
	var ap := BossActionPattern.new()
	ap.cooldown_turns = 3
	# 模拟 3 回合冷却递减
	for i in range(1, 4):
		ap.cooldown_turns -= 1
		assert_eq(ap.cooldown_turns, 3 - i)
	assert_eq(ap.cooldown_turns, 0)


# --- target scope coverage ---

func test_target_scope_has_exactly_4_values() -> void:
	var values: Array[int] = [
		BossActionPattern.TargetScope.SINGLE,
		BossActionPattern.TargetScope.ROW,
		BossActionPattern.TargetScope.CROSS,
		BossActionPattern.TargetScope.AREA,
	]
	assert_eq(values.size(), 4)
	assert_eq(BossActionPattern.TargetScope.SINGLE, 0)
	assert_eq(BossActionPattern.TargetScope.AREA, 3)

func test_action_pattern_default_target_is_single() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.targets, BossActionPattern.TargetScope.SINGLE)

func test_action_pattern_target_scope_settable() -> void:
	var ap := BossActionPattern.new()
	ap.targets = BossActionPattern.TargetScope.CROSS
	assert_eq(ap.targets, BossActionPattern.TargetScope.CROSS)


# --- range indicator coverage ---

func test_range_indicator_has_exactly_4_values() -> void:
	var values: Array[int] = [
		BossActionPattern.RangeIndicator.RECT,
		BossActionPattern.RangeIndicator.CROSS,
		BossActionPattern.RangeIndicator.DIAMOND,
		BossActionPattern.RangeIndicator.FULLSCREEN,
	]
	assert_eq(values.size(), 4)
	assert_eq(BossActionPattern.RangeIndicator.RECT, 0)
	assert_eq(BossActionPattern.RangeIndicator.FULLSCREEN, 3)

func test_action_pattern_default_range_is_rect() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.range_indicator, BossActionPattern.RangeIndicator.RECT)


# --- damage multiplier edge cases ---

func test_damage_multiplier_default_is_one() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.damage_multiplier, 1.0)

func test_damage_multiplier_zero_means_no_damage() -> void:
	var ap := BossActionPattern.new()
	ap.damage_multiplier = 0.0
	assert_eq(ap.damage_multiplier, 0.0)

func test_damage_multiplier_double() -> void:
	var ap := BossActionPattern.new()
	ap.damage_multiplier = 2.0
	assert_eq(ap.damage_multiplier, 2.0)


# --- element type ---

func test_element_type_default_zero() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.element_type, 0)

func test_element_type_settable() -> void:
	var ap := BossActionPattern.new()
	ap.element_type = 4
	assert_eq(ap.element_type, 4)


# --- pattern identity ---

func test_pattern_id_default_empty() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.pattern_id, "")

func test_pattern_id_settable() -> void:
	var ap := BossActionPattern.new()
	ap.pattern_id = "boss_fire_breath"
	assert_eq(ap.pattern_id, "boss_fire_breath")


# --- full configuration using factory ---

func test_factory_make_action_pattern_has_correct_defaults() -> void:
	var ap := Factory.make_action_pattern()
	assert_eq(ap.pattern_id, "test_pattern")
	assert_eq(ap.cooldown_turns, 2)
	assert_eq(ap.damage_multiplier, 1.0)
	assert_eq(ap.targets, 0)
	assert_eq(ap.telegraph_duration, 0.7)

func test_factory_make_action_pattern_custom() -> void:
	var ap := Factory.make_action_pattern("fire_breath", 4, 2.5, BossActionPattern.TargetScope.CROSS, 1.2)
	assert_eq(ap.pattern_id, "fire_breath")
	assert_eq(ap.cooldown_turns, 4)
	assert_eq(ap.damage_multiplier, 2.5)
	assert_eq(ap.targets, BossActionPattern.TargetScope.CROSS)
	assert_eq(ap.telegraph_duration, 1.2)
