class_name DifficultyBridge
extends RefCounted

## Bridges DifficultyManager (chapter-to-phase autoload) to BattleDifficultyProfile
## (battle-definition-driven profile) format. Callers that already read from
## battle_definition.difficulty_profile can optionally override with chapter-scaled
## values through this bridge.

## Convert a DifficultyManager-style profile into the format expected by
## BattleDifficultyProfile consumers (battle_arena, settlement, HUD).
static func to_battle_profile(manager_profile: Dictionary) -> Dictionary:
	return {
		"label": _phase_label(int(manager_profile.get("phase", 2))),
		"enemy_stat_multiplier": float(manager_profile.get("enemy_stat_mult", 1.0)),
		"exp_multiplier": float(manager_profile.get("exp_mult", 1.0)),
		"resource_multiplier": float(manager_profile.get("resource_mult", 1.0)),
		"ai_tier": _ai_tier_name(int(manager_profile.get("ai_strategy_level", 0))),
	}

## Merge a DifficultyManager profile into an existing battle_definition difficulty_profile,
## giving the manager's chapter-scaled values priority over JSON defaults.
static func merge_with_definition(chapter: int, definition_profile: Dictionary) -> Dictionary:
	if not Engine.has_singleton("DifficultyManager"):
		return definition_profile.duplicate(true)
	var dm := Engine.get_singleton("DifficultyManager")
	if dm == null:
		return definition_profile.duplicate(true)
	var chapter_profile: Dictionary = dm.get_profile(chapter)
	var merged := definition_profile.duplicate(true)
	if chapter_profile.get("enemy_stat_mult", 1.0) != 1.0:
		merged["enemy_stat_multiplier"] = float(chapter_profile.get("enemy_stat_mult", 1.0))
	if chapter_profile.get("exp_mult", 1.0) != 1.0:
		merged["exp_multiplier"] = float(chapter_profile.get("exp_mult", 1.0))
	if chapter_profile.get("resource_mult", 1.0) != 1.0:
		merged["resource_multiplier"] = float(chapter_profile.get("resource_mult", 1.0))
	merged["ai_tier"] = _ai_tier_name(int(chapter_profile.get("ai_strategy_level", 0)))
	return merged

static func _phase_label(phase: int) -> String:
	match phase:
		1: return "Tutorial"
		2: return "Growth"
		3: return "Challenge"
		4: return "Climax"
		_: return "Growth"

static func _ai_tier_name(level: int) -> String:
	match level:
		0: return "baseline"
		1: return "advanced"
		2: return "optimal"
		_: return "baseline"
