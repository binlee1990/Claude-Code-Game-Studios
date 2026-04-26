class_name ClassNames
extends RefCounted

## Class ID enum — all 15 classes across 3 tiers
enum ClassID {
	BASIC_WARRIOR,
	BASIC_MAGE,
	BASIC_ARCHER,
	BASIC_ROGUE,
	BASIC_CLERIC,
	BASIC_KNIGHT,
	ADV_SWORDMASTER,
	ADV_BATTLEMAGE,
	ADV_MARKSMAN,
	ADV_ASSASSIN,
	ADV_HIGHCLERIC,
	ADV_PALADIN,
	SPC_DRAGONKNIGHT,
	SPC_NIGHTSHADE,
	SPC_SOVEREIGN,
}

## Class state machine states
enum ClassState {
	NONE,
	BASIC_ACTIVE,
	ADVANCED_UNLOCKED,
	ADVANCED_ACTIVE,
	SPECIAL_UNLOCKED,
	SPECIAL_ACTIVE,
}

## Class tier constants
const TIER_BASIC: int = 0
const TIER_ADVANCED: int = 1
const TIER_SPECIAL: int = 2

## Experience caps per tier
const EXP_CAP_BASIC: int = 1000
const EXP_CAP_ADVANCED: int = 2000
const EXP_CAP_SPECIAL: int = 2000

## Class experience formula parameters
const DMG_EXP_COEFFICIENT: float = 0.02
const DMG_EXP_CAP: int = 500
const KILL_BONUS: int = 10
const BATTLE_BONUS: int = 20

## Special class achievement costs
const SPC_COST_LOW: int = 2000
const SPC_COST_HIGH: int = 3000

## Class definitions: { class_id: { tier, primary_attr, secondary_attr, primary_threshold, secondary_threshold, exp_required, spc_cost, exp_cap } }
const CLASS_DEFS: Dictionary = {
	ClassID.BASIC_WARRIOR: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.STR,
		"secondary_attr": AttributeNames.Attribute.CON,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.BASIC_MAGE: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.INT,
		"secondary_attr": AttributeNames.Attribute.CHA,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.BASIC_ARCHER: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.AGI,
		"secondary_attr": AttributeNames.Attribute.STR,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.BASIC_ROGUE: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.AGI,
		"secondary_attr": AttributeNames.Attribute.LUK,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.BASIC_CLERIC: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.CHA,
		"secondary_attr": AttributeNames.Attribute.INT,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.BASIC_KNIGHT: {
		"tier": TIER_BASIC,
		"primary_attr": AttributeNames.Attribute.CON,
		"secondary_attr": AttributeNames.Attribute.STR,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_BASIC,
	},
	ClassID.ADV_SWORDMASTER: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.STR,
		"secondary_attr": AttributeNames.Attribute.AGI,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.ADV_BATTLEMAGE: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.INT,
		"secondary_attr": AttributeNames.Attribute.STR,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.ADV_MARKSMAN: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.AGI,
		"secondary_attr": AttributeNames.Attribute.STR,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.ADV_ASSASSIN: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.AGI,
		"secondary_attr": AttributeNames.Attribute.LUK,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.ADV_HIGHCLERIC: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.CHA,
		"secondary_attr": AttributeNames.Attribute.INT,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.ADV_PALADIN: {
		"tier": TIER_ADVANCED,
		"primary_attr": AttributeNames.Attribute.CON,
		"secondary_attr": AttributeNames.Attribute.CHA,
		"primary_threshold": 50,
		"secondary_threshold": 40,
		"exp_required": 500,
		"spc_cost": 0,
		"exp_cap": EXP_CAP_ADVANCED,
	},
	ClassID.SPC_DRAGONKNIGHT: {
		"tier": TIER_SPECIAL,
		"primary_attr": AttributeNames.Attribute.STR,
		"secondary_attr": AttributeNames.Attribute.CON,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": SPC_COST_LOW,
		"exp_cap": EXP_CAP_SPECIAL,
	},
	ClassID.SPC_NIGHTSHADE: {
		"tier": TIER_SPECIAL,
		"primary_attr": AttributeNames.Attribute.AGI,
		"secondary_attr": AttributeNames.Attribute.LUK,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": SPC_COST_LOW,
		"exp_cap": EXP_CAP_SPECIAL,
	},
	ClassID.SPC_SOVEREIGN: {
		"tier": TIER_SPECIAL,
		"primary_attr": AttributeNames.Attribute.CHA,
		"secondary_attr": AttributeNames.Attribute.INT,
		"primary_threshold": 0,
		"secondary_threshold": 0,
		"exp_required": 0,
		"spc_cost": SPC_COST_HIGH,
		"exp_cap": EXP_CAP_SPECIAL,
	},
}

