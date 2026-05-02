extends Gut

const DifficultyBridge = preload("res://src/core/difficulty/difficulty_bridge.gd")


func test_difficulty_bridge_to_battle_profile_tutorial() -> void:
	var manager_profile: Dictionary = {
		"phase": 1, "enemy_stat_mult": 0.7, "exp_mult": 1.2, "resource_mult": 1.0, "ai_strategy_level": 0
	}
	var bp: Dictionary = DifficultyBridge.to_battle_profile(manager_profile)
	assert_eq(bp["label"], "Tutorial")
	assert_eq(bp["enemy_stat_multiplier"], 0.7)
	assert_eq(bp["exp_multiplier"], 1.2)
	assert_eq(bp["resource_multiplier"], 1.0)
	assert_eq(bp["ai_tier"], "baseline")


func test_difficulty_bridge_to_battle_profile_climax() -> void:
	var manager_profile: Dictionary = {
		"phase": 4, "enemy_stat_mult": 1.4, "exp_mult": 0.8, "resource_mult": 0.8, "ai_strategy_level": 2
	}
	var bp: Dictionary = DifficultyBridge.to_battle_profile(manager_profile)
	assert_eq(bp["label"], "Climax")
	assert_eq(bp["enemy_stat_multiplier"], 1.4)
	assert_eq(bp["exp_multiplier"], 0.8)
	assert_eq(bp["ai_tier"], "optimal")


func test_difficulty_bridge_ai_tier_baseline() -> void:
	var bp: Dictionary = DifficultyBridge.to_battle_profile({"phase": 2, "enemy_stat_mult": 1.0, "exp_mult": 1.0, "resource_mult": 1.0, "ai_strategy_level": 0})
	assert_eq(bp["ai_tier"], "baseline")


func test_difficulty_bridge_ai_tier_advanced() -> void:
	var bp: Dictionary = DifficultyBridge.to_battle_profile({"phase": 3, "enemy_stat_mult": 1.2, "exp_mult": 0.9, "resource_mult": 0.9, "ai_strategy_level": 1})
	assert_eq(bp["ai_tier"], "advanced")


func test_difficulty_bridge_merge_preserves_original_fields() -> void:
	var def_profile: Dictionary = {"label": "Custom", "enemy_stat_multiplier": 2.0, "exp_multiplier": 1.5}
	var merged: Dictionary = DifficultyBridge.merge_with_definition(3, def_profile)
	assert_eq(merged["label"], "Custom")
	# Enemy stat multiplier from DifficultyManager (ch.3 → phase 2, 1.0x)
	assert_eq(merged["enemy_stat_multiplier"], 2.0)
	assert_eq(merged["exp_multiplier"], 1.5)
	assert_eq(merged["label"], "Custom")
