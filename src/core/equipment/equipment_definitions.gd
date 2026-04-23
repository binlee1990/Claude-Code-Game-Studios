class_name EquipmentDefinitions
extends RefCounted

enum Slot {
	WEAPON,
	ARMOR,
	HELMET,
	LEGS,
	BOOTS,
	ACCESSORY,
}

enum Quality {
	WHITE,
	GREEN,
	BLUE,
	PURPLE,
	GOLD,
}

enum AffixCategory {
	ATTACK,
	DEFENSE,
	SURVIVAL,
	SPECIAL,
}

enum AffixType {
	STR,
	AGI,
	INT,
	CRIT_RATE,
	CON,
	DEFENSE,
	RESIST,
	HP,
	REGEN,
	MOVEMENT,
	RANGE,
	SKILL_EFFECT,
}

enum SetId {
	WARRIOR_POWER,
	MAGE_WISDOM,
	ARCHER_PRECISION,
	KNIGHT_GLORY,
}

const NO_SET: int = -1

const QUALITY_AFFIX_COUNTS: Dictionary = {
	Quality.WHITE: 1,
	Quality.GREEN: 2,
	Quality.BLUE: 3,
	Quality.PURPLE: 4,
	Quality.GOLD: 4,
}

const QUALITY_MULTIPLIERS: Dictionary = {
	Quality.WHITE: 1.0,
	Quality.GREEN: 1.5,
	Quality.BLUE: 2.0,
	Quality.PURPLE: 3.0,
	Quality.GOLD: 5.0,
}

const QUALITY_BASE_ATTRIBUTE_RANGES: Dictionary = {
	Quality.WHITE: {"min": 5, "max": 10},
	Quality.GREEN: {"min": 10, "max": 18},
	Quality.BLUE: {"min": 18, "max": 30},
	Quality.PURPLE: {"min": 30, "max": 45},
	Quality.GOLD: {"min": 45, "max": 70},
}

const QUALITY_AFFIX_RANGES: Dictionary = {
	Quality.WHITE: {"min": 1, "max": 3},
	Quality.GREEN: {"min": 2, "max": 6},
	Quality.BLUE: {"min": 4, "max": 12},
	Quality.PURPLE: {"min": 8, "max": 20},
	Quality.GOLD: {"min": 12, "max": 30},
}

const QUALITY_ENHANCEMENT_CAPS: Dictionary = {
	Quality.WHITE: 5,
	Quality.GREEN: 10,
	Quality.BLUE: 15,
	Quality.PURPLE: 20,
	Quality.GOLD: 25,
}

const RISK_ZONE_SUCCESS_RATES: Dictionary = {
	5: 0.70,
	6: 0.60,
	7: 0.50,
	8: 0.40,
	9: 0.30,
	10: 0.25,
	11: 0.20,
	12: 0.15,
	13: 0.10,
	14: 0.05,
}

const SLOT_PRIMARY_STATS: Dictionary = {
	Slot.WEAPON: "attack",
	Slot.ARMOR: "defense",
	Slot.HELMET: "defense",
	Slot.LEGS: "defense",
	Slot.BOOTS: "speed",
	Slot.ACCESSORY: "focus",
}

const AFFIX_DEFS: Dictionary = {
	AffixType.STR: {"category": AffixCategory.ATTACK, "attribute_type": AttributeNames.Attribute.STR, "weight": 20},
	AffixType.AGI: {"category": AffixCategory.ATTACK, "attribute_type": AttributeNames.Attribute.AGI, "weight": 20},
	AffixType.INT: {"category": AffixCategory.ATTACK, "attribute_type": AttributeNames.Attribute.INT, "weight": 20},
	AffixType.CRIT_RATE: {"category": AffixCategory.ATTACK, "stat_key": "crit_rate", "weight": 10},
	AffixType.CON: {"category": AffixCategory.DEFENSE, "attribute_type": AttributeNames.Attribute.CON, "weight": 20},
	AffixType.DEFENSE: {"category": AffixCategory.DEFENSE, "stat_key": "defense", "weight": 15},
	AffixType.RESIST: {"category": AffixCategory.DEFENSE, "attribute_type": AttributeNames.Attribute.RES, "weight": 10},
	AffixType.HP: {"category": AffixCategory.SURVIVAL, "stat_key": "hp", "weight": 15},
	AffixType.REGEN: {"category": AffixCategory.SURVIVAL, "stat_key": "regen", "weight": 10},
	AffixType.MOVEMENT: {"category": AffixCategory.SPECIAL, "stat_key": "movement", "weight": 4},
	AffixType.RANGE: {"category": AffixCategory.SPECIAL, "stat_key": "range", "weight": 3},
	AffixType.SKILL_EFFECT: {"category": AffixCategory.SPECIAL, "stat_key": "skill_effect", "weight": 3},
}

const DECOMPOSITION_REWARDS: Dictionary = {
	Quality.WHITE: {"basic_materials": 2, "rare_materials": 0, "rare_chance": 0.0},
	Quality.GREEN: {"basic_materials": 5, "rare_materials": 0, "rare_chance": 0.0},
	Quality.BLUE: {"basic_materials": 10, "rare_materials": 1, "rare_chance": 0.20},
	Quality.PURPLE: {"basic_materials": 20, "rare_materials": 2, "rare_chance": 0.50},
	Quality.GOLD: {"basic_materials": 50, "rare_materials": 5, "rare_chance": 1.0},
}