## Per-class stat bonuses: [STR, AGI, CON, INT, CHA, LUK, WIL, RES, SOU]
const CLASS_BONUSES: Dictionary = {
	ClassID.BASIC_WARRIOR:   [10,  0,  5,  0,  0,  0,  0,  0,  0],
	ClassID.BASIC_MAGE:      [ 0,  0, -5, 15,  0,  0,  0,  0,  0],
	ClassID.BASIC_ARCHER:    [ 5, 10,  0,  0,  0,  0,  0,  0,  0],
	ClassID.BASIC_ROGUE:     [ 0, 15,  0,  0,  0,  5,  0,  0,  0],
	ClassID.BASIC_CLERIC:    [ 0,  0,  0,  5, 10,  0,  0,  5,  0],
	ClassID.BASIC_KNIGHT:    [ 5,  0, 15,  0,  0,  0,  0,  0,  0],
	ClassID.ADV_SWORDMASTER: [15,  5,  5,  0,  0,  0,  0,  0,  0],
	ClassID.ADV_BATTLEMAGE:  [ 5,  0, -5, 20,  0,  0,  0,  5,  0],
	ClassID.ADV_MARKSMAN:    [ 5, 15,  0,  0,  0,  5,  0,  0,  0],
	ClassID.ADV_ASSASSIN:    [ 0, 20,  0,  0,  0, 10,  0,  0,  0],
	ClassID.ADV_HIGHCLERIC:  [ 0,  0,  5, 10, 15,  0,  0,  5,  0],
	ClassID.ADV_PALADIN:     [10,  0, 20,  0,  5,  0,  0,  0,  0],
	ClassID.SPC_DRAGONKNIGHT:[20,  0, 10,  0,  0,  0,  5,  5,  0],
	ClassID.SPC_NIGHTSHADE:  [ 0, 25,  0,  0,  0, 15,  0,  0,  5],
	ClassID.SPC_SOVEREIGN:   [10,  5, 10, 10, 15,  5,  5,  5,  5],
}

## Per-class base HP (used by HpFormula). Reflects archetype durability.
const CLASS_BASE_HP: Dictionary = {
	ClassID.BASIC_WARRIOR:    40,
	ClassID.BASIC_MAGE:       25,
	ClassID.BASIC_ARCHER:     28,
	ClassID.BASIC_ROGUE:      28,
	ClassID.BASIC_CLERIC:     32,
	ClassID.BASIC_KNIGHT:     50,
	ClassID.ADV_SWORDMASTER:  45,
	ClassID.ADV_BATTLEMAGE:   30,
	ClassID.ADV_MARKSMAN:     32,
	ClassID.ADV_ASSASSIN:     30,
	ClassID.ADV_HIGHCLERIC:   38,
	ClassID.ADV_PALADIN:      55,
	ClassID.SPC_DRAGONKNIGHT: 60,
	ClassID.SPC_NIGHTSHADE:   35,
	ClassID.SPC_SOVEREIGN:    45,
}

static func get_class_base_hp(class_id: int) -> int:
	return CLASS_BASE_HP.get(class_id, 30)

static func get_tier(class_id: int) -> int:
	return CLASS_DEFS[class_id]["tier"]

static func get_exp_cap(class_id: int) -> int:
	return CLASS_DEFS[class_id]["exp_cap"]

static func get_class_bonus(class_id: int, attr_type: int) -> int:
	if not CLASS_BONUSES.has(class_id):
		return 0
	var bonuses: Array = CLASS_BONUSES[class_id]
	var idx: int = attr_type
	if idx < 0 or idx >= bonuses.size():
		return 0
	return bonuses[idx]

static func is_basic(class_id: int) -> bool:
	return CLASS_DEFS[class_id]["tier"] == TIER_BASIC

static func is_advanced(class_id: int) -> bool:
	return CLASS_DEFS[class_id]["tier"] == TIER_ADVANCED

static func is_special(class_id: int) -> bool:
	return CLASS_DEFS[class_id]["tier"] == TIER_SPECIAL

## Calculate class experience gain from combat performance (formula D.2)
static func calculate_exp_gain(damage_dealt: int, is_kill: bool, is_battle: bool) -> int:
	var dmg_exp: int = mini(int(damage_dealt * DMG_EXP_COEFFICIENT), DMG_EXP_CAP)
	var kill_exp: int = KILL_BONUS if is_kill else 0
	var battle_exp: int = BATTLE_BONUS if is_battle else 0
	return dmg_exp + kill_exp + battle_exp
