extends Gut

const BossProfile = preload("res://src/core/boss/boss_profile.gd")
const BossPhase = preload("res://src/core/boss/boss_phase.gd")
const BossCheckpoint = preload("res://src/core/boss/boss_checkpoint.gd")
const BossActionPattern = preload("res://src/core/boss/boss_action_pattern.gd")


func test_boss_profile_has_all_fields() -> void:
	var bp := BossProfile.new()
	bp.boss_id = "test_boss"
	bp.boss_type = 3
	bp.display_name = "Test Boss"
	assert_eq(bp.boss_id, "test_boss")
	assert_eq(bp.boss_type, 3)
	assert_eq(bp.display_name, "Test Boss")


func test_boss_type_enum_has_5_values() -> void:
	var TUTORIAL: int = BossProfile.BossType.TUTORIAL
	var NARRATIVE: int = BossProfile.BossType.NARRATIVE
	var APTITUDE: int = BossProfile.BossType.APTITUDE
	var PEAK: int = BossProfile.BossType.PEAK
	var HIDDEN: int = BossProfile.BossType.HIDDEN
	assert_eq(TUTORIAL, 0)
	assert_eq(NARRATIVE, 1)
	assert_eq(APTITUDE, 2)
	assert_eq(PEAK, 3)
	assert_eq(HIDDEN, 4)


func test_boss_type_defaults_tutorial_has_1_phase() -> void:
	var bp := BossProfile.new()
	bp.boss_type = 0
	assert_eq(bp.get_type_default("default_phases"), 1)


func test_boss_type_defaults_peak_has_3_phases() -> void:
	var bp := BossProfile.new()
	bp.boss_type = 3
	assert_eq(bp.get_type_default("default_phases"), 3)


func test_boss_type_defaults_hidden_has_4_phases() -> void:
	var bp := BossProfile.new()
	bp.boss_type = 4
	assert_eq(bp.get_type_default("default_phases"), 4)


func test_boss_default_hint_level_per_type() -> void:
	var bp := BossProfile.new()
	bp.boss_type = 0
	assert_eq(bp.get_type_default("hint_level"), 2)
	bp.boss_type = 2
	assert_eq(bp.get_type_default("hint_level"), 0)


func test_boss_phase_has_correct_defaults() -> void:
	var phase := BossPhase.new()
	assert_eq(phase.phase_index, 0)
	assert_eq(phase.hp_threshold, 0.50)
	assert_eq(phase.phase_name, "")


func test_boss_phase_hp_threshold_can_be_set() -> void:
	var phase := BossPhase.new()
	phase.hp_threshold = 0.25
	assert_eq(phase.hp_threshold, 0.25)


func test_boss_checkpoint_has_correct_defaults() -> void:
	var cp := BossCheckpoint.new()
	assert_eq(cp.phase_index, 0)
	assert_eq(cp.retained_hp_ratio, 0.15)
	assert_eq(cp.free_retries, 2)
	assert_false(cp.pattern_hints_revealed)


func test_boss_checkpoint_get_retained_hp() -> void:
	var cp := BossCheckpoint.new()
	cp.retained_hp_ratio = 0.15
	assert_eq(cp.get_retained_hp(1000), 150)


func test_boss_checkpoint_retained_hp_rounds_up() -> void:
	var cp := BossCheckpoint.new()
	cp.retained_hp_ratio = 0.15
	assert_eq(cp.get_retained_hp(100), 15)


func test_boss_action_pattern_has_correct_defaults() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.telegraph_duration, 0.7)
	assert_eq(ap.cooldown_turns, 2)
	assert_eq(ap.targets, 0)
	assert_eq(ap.range_indicator, 0)
	assert_eq(ap.element_type, 0)
	assert_eq(ap.damage_multiplier, 1.0)


func test_boss_action_pattern_targetscope_has_4_values() -> void:
	var SINGLE: int = BossActionPattern.TargetScope.SINGLE
	var ROW: int = BossActionPattern.TargetScope.ROW
	var CROSS: int = BossActionPattern.TargetScope.CROSS
	var AREA: int = BossActionPattern.TargetScope.AREA
	assert_eq(SINGLE, 0)
	assert_eq(ROW, 1)
	assert_eq(CROSS, 2)
	assert_eq(AREA, 3)


func test_boss_action_pattern_range_indicator_has_4_values() -> void:
	var RECT: int = BossActionPattern.RangeIndicator.RECT
	var CROSS_V: int = BossActionPattern.RangeIndicator.CROSS
	var DIAMOND: int = BossActionPattern.RangeIndicator.DIAMOND
	var FULLSCREEN: int = BossActionPattern.RangeIndicator.FULLSCREEN
	assert_eq(RECT, 0)
	assert_eq(CROSS_V, 1)
	assert_eq(DIAMOND, 2)
	assert_eq(FULLSCREEN, 3)


func test_boss_profile_get_label_returns_correct_label() -> void:
	var bp := BossProfile.new()
	bp.boss_type = 0
	assert_eq(bp.get_label(), "tutorial")
	bp.boss_type = 4
	assert_eq(bp.get_label(), "hidden")


func test_boss_checkpoint_can_set_pattern_hints_revealed() -> void:
	var cp := BossCheckpoint.new()
	cp.pattern_hints_revealed = true
	assert_true(cp.pattern_hints_revealed)
