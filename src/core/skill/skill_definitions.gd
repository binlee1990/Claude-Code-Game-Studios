class_name SkillDefinitions
extends RefCounted

## Static registry for skill definitions and cross-class skill metadata.

enum SourceType { NORMAL, CLASS }
enum UsageType { ACTIVE, PASSIVE }
enum Rank { BASIC, INTERMEDIATE, ADVANCED, MASTER }
enum DamageType { NONE, PHYSICAL, MAGIC }

const RANK_LEVEL_CAPS: Dictionary = {
	Rank.BASIC: 10,
	Rank.INTERMEDIATE: 20,
	Rank.ADVANCED: 30,
	Rank.MASTER: 99,
}

const DEFAULT_RANK_UP_CONDITION: Dictionary = {
	"intermediate_hidden_attr_threshold": 50,
	"advanced_hidden_attr_threshold": 100,
	"master_requires_challenge": true,
}

const TRAIT_PACK_FIREBALL: Dictionary = {
	10: [
		{"trait_id": "range_plus_1", "name": "Range +1", "effect_type": "range_add", "value": 1},
		{"trait_id": "damage_20", "name": "Damage +20%", "effect_type": "damage_mult", "value": 1.2},
		{"trait_id": "burn_plus_1", "name": "Burn +1", "effect_type": "duration_add", "value": 1},
	],
	20: [
		{"trait_id": "chain_burst", "name": "Chain Burst", "effect_type": "effect_unlock", "value": "chain_burst"},
		{"trait_id": "fire_pierce", "name": "Fire Pierce", "effect_type": "damage_mult", "value": 1.15},
	],
	30: [
		{"trait_id": "meteor", "name": "Meteor", "effect_type": "effect_unlock", "value": "meteor"},
		{"trait_id": "avatar_flame", "name": "Avatar Flame", "effect_type": "damage_mult", "value": 1.5},
	],
}

const TRAIT_PACK_MELEE: Dictionary = {
	10: [
		{"trait_id": "damage_20", "name": "Damage +20%", "effect_type": "damage_mult", "value": 1.2},
		{"trait_id": "range_plus_1", "name": "Range +1", "effect_type": "range_add", "value": 1},
	],
	20: [
		{"trait_id": "armor_break", "name": "Armor Break", "effect_type": "effect_unlock", "value": "armor_break"},
		{"trait_id": "damage_15", "name": "Damage +15%", "effect_type": "damage_mult", "value": 1.15},
	],
	30: [
		{"trait_id": "finisher", "name": "Finisher", "effect_type": "damage_mult", "value": 1.4},
		{"trait_id": "shockwave", "name": "Shockwave", "effect_type": "effect_unlock", "value": "shockwave"},
	],
}

## Return the complete definition registry.
static func _skill_defs() -> Dictionary:
	return {
	&"defend": {
		"skill_id": &"defend",
		"name": "Defend",
		"source_type": SourceType.NORMAL,
		"usage_type": UsageType.ACTIVE,
		"class_id": -1,
		"rank": Rank.BASIC,
		"level": 1,
		"proficiency": 0,
		"base_cost": 100,
		"mp_cost": 10,
		"cooldown": 1,
		"base_damage": 0,
		"damage_type": DamageType.NONE,
		"effects": ["guard"],
		"rank_effects": {Rank.INTERMEDIATE: ["guard_plus"], Rank.ADVANCED: ["reflect"], Rank.MASTER: ["fortress"]},
		"unlock_condition": {},
		"rank_up_condition": DEFAULT_RANK_UP_CONDITION,
		"traits": TRAIT_PACK_MELEE,
	},
	&"magic_shield": {
		"skill_id": &"magic_shield",
		"name": "Magic Shield",
		"source_type": SourceType.NORMAL,
		"usage_type": UsageType.PASSIVE,
		"class_id": -1,
		"rank": Rank.BASIC,
		"level": 1,
		"proficiency": 0,
		"base_cost": 120,
		"mp_cost": 0,
		"cooldown": 0,
		"base_damage": 0,
		"damage_type": DamageType.NONE,
		"effects": ["magic_guard"],
		"rank_effects": {Rank.INTERMEDIATE: ["magic_barrier"], Rank.ADVANCED: ["reflect_spell"], Rank.MASTER: ["arcane_aegis"]},
		"unlock_condition": {},
		"rank_up_condition": DEFAULT_RANK_UP_CONDITION,
		"traits": {},
	},
	&"heavy_strike": _make_class_skill(&"heavy_strike", "Heavy Strike", ClassNames.ClassID.BASIC_WARRIOR, 18, DamageType.PHYSICAL),
	&"fireball": _make_class_skill(&"fireball", "Fireball", ClassNames.ClassID.BASIC_MAGE, 22, DamageType.MAGIC, TRAIT_PACK_FIREBALL),
	&"precise_shot": _make_class_skill(&"precise_shot", "Precise Shot", ClassNames.ClassID.BASIC_ARCHER, 18, DamageType.PHYSICAL),
	&"backstab": _make_class_skill(&"backstab", "Backstab", ClassNames.ClassID.BASIC_ROGUE, 20, DamageType.PHYSICAL),
	&"heal": _make_class_skill(&"heal", "Heal", ClassNames.ClassID.BASIC_CLERIC, 0, DamageType.NONE),
	&"shield_bash": _make_class_skill(&"shield_bash", "Shield Bash", ClassNames.ClassID.BASIC_KNIGHT, 16, DamageType.PHYSICAL),
	&"sword_qi": _make_class_skill(&"sword_qi", "Sword Qi", ClassNames.ClassID.ADV_SWORDMASTER, 28, DamageType.PHYSICAL, TRAIT_PACK_MELEE),
	&"arcane_missile": _make_class_skill(&"arcane_missile", "Arcane Missile", ClassNames.ClassID.ADV_BATTLEMAGE, 26, DamageType.MAGIC, TRAIT_PACK_FIREBALL),
	&"armor_pierce_arrow": _make_class_skill(&"armor_pierce_arrow", "Armor Pierce Arrow", ClassNames.ClassID.ADV_MARKSMAN, 26, DamageType.PHYSICAL),
	&"venom_blade": _make_class_skill(&"venom_blade", "Venom Blade", ClassNames.ClassID.ADV_ASSASSIN, 24, DamageType.PHYSICAL),
	&"holy_nova": _make_class_skill(&"holy_nova", "Holy Nova", ClassNames.ClassID.ADV_HIGHCLERIC, 0, DamageType.NONE),
	&"holy_judgement": _make_class_skill(&"holy_judgement", "Holy Judgement", ClassNames.ClassID.ADV_PALADIN, 30, DamageType.PHYSICAL),
	&"dragon_dive": _make_class_skill(&"dragon_dive", "Dragon Dive", ClassNames.ClassID.SPC_DRAGONKNIGHT, 34, DamageType.PHYSICAL),
	&"nightfall": _make_class_skill(&"nightfall", "Nightfall", ClassNames.ClassID.SPC_NIGHTSHADE, 34, DamageType.PHYSICAL),
	&"imperial_edict": _make_class_skill(&"imperial_edict", "Imperial Edict", ClassNames.ClassID.SPC_SOVEREIGN, 40, DamageType.MAGIC),
	}

