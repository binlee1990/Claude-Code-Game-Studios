class_name SkillData
extends RefCounted

## Mutable per-skill state and formulas for progression, traits, and cooldowns.

var skill_id: StringName = &""
var name: String = ""
var source_type: int = SkillDefinitions.SourceType.NORMAL
var usage_type: int = SkillDefinitions.UsageType.ACTIVE
var class_id: int = -1
var rank: int = SkillDefinitions.Rank.BASIC
var level: int = 1
var proficiency: int = 0
var max_proficiency: int = 100
var base_cost: int = 100
var mp_cost: int = 0
var cooldown: int = 0
var cooldown_remaining: int = 0
var base_damage: int = 0
var damage_type: int = SkillDefinitions.DamageType.NONE
var effects: Array = []
var unlocked_effects: Array = []
var unlock_condition: Dictionary = {}
var rank_up_condition: Dictionary = {}
var traits: Dictionary = {}
var selected_traits: Dictionary = {}
var pending_trait_levels: Dictionary = {}
var frozen: bool = false

func _init(definition: Dictionary = {}) -> void:
	if not definition.is_empty():
		apply_definition(definition)

## Apply a definition dictionary and initialize derived state.
func apply_definition(definition: Dictionary) -> void:
	skill_id = definition.get("skill_id", skill_id)
	name = definition.get("name", name)
	source_type = definition.get("source_type", source_type)
	usage_type = definition.get("usage_type", usage_type)
	class_id = definition.get("class_id", class_id)
	rank = definition.get("rank", rank)
	level = definition.get("level", level)
	proficiency = definition.get("proficiency", proficiency)
	base_cost = definition.get("base_cost", base_cost)
	mp_cost = definition.get("mp_cost", mp_cost)
	cooldown = definition.get("cooldown", cooldown)
	cooldown_remaining = definition.get("cooldown_remaining", cooldown_remaining)
	base_damage = definition.get("base_damage", base_damage)
	damage_type = definition.get("damage_type", damage_type)
	effects = definition.get("effects", []).duplicate(true)
	unlocked_effects = definition.get("unlocked_effects", []).duplicate(true)
	unlock_condition = definition.get("unlock_condition", {}).duplicate(true)
	rank_up_condition = definition.get("rank_up_condition", {}).duplicate(true)
	traits = definition.get("traits", {}).duplicate(true)
	selected_traits = definition.get("selected_traits", {}).duplicate(true)
	pending_trait_levels = definition.get("pending_trait_levels", {}).duplicate(true)
	frozen = definition.get("frozen", frozen)
	max_proficiency = definition.get("max_proficiency", calculate_max_proficiency(level, base_cost))

## Calculate the max proficiency required for a skill level.
static func calculate_max_proficiency(skill_level: int, skill_base_cost: int) -> int:
	return maxi(1, int(floor(skill_base_cost * pow(skill_level, 1.5))))

## Calculate proficiency gain for one battle reward event.
static func calculate_proficiency_gain(base_proficiency: int, synergy_bonus: float, talent_bonus: float) -> int:
	var multiplier: float = 1.0 + synergy_bonus + talent_bonus
	return maxi(0, int(floor(base_proficiency * multiplier)))

## Apply battle proficiency and handle level-ups plus overflow.
func apply_proficiency_gain(base_proficiency: int, synergy_bonus: float = 0.0, talent_bonus: float = 0.0) -> Dictionary:
	if frozen:
		return {"gained": 0, "levels_gained": 0, "trait_triggers": []}

	var gained: int = calculate_proficiency_gain(base_proficiency, synergy_bonus, talent_bonus)
	var levels_gained: int = 0
	var trait_triggers: Array = []
	proficiency += gained

	while proficiency >= max_proficiency and level < SkillDefinitions.get_rank_cap(rank):
		proficiency -= max_proficiency
		level += 1
		levels_gained += 1
		max_proficiency = calculate_max_proficiency(level, base_cost)
		if [10, 20, 30].has(level) and traits.has(level) and not selected_traits.has(level):
			pending_trait_levels[level] = true
			trait_triggers.append({"level": level, "available_traits": get_available_traits(level)})

	if level >= SkillDefinitions.get_rank_cap(rank):
		proficiency = mini(proficiency, max_proficiency)

	return {"gained": gained, "levels_gained": levels_gained, "trait_triggers": trait_triggers}

## Returns true when the skill has reached its current rank ceiling.
func is_at_rank_ceiling() -> bool:
	return level >= SkillDefinitions.get_rank_cap(rank)

