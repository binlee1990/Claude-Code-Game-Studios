class_name DropCalculator
extends RefCounted

## Battle drop calculations for BS-004 (Story BS-004).
## Wraps existing ResourceFormulas and adds equipment drop / quality logic.
## GDD battle-settlement.md C.3, C.4.
## All methods static; deterministic given a seeded RNG.

## Enemy tier mapping for equipment drop rate (GDD C.4).
enum EnemyTier { NORMAL, ELITE, HARD, BOSS }

## Numeric tier multiplier for material yield (GDD C.3 — tier × rand(1,3)).
## Separate from enum ordinal to avoid NORMAL=0 yielding zero materials.
const TIER_MATERIAL_MULTIPLIER: Dictionary = {
	EnemyTier.NORMAL: 1,
	EnemyTier.ELITE:  2,
	EnemyTier.HARD:   3,
	EnemyTier.BOSS:   4,
}

## Equipment drop rate per enemy tier (GDD C.4).
## NORMAL=10%, ELITE=50%, HARD=50%, BOSS=100%.
const EQUIPMENT_DROP_RATE: Dictionary = {
	EnemyTier.NORMAL: 0.10,
	EnemyTier.ELITE:  0.50,
	EnemyTier.HARD:   0.50,
	EnemyTier.BOSS:   1.00,
}

## Equipment quality tiers.
enum Quality { WHITE, GREEN, BLUE, PURPLE, GOLD }

## Cumulative cutoffs for quality roll (ascending, exclusive upper bounds).
## Gold 0.5%, Purple 2%, Blue 10%, Green 27.5%, White 60%.
## GDD AC-D1.
const QUALITY_CUTOFFS: Array = [
	[0.005, Quality.GOLD],
	[0.025, Quality.PURPLE],
	[0.125, Quality.BLUE],
	[0.400, Quality.GREEN],
	[1.000, Quality.WHITE],
]

## Gold reward — thin wrapper around ResourceFormulas.calculate_gold_reward.
## formula: base + floor(damage * 0.1) + kill_bonus (boss=20, else 0). GDD D.1, AC.2.2.
static func calculate_gold(base_reward: int, damage_dealt: int, is_boss_kill: bool) -> int:
	return ResourceFormulas.calculate_gold_reward(base_reward, damage_dealt, is_boss_kill)

## Material reward — delegates to ResourceFormulas using TIER_MATERIAL_MULTIPLIER.
## formula: TIER_MATERIAL_MULTIPLIER[enemy_tier] * random(1,3). GDD C.3, AC.2.3.
## Returns 0 for unknown tiers.
static func calculate_materials(enemy_tier: int, rng_seed: int = 0) -> int:
	if not TIER_MATERIAL_MULTIPLIER.has(enemy_tier):
		return 0
	return ResourceFormulas.calculate_material_reward(TIER_MATERIAL_MULTIPLIER[enemy_tier], rng_seed)

## Returns true if equipment drops for the given enemy tier. GDD C.4, AC.2.3.
## Pass rng_seed != 0 for deterministic tests.
static func rolls_equipment_drop(enemy_tier: int, rng_seed: int = 0) -> bool:
	if not EQUIPMENT_DROP_RATE.has(enemy_tier):
		return false
	var rate: float = EQUIPMENT_DROP_RATE[enemy_tier]
	var roll: float
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		roll = rng.randf()
	else:
		roll = randf()
	return roll < rate

## Pure quality resolver from a pre-rolled float in [0, 1). GDD AC-D1.
## Deterministic — callers supply the roll value.
static func roll_quality_from(roll_value: float) -> int:
	for entry in QUALITY_CUTOFFS:
		var cutoff: float = entry[0]
		var quality: int  = entry[1]
		if roll_value < cutoff:
			return quality
	return Quality.WHITE  # defensive fallback

## Convenience seeded quality roll. GDD AC-D1.
static func roll_quality(rng_seed: int = 0) -> int:
	var roll: float
	if rng_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		roll = rng.randf()
	else:
		roll = randf()
	return roll_quality_from(roll)

## Aggregate drops from a list of defeated enemies into one reward bundle.
## Returns: { "gold": int, "materials": int, "equipment": Array[int Quality] }
##
## enemy_specs entries: { "tier": int, "damage_dealt": int,
##                        "is_boss_kill": bool, "base_gold": int (opt, default 0) }
##
## Pass rng_seed != 0 for fully deterministic aggregation (shared RNG across all rolls).
## Note: materials computed inline (TIER_MATERIAL_MULTIPLIER[tier] * randi_range(1,3))
## to share the seeded RNG sequence; ResourceFormulas.calculate_material_reward uses
## its own isolated RNG and cannot participate in a shared sequence.
static func aggregate_drops(enemy_specs: Array, rng_seed: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	var total_gold: int      = 0
	var total_materials: int = 0
	var equipment_drops: Array = []
	for spec in enemy_specs:
		var tier: int      = spec.get("tier", EnemyTier.NORMAL)
		var damage: int    = spec.get("damage_dealt", 0)
		var is_boss: bool  = spec.get("is_boss_kill", false)
		var base_gold: int = spec.get("base_gold", 0)
		total_gold += calculate_gold(base_gold, damage, is_boss)
		if TIER_MATERIAL_MULTIPLIER.has(tier):
			var mat_roll: int = rng.randi_range(1, 3) if rng_seed != 0 else randi_range(1, 3)
			total_materials += TIER_MATERIAL_MULTIPLIER[tier] * mat_roll
		if EQUIPMENT_DROP_RATE.has(tier):
			var drop_roll: float = rng.randf() if rng_seed != 0 else randf()
			if drop_roll < EQUIPMENT_DROP_RATE[tier]:
				var qual_roll: float = rng.randf() if rng_seed != 0 else randf()
				equipment_drops.append(roll_quality_from(qual_roll))
	return {
		"gold":      total_gold,
		"materials": total_materials,
		"equipment": equipment_drops,
	}