## Return the class-to-skill registry.
static func _class_skills() -> Dictionary:
	return {
		ClassNames.ClassID.BASIC_WARRIOR: [&"heavy_strike"],
		ClassNames.ClassID.BASIC_MAGE: [&"fireball"],
		ClassNames.ClassID.BASIC_ARCHER: [&"precise_shot"],
		ClassNames.ClassID.BASIC_ROGUE: [&"backstab"],
		ClassNames.ClassID.BASIC_CLERIC: [&"heal"],
		ClassNames.ClassID.BASIC_KNIGHT: [&"shield_bash"],
		ClassNames.ClassID.ADV_SWORDMASTER: [&"sword_qi"],
		ClassNames.ClassID.ADV_BATTLEMAGE: [&"arcane_missile"],
		ClassNames.ClassID.ADV_MARKSMAN: [&"armor_pierce_arrow"],
		ClassNames.ClassID.ADV_ASSASSIN: [&"venom_blade"],
		ClassNames.ClassID.ADV_HIGHCLERIC: [&"holy_nova"],
		ClassNames.ClassID.ADV_PALADIN: [&"holy_judgement"],
		ClassNames.ClassID.SPC_DRAGONKNIGHT: [&"dragon_dive"],
		ClassNames.ClassID.SPC_NIGHTSHADE: [&"nightfall"],
		ClassNames.ClassID.SPC_SOVEREIGN: [&"imperial_edict"],
	}

## Create a fresh skill definition copy for the requested skill id.
static func get_definition(skill_id: StringName) -> Dictionary:
	var defs: Dictionary = _skill_defs()
	if not defs.has(skill_id):
		return {}
	return (defs[skill_id] as Dictionary).duplicate(true)

## Return true when the skill belongs to a specific class.
static func is_class_skill(skill_id: StringName) -> bool:
	var def: Dictionary = get_definition(skill_id)
	return not def.is_empty() and def["source_type"] == SourceType.CLASS

## Return the current level cap for the given rank.
static func get_rank_cap(rank: int) -> int:
	return RANK_LEVEL_CAPS.get(rank, 99)

## Return the list of class-skill ids for the given class.
static func get_class_skill_ids(class_id: int) -> Array:
	var ids: Array = _class_skills().get(class_id, [])
	return ids.duplicate()

## Return the canonical display name for a skill.
static func get_skill_name(skill_id: StringName) -> String:
	var def: Dictionary = get_definition(skill_id)
	return def.get("name", String(skill_id))

static func _make_class_skill(
	skill_id: StringName,
	display_name: String,
	class_id: int,
	base_damage: int,
	damage_type: int,
	traits: Dictionary = TRAIT_PACK_MELEE
) -> Dictionary:
	return {
		"skill_id": skill_id,
		"name": display_name,
		"source_type": SourceType.CLASS,
		"usage_type": UsageType.ACTIVE,
		"class_id": class_id,
		"rank": Rank.BASIC,
		"level": 1,
		"proficiency": 0,
		"base_cost": 200,
		"mp_cost": 20,
		"cooldown": 2,
		"base_damage": base_damage,
		"damage_type": damage_type,
		"effects": [],
		"rank_effects": {Rank.INTERMEDIATE: ["rank_fx_1"], Rank.ADVANCED: ["rank_fx_2"], Rank.MASTER: ["rank_fx_3"]},
		"unlock_condition": {},
		"rank_up_condition": DEFAULT_RANK_UP_CONDITION,
		"traits": traits,
	}
