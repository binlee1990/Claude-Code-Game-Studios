class_name ResourceFormulas
extends RefCounted

## Resource acquisition and drop formulas (GDD D.1-D.3).

## Gold reward: base + floor(damage * 0.1) + kill_bonus (boss=20, normal=0)
static func calculate_gold_reward(base_reward: int, damage_dealt: int, is_boss_kill: bool) -> int:
	var kill_bonus: int = 20 if is_boss_kill else 0
	return base_reward + int(damage_dealt * 0.1) + kill_bonus

## Material reward: enemy_tier * random(1, 3)
static func calculate_material_reward(enemy_tier: int, rng_seed: int = 0) -> int:
	var rand_value: int
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		rand_value = rng.randi_range(1, 3)
	else:
		rand_value = randi_range(1, 3)
	return enemy_tier * rand_value

## Drop rate constants
const DROP_RATE_NORMAL_FRUIT: float = 0.05
const DROP_RATE_BOSS_FRUIT: float = 1.0
const DROP_RATE_HARD_RARE: float = 0.10
const DROP_RATE_HIDDEN_BOSS_RARE: float = 1.0
const DROP_RATE_HELL_RARE: float = 0.20
const DROP_RATE_HELL_PROTECT: float = 0.02

## Enhancement cost formula (GDD D.4)
static func calculate_enhancement_cost(base_cost: int, current_level: int) -> Dictionary:
	var target_level: int = current_level + 1
	return {
		"gold": base_cost * target_level,
		"materials": 5 * target_level,
	}

## Enhancement success rate
static func get_enhancement_success_rate(current_level: int) -> float:
	if current_level < 5:
		return 1.0  # Safe zone +1 to +5
	return 1.0 - 0.3 - (current_level - 5) * 0.05  # 30% at +6, +5% per level

## Check if fruit drops for a given battle type
static func check_fruit_drop(is_boss: bool, rng_seed: int = 0) -> bool:
	var rate: float = DROP_RATE_BOSS_FRUIT if is_boss else DROP_RATE_NORMAL_FRUIT
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		return rng.randf() < rate
	return randf() < rate

## Get number of fruits dropped in boss battle (1-2)
static func get_boss_fruit_count(rng_seed: int = 0) -> int:
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		return rng.randi_range(1, 2)
	return randi_range(1, 2)

## Enhancement result
enum EnhancementResult { SUCCESS, FAIL_DOWNGRADE, FAIL_PROTECTED }

## Execute enhancement attempt
static func execute_enhancement(
	current_level: int,
	has_protection: bool,
	rng_seed: int = 0
) -> Dictionary:
	if current_level < 5:
		return {"result": EnhancementResult.SUCCESS, "new_level": current_level + 1}

	var success_rate: float = get_enhancement_success_rate(current_level)
	var roll: float
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		roll = rng.randf()
	else:
		roll = randf()

	if roll < success_rate:
		return {"result": EnhancementResult.SUCCESS, "new_level": current_level + 1}

	if has_protection:
		return {"result": EnhancementResult.FAIL_PROTECTED, "new_level": current_level}

	var new_level: int = maxi(current_level - 5, 0)
	return {"result": EnhancementResult.FAIL_DOWNGRADE, "new_level": new_level}
