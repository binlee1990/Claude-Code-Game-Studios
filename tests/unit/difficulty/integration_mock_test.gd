extends Gut

const DifficultyManager = preload("res://src/core/difficulty/difficulty_manager.gd")

var _manager


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


# --- combat integration: enemy stat scaling ---

func test_difficulty_combat_enemy_stat_scaling_chapter_1() -> void:
	_manager.set_current_chapter(1)
	var base_hp: float = 100.0
	var scaled: float = _manager.scale_enemy_stat(base_hp)
	assert_eq(scaled, 70.0)


func test_difficulty_combat_enemy_stat_scaling_chapter_6() -> void:
	_manager.set_current_chapter(6)
	var base_atk: float = 50.0
	var scaled: float = _manager.scale_enemy_stat(base_atk)
	assert_eq(scaled, 60.0)


func test_difficulty_combat_enemy_stat_scaling_chapter_9() -> void:
	_manager.set_current_chapter(9)
	var base_hp: float = 200.0
	var scaled: float = _manager.scale_enemy_stat(base_hp)
	assert_eq(scaled, 280.0)


# --- settlement integration: exp/drop multipliers ---

func test_difficulty_settlement_exp_multiplier_chapter_1() -> void:
	_manager.set_current_chapter(1)
	var base_exp: float = 100.0
	var mult: float = _manager.get_exp_multiplier()
	var result: float = base_exp * mult
	assert_eq(result, 120.0)


func test_difficulty_settlement_resource_multiplier_chapter_6() -> void:
	_manager.set_current_chapter(6)
	var mult: float = _manager.get_resource_multiplier()
	assert_eq(mult, 0.9)


# --- AI integration: strategy level ---

func test_difficulty_ai_strategy_level_chapter_1_is_0() -> void:
	_manager.set_current_chapter(1)
	assert_eq(_manager.get_ai_strategy_level(), 0)


func test_difficulty_ai_strategy_level_chapter_6_is_1() -> void:
	_manager.set_current_chapter(6)
	assert_eq(_manager.get_ai_strategy_level(), 1)


func test_difficulty_ai_strategy_level_chapter_9_is_2() -> void:
	_manager.set_current_chapter(9)
	assert_eq(_manager.get_ai_strategy_level(), 2)


# --- full pipeline integration ---

func test_difficulty_full_pipeline_chapter_3() -> void:
	_manager.set_current_chapter(3)  # growth phase, 1.0x
	assert_eq(_manager.scale_enemy_stat(100.0), 100.0)
	assert_eq(_manager.get_exp_multiplier(), 1.0)
	assert_eq(_manager.get_resource_multiplier(), 1.0)
	assert_eq(_manager.get_ai_strategy_level(), 0)


func test_difficulty_full_pipeline_chapter_9() -> void:
	_manager.set_current_chapter(9)  # climax phase, 1.4x
	assert_eq(_manager.scale_enemy_stat(100.0), 140.0)
	assert_eq(_manager.get_exp_multiplier(), 0.8)
	assert_eq(_manager.get_resource_multiplier(), 0.8)
	assert_eq(_manager.get_ai_strategy_level(), 2)
