extends RefCounted

const DEFAULT_LABEL := "Fixed Curve"

## Build the runtime difficulty profile from a battle definition.
static func from_definition(definition: Dictionary) -> Dictionary:
	var raw = definition.get("difficulty_profile", {})
	if typeof(raw) != TYPE_DICTIONARY:
		raw = {}
	return {
		"label": String(raw.get("label", DEFAULT_LABEL)),
		"enemy_stat_multiplier": maxf(0.1, float(raw.get("enemy_stat_multiplier", 1.0))),
		"exp_multiplier": maxf(0.0, float(raw.get("exp_multiplier", 1.0))),
		"resource_multiplier": maxf(0.0, float(raw.get("resource_multiplier", 1.0))),
		"ai_tier": String(raw.get("ai_tier", "baseline")),
	}

## Apply the profile to an enemy HP value.
static func scale_enemy_hp(base_hp: int, profile: Dictionary) -> int:
	return maxi(1, int(round(float(base_hp) * _enemy_stat_multiplier(profile))))

## Apply the profile to all numeric enemy attributes in a battle definition.
static func scale_enemy_stats(base_stats: Dictionary, profile: Dictionary) -> Dictionary:
	var scaled := base_stats.duplicate(true)
	var multiplier := _enemy_stat_multiplier(profile)
	for key in scaled.keys():
		if typeof(scaled[key]) in [TYPE_INT, TYPE_FLOAT]:
			scaled[key] = maxi(1, int(round(float(scaled[key]) * multiplier)))
	return scaled

## Human-readable summary for HUD and menu surfaces.
static func format_summary(profile: Dictionary) -> String:
	return "%s | Enemy %.1fx | EXP %.1fx | Resources %.1fx" % [
		String(profile.get("label", DEFAULT_LABEL)),
		_enemy_stat_multiplier(profile),
		float(profile.get("exp_multiplier", 1.0)),
		float(profile.get("resource_multiplier", 1.0)),
	]

static func _enemy_stat_multiplier(profile: Dictionary) -> float:
	return maxf(0.1, float(profile.get("enemy_stat_multiplier", 1.0)))
