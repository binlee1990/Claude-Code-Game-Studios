class_name Chapter03PressureModel
extends RefCounted

const DEFAULT_BEACON_TURNS_REQUIRED: int = 2
const DEFAULT_MIN_CIVILIANS_FOR_NEUTRAL: int = 2

static func evaluate_pressure(story_progress: Dictionary, pressure_def: Dictionary = {}) -> Dictionary:
	var rescued_key := String(pressure_def.get("civilian_rescued_key", "chapter_03_battle_1_civilians_rescued"))
	var defeated_key := String(pressure_def.get("e1_defeated_key", "chapter_03_act_a_e1_defeated_in_6_turns"))
	var neutral_count := int(pressure_def.get("neutral_civilian_rescued_count", DEFAULT_MIN_CIVILIANS_FOR_NEUTRAL))
	var rescued_count := int(story_progress.get(rescued_key, neutral_count))
	var enemy_morale_bonus := 1 if rescued_count < int(pressure_def.get("min_civilians_for_neutral", DEFAULT_MIN_CIVILIANS_FOR_NEUTRAL)) else 0
	return {
		"civilian_rescued_count": rescued_count,
		"enemy_morale_bonus": enemy_morale_bonus,
		"advance_hint": bool(story_progress.get(defeated_key, false)),
		"beacon_turns_required": int(pressure_def.get("beacon_turns_required", DEFAULT_BEACON_TURNS_REQUIRED)),
	}

static func update_beacon_hold(previous_state: Dictionary, beacon_owner: String, turns_required: int = DEFAULT_BEACON_TURNS_REQUIRED) -> Dictionary:
	var held_turns := int(previous_state.get("held_turns", 0))
	if beacon_owner == "player":
		held_turns += 1
	else:
		held_turns = 0
	return {
		"beacon_owner": beacon_owner,
		"held_turns": held_turns,
		"turns_required": turns_required,
		"victory_ready": held_turns >= turns_required,
	}

static func apply_behavior_scoring(story_progress: Dictionary, scoring_def: Dictionary = {}) -> Dictionary:
	var belief_values: Dictionary = B3GateEvaluator.normalize_values(story_progress.get("belief_values", {}))
	var deltas := {"ren": 0, "yi": 0, "zhi": 0}

	var total_civilians := int(scoring_def.get("total_civilians", 3))
	var rescued_count := int(story_progress.get("chapter_03_act_b_civilians_rescued", total_civilians))
	var civilian_deaths := int(story_progress.get("chapter_03_act_b_civilian_deaths", 0))
	var clear_turns := int(story_progress.get("chapter_03_act_b_clear_turn", int(scoring_def.get("default_clear_turn", 8))))
	var supply_interactions := int(story_progress.get("chapter_03_act_b_supply_interactions", int(scoring_def.get("default_supply_interactions", 1))))

	if rescued_count >= total_civilians:
		deltas["ren"] += int(scoring_def.get("all_civilians_ren", 6))
	if clear_turns <= int(scoring_def.get("fast_clear_turn", 8)):
		deltas["yi"] += int(scoring_def.get("fast_clear_yi", 6))
	if supply_interactions > 0:
		deltas["zhi"] += int(scoring_def.get("supply_interaction_zhi", 6))
	if civilian_deaths > 0:
		deltas["ren"] -= int(scoring_def.get("civilian_death_ren_penalty", 5)) * civilian_deaths
		deltas["yi"] += int(scoring_def.get("civilian_death_yi_bonus", 2)) * civilian_deaths

	for route in B3GateEvaluator.ROUTES:
		belief_values[route] = clampi(int(belief_values.get(route, 0)) + int(deltas[route]), BeliefSystem.BELIEF_MIN, BeliefSystem.BELIEF_MAX)
	story_progress["belief_values"] = belief_values
	story_progress["chapter_03_act_b_behavior_deltas"] = deltas
	return {"belief_values": belief_values.duplicate(true), "deltas": deltas}
