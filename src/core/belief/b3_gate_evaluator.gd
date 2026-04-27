class_name B3GateEvaluator
extends RefCounted

const ROUTES: Array[String] = ["ren", "yi", "zhi"]
const FALLBACK_ROUTE: String = "zhi"
const SOFT_LOCK_THRESHOLD: int = 20

static func evaluate(belief_values: Dictionary, evaluated_after: String = "chapter_03_act_b") -> Dictionary:
	var values := normalize_values(belief_values)
	var ranked: Array[Dictionary] = []
	for route in ROUTES:
		ranked.append({"route": route, "value": int(values.get(route, 0))})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["value"]) > int(b["value"])
	)

	var top_value: int = int(ranked[0]["value"])
	var second_value: int = int(ranked[1]["value"])
	var tied_top_count: int = 0
	for row in ranked:
		if int(row["value"]) == top_value:
			tied_top_count += 1

	var dominant_route := String(ranked[0]["route"])
	var fallback_used := tied_top_count > 1
	if fallback_used:
		dominant_route = FALLBACK_ROUTE
	var margin: int = 0 if fallback_used else top_value - second_value

	return {
		"dominant_route": dominant_route,
		"margin": margin,
		"soft_lock_candidate": margin >= SOFT_LOCK_THRESHOLD,
		"evaluated_after": evaluated_after,
		"values": values,
		"fallback_used": fallback_used,
	}

static func evaluate_and_persist(story_progress: Dictionary, evaluated_after: String = "chapter_03_act_b") -> Dictionary:
	var result := evaluate(story_progress.get("belief_values", {}), evaluated_after)
	story_progress["belief_values"] = result["values"].duplicate(true)
	story_progress["b3_gate"] = {
		"dominant_route": result["dominant_route"],
		"margin": result["margin"],
		"soft_lock_candidate": result["soft_lock_candidate"],
		"evaluated_after": result["evaluated_after"],
	}
	return result

static func get_persisted_route(story_progress: Dictionary) -> String:
	var gate: Dictionary = story_progress.get("b3_gate", {})
	var route := String(gate.get("dominant_route", ""))
	if ROUTES.has(route):
		return route
	return FALLBACK_ROUTE

static func normalize_values(belief_values: Dictionary) -> Dictionary:
	return {
		"ren": clampi(int(belief_values.get("ren", 0)), BeliefSystem.BELIEF_MIN, BeliefSystem.BELIEF_MAX),
		"yi": clampi(int(belief_values.get("yi", 0)), BeliefSystem.BELIEF_MIN, BeliefSystem.BELIEF_MAX),
		"zhi": clampi(int(belief_values.get("zhi", 0)), BeliefSystem.BELIEF_MIN, BeliefSystem.BELIEF_MAX),
	}
