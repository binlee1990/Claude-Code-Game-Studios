class_name EquipmentAffixGenerator
extends RefCounted

static func generate_affix(quality: int, forced_type: int = -1, rng_seed: int = 0) -> Dictionary:
	var affix_type: int = forced_type if forced_type >= 0 else _pick_affix_type(rng_seed)
	var range: Dictionary = EquipmentDefinitions.QUALITY_AFFIX_RANGES.get(
		quality,
		EquipmentDefinitions.QUALITY_AFFIX_RANGES[EquipmentDefinitions.Quality.WHITE]
	)
	var rolled: int = _roll_int(range["min"], range["max"], rng_seed)
	var value: int = int(round(float(rolled) * EquipmentDefinitions.get_quality_multiplier(quality)))
	return {
		"type": affix_type,
		"value": value,
		"category": EquipmentDefinitions.get_affix_definition(affix_type).get("category", -1),
		"attribute_type": EquipmentDefinitions.get_affix_attribute_type(affix_type),
		"stat_key": EquipmentDefinitions.get_affix_stat_key(affix_type),
	}

static func generate_affixes(quality: int, count: int = -1, rng_seed: int = 0) -> Array:
	var final_count: int = count if count >= 0 else EquipmentDefinitions.get_affix_capacity(quality)
	var out: Array = []
	for i in range(final_count):
		var seed: int = rng_seed + i + 1 if rng_seed != 0 else 0
		out.append(generate_affix(quality, -1, seed))
	return out

static func _pick_affix_type(rng_seed: int = 0) -> int:
	var total_weight: int = 0
	for affix_type in EquipmentDefinitions.AFFIX_DEFS:
		total_weight += int(EquipmentDefinitions.AFFIX_DEFS[affix_type]["weight"])
	var roll: int = _roll_int(1, total_weight, rng_seed)
	var cursor: int = 0
	for affix_type in EquipmentDefinitions.AFFIX_DEFS:
		cursor += int(EquipmentDefinitions.AFFIX_DEFS[affix_type]["weight"])
		if roll <= cursor:
			return affix_type
	return EquipmentDefinitions.AffixType.STR

static func _roll_int(min_value: int, max_value: int, rng_seed: int = 0) -> int:
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	return rng.randi_range(min_value, max_value)