const SET_BONUSES: Dictionary = {
	SetId.WARRIOR_POWER: {
		"name": "Warrior's Power",
		"two_piece": {"attributes": {AttributeNames.Attribute.STR: 10}, "stats": {"hp": 100}},
		"four_piece": {"effects": {"double_damage_chance": 0.20}},
	},
	SetId.MAGE_WISDOM: {
		"name": "Mage's Wisdom",
		"two_piece": {"attributes": {AttributeNames.Attribute.INT: 10}, "stats": {"mp": 50}},
		"four_piece": {"effects": {"skill_damage_mult": 0.15}},
	},
	SetId.ARCHER_PRECISION: {
		"name": "Archer's Precision",
		"two_piece": {"attributes": {AttributeNames.Attribute.AGI: 10}, "stats": {"crit_rate": 5}},
		"four_piece": {"effects": {"crit_damage_mult": 0.30}},
	},
	SetId.KNIGHT_GLORY: {
		"name": "Knight's Glory",
		"two_piece": {"attributes": {AttributeNames.Attribute.CON: 10}, "stats": {"defense": 20}},
		"four_piece": {"effects": {"reflect_ratio": 0.10}},
	},
}

static func get_affix_capacity(quality: int) -> int:
	return QUALITY_AFFIX_COUNTS.get(quality, QUALITY_AFFIX_COUNTS[Quality.WHITE])

static func get_quality_multiplier(quality: int) -> float:
	return QUALITY_MULTIPLIERS.get(quality, 1.0)

static func get_enhancement_cap(quality: int) -> int:
	return QUALITY_ENHANCEMENT_CAPS.get(quality, QUALITY_ENHANCEMENT_CAPS[Quality.WHITE])

static func get_success_rate(current_level: int) -> float:
	if current_level < 5:
		return 1.0
	return RISK_ZONE_SUCCESS_RATES.get(current_level, 0.05)

static func get_affix_definition(affix_type: int) -> Dictionary:
	return AFFIX_DEFS.get(affix_type, {})

static func get_affix_attribute_type(affix_type: int) -> int:
	return get_affix_definition(affix_type).get("attribute_type", -1)

static func get_affix_stat_key(affix_type: int) -> String:
	return String(get_affix_definition(affix_type).get("stat_key", ""))

static func generate_base_attributes(slot: int, quality: int, rng_seed: int = 0) -> Dictionary:
	var range: Dictionary = QUALITY_BASE_ATTRIBUTE_RANGES.get(quality, QUALITY_BASE_ATTRIBUTE_RANGES[Quality.WHITE])
	return {SLOT_PRIMARY_STATS.get(slot, "power"): _roll_int(range["min"], range["max"], rng_seed)}

static func calculate_decomposition_rewards(quality: int, rng_seed: int = 0) -> Dictionary:
	var def: Dictionary = DECOMPOSITION_REWARDS.get(quality, DECOMPOSITION_REWARDS[Quality.WHITE])
	var rare_materials: int = 0
	if _roll_chance(def["rare_chance"], rng_seed):
		rare_materials = def["rare_materials"]
	return {
		"basic_materials": def["basic_materials"],
		"rare_materials": rare_materials,
	}

static func pick_random_set_id(rng_seed: int = 0) -> int:
	var set_ids: Array[int] = [
		SetId.WARRIOR_POWER,
		SetId.MAGE_WISDOM,
		SetId.ARCHER_PRECISION,
		SetId.KNIGHT_GLORY,
	]
	return set_ids[_roll_int(0, set_ids.size() - 1, rng_seed)]

static func aggregate_set_bonuses(set_counts: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"attributes": {},
		"stats": {},
		"effects": {},
		"active_sets": {},
	}
	for set_id in set_counts:
		var count: int = int(set_counts[set_id])
		if count < 2:
			continue
		var def: Dictionary = SET_BONUSES.get(set_id, {})
		var tiers: Array = []
		_apply_bonus_payload(out, def.get("two_piece", {}))
		tiers.append(2)
		if count >= 4:
			_apply_bonus_payload(out, def.get("four_piece", {}))
			tiers.append(4)
		out["active_sets"][set_id] = {
			"count": count,
			"tiers": tiers,
			"name": def.get("name", "Unknown Set"),
		}
	return out

static func _apply_bonus_payload(target: Dictionary, payload: Dictionary) -> void:
	_merge_numeric_dict(target["attributes"], payload.get("attributes", {}))
	_merge_numeric_dict(target["stats"], payload.get("stats", {}))
	_merge_numeric_dict(target["effects"], payload.get("effects", {}))

static func _merge_numeric_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[key] = target.get(key, 0) + source[key]

static func _roll_int(min_value: int, max_value: int, rng_seed: int = 0) -> int:
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	return rng.randi_range(min_value, max_value)

static func _roll_chance(chance: float, rng_seed: int = 0) -> bool:
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	return rng.randf() < chance