## Returns true when the skill may advance to the next rank.
func can_advance_rank(hidden_attr_value: int = 0, challenge_passed: bool = false) -> bool:
	match rank:
		SkillDefinitions.Rank.BASIC:
			return level >= SkillDefinitions.get_rank_cap(rank) and hidden_attr_value >= rank_up_condition.get("intermediate_hidden_attr_threshold", 50)
		SkillDefinitions.Rank.INTERMEDIATE:
			return level >= SkillDefinitions.get_rank_cap(rank) and hidden_attr_value >= rank_up_condition.get("advanced_hidden_attr_threshold", 100)
		SkillDefinitions.Rank.ADVANCED:
			return level >= SkillDefinitions.get_rank_cap(rank) and (
				not rank_up_condition.get("master_requires_challenge", true) or challenge_passed
			)
		_:
			return false

## Advance the skill to the next rank when conditions are satisfied.
func advance_rank(hidden_attr_value: int = 0, challenge_passed: bool = false) -> bool:
	if not can_advance_rank(hidden_attr_value, challenge_passed):
		return false
	rank += 1
	unlocked_effects.append_array((get_rank_effects(rank)).duplicate())
	return true

## Return the effects unlocked specifically by the given rank.
func get_rank_effects(target_rank: int) -> Array:
	var def: Dictionary = SkillDefinitions.get_definition(skill_id)
	var rank_effect_map: Dictionary = def.get("rank_effects", {})
	return rank_effect_map.get(target_rank, []).duplicate(true)

## Return the trait options available at a milestone level.
func get_available_traits(trigger_level: int) -> Array:
	return traits.get(trigger_level, []).duplicate(true)

## Returns true when the skill still requires a trait choice at the given level.
func is_trait_pending(trigger_level: int) -> bool:
	return bool(pending_trait_levels.get(trigger_level, false)) and not selected_traits.has(trigger_level)

## Select a trait for a milestone level.
func select_trait(trigger_level: int, trait_id: String) -> bool:
	for trait_data in get_available_traits(trigger_level):
		if trait_data.get("trait_id", "") == trait_id:
			selected_traits[trigger_level] = trait_data.duplicate(true)
			pending_trait_levels.erase(trigger_level)
			return true
	return false

## Return the currently selected trait ids in milestone order.
func get_selected_trait_ids() -> Array:
	var out: Array = []
	var levels: Array = selected_traits.keys()
	levels.sort()
	for trigger_level in levels:
		out.append(selected_traits[trigger_level]["trait_id"])
	return out

## Return the multiplicative damage modifier contributed by selected traits.
func get_trait_multiplier() -> float:
	var multiplier: float = 1.0
	for trigger_level in selected_traits:
		var trait_data: Dictionary = selected_traits[trigger_level]
		if trait_data.get("effect_type", "") == "damage_mult":
			multiplier *= float(trait_data.get("value", 1.0))
	return multiplier

## Return the additive range bonus contributed by selected traits.
func get_range_bonus() -> int:
	var bonus: int = 0
	for trigger_level in selected_traits:
		var trait_data: Dictionary = selected_traits[trigger_level]
		if trait_data.get("effect_type", "") == "range_add":
			bonus += int(trait_data.get("value", 0))
	return bonus

## Return the multiplicative level bonus used by the skill-damage formula.
func get_level_multiplier() -> float:
	return 1.0 + float(level - 1) * 0.1

## Calculate final skill damage from trait, level, and attribute bonuses.
func calculate_damage(attribute_bonus: float) -> int:
	var final_damage: float = base_damage * get_level_multiplier() * get_trait_multiplier() * (1.0 + attribute_bonus)
	return int(round(final_damage))

## Set the remaining cooldown after using the skill.
func trigger_cooldown() -> void:
	cooldown_remaining = cooldown

## Reduce remaining cooldown by one battle turn.
func tick_cooldown() -> void:
	cooldown_remaining = maxi(0, cooldown_remaining - 1)

## Return true when this skill may currently be executed.
func is_available(mp_available: int) -> bool:
	if usage_type != SkillDefinitions.UsageType.ACTIVE:
		return false
	return cooldown_remaining <= 0 and mp_available >= mp_cost

## Serialize the full mutable skill state.
func serialize() -> Dictionary:
	return {
		"skill_id": skill_id,
		"name": name,
		"source_type": source_type,
		"usage_type": usage_type,
		"class_id": class_id,
		"rank": rank,
		"level": level,
		"proficiency": proficiency,
		"max_proficiency": max_proficiency,
		"base_cost": base_cost,
		"mp_cost": mp_cost,
		"cooldown": cooldown,
		"cooldown_remaining": cooldown_remaining,
		"base_damage": base_damage,
		"damage_type": damage_type,
		"effects": effects.duplicate(true),
		"unlocked_effects": unlocked_effects.duplicate(true),
		"unlock_condition": unlock_condition.duplicate(true),
		"rank_up_condition": rank_up_condition.duplicate(true),
		"traits": traits.duplicate(true),
		"selected_traits": selected_traits.duplicate(true),
		"pending_trait_levels": pending_trait_levels.duplicate(true),
		"frozen": frozen,
	}

## Rebuild a SkillData instance from serialized state.
static func deserialize(data: Dictionary) -> SkillData:
	return SkillData.new(data)
