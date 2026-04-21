class_name AI
extends RefCounted

## AI personality types
enum AIType {
	AGGRESSIVE,
	DEFENSIVE,
	SUPPORT,
	CONTROL,
	BALANCED,
}

## Skill categories
enum SkillCategory {
	DAMAGE,
	HEAL,
	BUFF,
	CONTROL,
	BASIC_ATTACK,
}

## Threat formula constants
const THREAT_DAMAGE_DEALT_RATE: float = 0.1
const THREAT_DAMAGE_RECEIVED_RATE: float = 0.05
const THREAT_HEAL_RATE: float = 0.2
const THREAT_BUFF_FIXED: float = 10.0
const THREAT_SKILL: Dictionary = {
	SkillCategory.DAMAGE: 5.0,
	SkillCategory.HEAL: 20.0,
	SkillCategory.BUFF: 15.0,
	SkillCategory.CONTROL: 10.0,
	SkillCategory.BASIC_ATTACK: 5.0,
}
const THREAT_POSITION: Dictionary = {
	TerrainTypes.HEIGHT_LOW: 0.0,
	TerrainTypes.HEIGHT_PLAIN: 5.0,
	TerrainTypes.HEIGHT_HIGH: 10.0,
}

## AI type weight multipliers
const TYPE_WEIGHTS: Dictionary = {
	AIType.AGGRESSIVE: {"damage": 1.5, "survival": 1.0, "heal": 1.0, "buff": 1.0, "control": 1.0},
	AIType.DEFENSIVE: {"damage": 1.0, "survival": 1.5, "heal": 1.2, "buff": 1.0, "control": 1.0},
	AIType.SUPPORT:   {"damage": 1.0, "survival": 1.0, "heal": 1.5, "buff": 1.5, "control": 1.0},
	AIType.CONTROL:   {"damage": 1.0, "survival": 1.0, "heal": 1.0, "buff": 1.0, "control": 1.5},
	AIType.BALANCED:  {"damage": 1.0, "survival": 1.0, "heal": 1.0, "buff": 1.0, "control": 1.0},
}

## Position scoring constants
const POS_HEIGHT_SCORE: Dictionary = {
	TerrainTypes.HEIGHT_LOW: 0.8,
	TerrainTypes.HEIGHT_PLAIN: 1.0,
	TerrainTypes.HEIGHT_HIGH: 1.2,
}
const POS_ELEMENT_DANGEROUS: float = 0.5
const POS_ELEMENT_NORMAL: float = 1.0
const POS_SUPPORT_IN_RANGE: float = 1.2
const POS_SUPPORT_OUT_RANGE: float = 1.0

## Boss AI constants
const BOSS_PHASE_THRESHOLD: float = 0.70
const BOSS_ENRAGE_DAMAGE_MULT: float = 1.3
const BOSS_ENRAGE_SPEED_MULT: float = 1.2

static func get_type_weight(ai_type: int, category: String) -> float:
	return TYPE_WEIGHTS[ai_type].get(category, 1.0)

static func get_skill_threat(category: int) -> float:
	return THREAT_SKILL.get(category, 0.0)

static func get_position_threat(height: int) -> float:
	return THREAT_POSITION.get(height, 0.0)

static func get_height_score(height: int) -> float:
	return POS_HEIGHT_SCORE.get(height, 1.0)
