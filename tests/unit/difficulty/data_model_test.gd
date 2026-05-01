extends Gut

const DifficultyManager := preload("res://src/core/difficulty/difficulty_manager.gd")

var _manager: DifficultyManager


func before_each() -> void:
	_manager = DifficultyManager.new()
	_manager._set_phase_curve_for_test(_build_test_curve())


func after_each() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()


func _build_test_curve() -> Dictionary:
	return {
		"phases": [
			{"phase": 1, "label": "tutorial",  "enemy_stat_mult": 0.7, "exp_mult": 1.2, "resource_mult": 1.0, "ai_strategy_level": 0},
			{"phase": 2, "label": "growth",    "enemy_stat_mult": 1.0, "exp_mult": 1.0, "resource_mult": 1.0, "ai_strategy_level": 0},
			{"phase": 3, "label": "challenge", "enemy_stat_mult": 1.2, "exp_mult": 0.9, "resource_mult": 0.9, "ai_strategy_level": 1},
			{"phase": 4, "label": "climax",    "enemy_stat_mult": 1.4, "exp_mult": 0.8, "resource_mult": 0.8, "ai_strategy_level": 2},
		]
	}


# --- chapter → phase mapping ---

func test_difficulty_chapter_1_maps_to_tutorial() -> void:
	var profile: Dictionary = _manager.get_profile(1)
	assert_eq(profile["phase"], DifficultyManager.PHASE_TUTORIAL)

func test_difficulty_chapter_3_maps_to_growth() -> void:
	var profile: Dictionary = _manager.get_profile(3)
	assert_eq(profile["phase"], DifficultyManager.PHASE_GROWTH)

func test_difficulty_chapter_6_maps_to_challenge() -> void:
	var profile: Dictionary = _manager.get_profile(6)
	assert_eq(profile["phase"], DifficultyManager.PHASE_CHALLENGE)

func test_difficulty_chapter_9_maps_to_climax() -> void:
	var profile: Dictionary = _manager.get_profile(9)
	assert_eq(profile["phase"], DifficultyManager.PHASE_CLIMAX)


# --- per-phase multipliers ---

func test_difficulty_tutorial_enemy_stat_mult_is_0_7() -> void:
	assert_eq(_manager.get_profile(1)["enemy_stat_mult"], 0.7)

func test_difficulty_growth_enemy_stat_mult_is_1_0() -> void:
	assert_eq(_manager.get_profile(3)["enemy_stat_mult"], 1.0)

func test_difficulty_challenge_enemy_stat_mult_is_1_2() -> void:
	assert_eq(_manager.get_profile(6)["enemy_stat_mult"], 1.2)

func test_difficulty_climax_enemy_stat_mult_is_1_4() -> void:
	assert_eq(_manager.get_profile(9)["enemy_stat_mult"], 1.4)


# --- exp multipliers ---

func test_difficulty_tutorial_exp_mult_is_1_2() -> void:
	assert_eq(_manager.get_profile(1)["exp_mult"], 1.2)

func test_difficulty_challenge_exp_mult_is_0_9() -> void:
	assert_eq(_manager.get_profile(6)["exp_mult"], 0.9)


# --- resource multipliers ---

func test_difficulty_tutorial_resource_mult_is_1_0() -> void:
	assert_eq(_manager.get_profile(1)["resource_mult"], 1.0)

func test_difficulty_challenge_resource_mult_is_0_9() -> void:
	assert_eq(_manager.get_profile(6)["resource_mult"], 0.9)


# --- AI strategy level ---

func test_difficulty_tutorial_ai_strategy_level_is_0() -> void:
	assert_eq(_manager.get_profile(1)["ai_strategy_level"], 0)

func test_difficulty_challenge_ai_strategy_level_is_1() -> void:
	assert_eq(_manager.get_profile(6)["ai_strategy_level"], 1)

func test_difficulty_climax_ai_strategy_level_is_2() -> void:
	assert_eq(_manager.get_profile(9)["ai_strategy_level"], 2)


# --- NG multiplier ---

func test_difficulty_ng_multiplier_defaults_to_one() -> void:
	assert_eq(_manager.get_ng_multiplier(), 1.0)


# --- scale_enemy_stat ---

func test_difficulty_scale_enemy_stat_applies_multiplier() -> void:
	_manager.set_current_chapter(3)
	assert_eq(_manager.scale_enemy_stat(100.0), 100.0)
	_manager.set_current_chapter(1)
	assert_eq(_manager.scale_enemy_stat(100.0), 70.0)
	_manager.set_current_chapter(6)
	assert_eq(_manager.scale_enemy_stat(100.0), 120.0)
	_manager.set_current_chapter(9)
	assert_eq(_manager.scale_enemy_stat(100.0), 140.0)


# --- unaffected systems ---

func test_difficulty_bond_system_not_affected() -> void:
	assert_false(_manager.is_system_affected("bond"))

func test_difficulty_combat_system_is_affected() -> void:
	assert_true(_manager.is_system_affected("combat"))


# --- current profile convenience methods ---

func test_difficulty_get_enemy_stat_multiplier_uses_current_chapter() -> void:
	_manager.set_current_chapter(6)
	assert_eq(_manager.get_enemy_stat_multiplier(), 1.2)

func test_difficulty_get_exp_multiplier_uses_current_chapter() -> void:
	_manager.set_current_chapter(1)
	assert_eq(_manager.get_exp_multiplier(), 1.2)

func test_difficulty_get_ai_strategy_level_uses_current_chapter() -> void:
	_manager.set_current_chapter(9)
	assert_eq(_manager.get_ai_strategy_level(), 2)
