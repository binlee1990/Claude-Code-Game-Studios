extends Gut

const BossActionPattern = preload("res://src/core/boss/boss_action_pattern.gd")
const BossPhase = preload("res://src/core/boss/boss_phase.gd")
const BossProfile = preload("res://src/core/boss/boss_profile.gd")
const BossCheckpoint = preload("res://src/core/boss/boss_checkpoint.gd")


# --- telegraph ---

func test_boss_telegraph_duration_default_0_7() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.telegraph_duration, 0.7)


func test_boss_telegraph_duration_within_safe_range() -> void:
	var ap := BossActionPattern.new()
	ap.telegraph_duration = 0.3
	assert_true(ap.telegraph_duration >= 0.3)
	ap.telegraph_duration = 1.5
	assert_true(ap.telegraph_duration <= 1.5)


# --- cooldown ---

func test_boss_action_pattern_cooldown_minimum_2() -> void:
	var ap := BossActionPattern.new()
	ap.cooldown_turns = 1
	assert_true(ap.cooldown_turns >= 1)
	ap.cooldown_turns = 10
	assert_true(ap.cooldown_turns <= 10)


# --- element binding ---

func test_boss_action_pattern_element_type_default_0() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.element_type, 0)


# --- phase action pattern binding ---

func test_boss_phase_active_patterns_indices() -> void:
	var phase := BossPhase.new()
	phase.active_patterns = [0, 1, 2]
	assert_eq(phase.active_patterns.size(), 3)
	assert_eq(phase.active_patterns[0], 0)
	assert_eq(phase.active_patterns[2], 2)


func test_boss_phase_active_patterns_empty_by_default() -> void:
	var phase := BossPhase.new()
	assert_eq(phase.active_patterns.size(), 0)


# --- phase threshold ---

func test_boss_phase_threshold_50_and_25() -> void:
	var phase1 := BossPhase.new()
	phase1.phase_index = 0
	phase1.hp_threshold = 0.50

	var phase2 := BossPhase.new()
	phase2.phase_index = 1
	phase2.hp_threshold = 0.25

	assert_eq(phase1.hp_threshold, 0.50)
	assert_eq(phase2.hp_threshold, 0.25)


# --- checkpoint spec ---

func test_boss_checkpoint_retained_hp_ratio_within_bounds() -> void:
	var cp := BossCheckpoint.new()
	cp.retained_hp_ratio = 0.05
	assert_true(cp.retained_hp_ratio >= 0.05)
	cp.retained_hp_ratio = 0.25
	assert_true(cp.retained_hp_ratio <= 0.25)


func test_boss_checkpoint_free_retries_within_bounds() -> void:
	var cp := BossCheckpoint.new()
	cp.free_retries = 0
	assert_true(cp.free_retries >= 0)
	cp.free_retries = 5
	assert_true(cp.free_retries <= 5)


# --- boss type stage/phase mapping ---

func test_boss_type_tutorial_1_phase() -> void:
	var bp := BossProfile.new()
	bp.boss_type = BossProfile.BossType.TUTORIAL
	assert_eq(bp.get_type_default("default_phases"), 1)


func test_boss_type_peak_3_phases() -> void:
	var bp := BossProfile.new()
	bp.boss_type = BossProfile.BossType.PEAK
	assert_eq(bp.get_type_default("default_phases"), 3)


# --- damage multiplier ---

func test_boss_action_pattern_damage_multiplier_default_1() -> void:
	var ap := BossActionPattern.new()
	assert_eq(ap.damage_multiplier, 1.0)


func test_boss_action_pattern_damage_multiplier_can_be_set() -> void:
	var ap := BossActionPattern.new()
	ap.damage_multiplier = 1.5
	assert_eq(ap.damage_multiplier, 1.5)


# --- full boss profile composition ---

func test_boss_profile_phases_and_patterns_composition() -> void:
	var bp := BossProfile.new()
	bp.boss_id = "ch3_finale_boss"
	bp.boss_type = BossProfile.BossType.PEAK
	bp.display_name = "Ch.3 Finale Boss"

	var phase1 := BossPhase.new()
	phase1.phase_index = 0
	phase1.hp_threshold = 0.50
	phase1.active_patterns = [0, 1]

	var phase2 := BossPhase.new()
	phase2.phase_index = 1
	phase2.hp_threshold = 0.25
	phase2.active_patterns = [1, 2, 3]

	bp.phases = [phase1, phase2]

	var ap1 := BossActionPattern.new()
	ap1.pattern_id = "sweep_attack"
	ap1.telegraph_duration = 0.7
	ap1.cooldown_turns = 2
	ap1.targets = BossActionPattern.TargetScope.ROW

	bp.action_patterns = [ap1]

	assert_eq(bp.phases.size(), 2)
	assert_eq(bp.action_patterns.size(), 1)
	var p0 = bp.phases[0]
	assert_eq(p0.active_patterns[0], 0)


# --- label mapping ---

func test_boss_label_all_types() -> void:
	var labels: Dictionary = {
		BossProfile.BossType.TUTORIAL: "tutorial",
		BossProfile.BossType.NARRATIVE: "narrative",
		BossProfile.BossType.APTITUDE: "aptitude",
		BossProfile.BossType.PEAK: "peak",
		BossProfile.BossType.HIDDEN: "hidden",
	}
	for type_key in labels:
		var bp := BossProfile.new()
		bp.boss_type = type_key
		assert_eq(bp.get_label(), labels[type_key])
