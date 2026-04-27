class_name BeliefSystem
extends RefCounted

## Core belief values management (ren/yi/zhi).
## Handles clamped arithmetic, change application, and persistence to SaveData.
##
## Belongs to: Story CH2-c-001
## GDD: design/gdd/chapter-02.md §3.8, design/narrative/belief-branching.md §4.1

const BELIEF_MIN: int = 0
const BELIEF_MAX: int = 100

enum BeliefType {
	REN = 0,  # 仁
	YI  = 1,  # 义
	ZHI = 2,  # 智
}

var _values: Dictionary = {
	BeliefType.REN: 0,
	BeliefType.YI:  0,
	BeliefType.ZHI: 0,
}

## Returns the current value for a belief type.
func get_value(belief: BeliefType) -> int:
	return _values.get(belief, 0)

## Returns all belief values as a dictionary with string keys {"ren": int, "yi": int, "zhi": int}.
## This format matches what BeliefGate.evaluate() expects.
func get_values() -> Dictionary:
	return {
		"ren": _values[BeliefType.REN],
		"yi":  _values[BeliefType.YI],
		"zhi": _values[BeliefType.ZHI],
	}

## Applies a delta to a belief value, clamped to [BELIEF_MIN, BELIEF_MAX].
## Returns the actual amount applied (may be less than delta due to clamping).
func apply_change(belief: BeliefType, delta: int) -> int:
	var current: int = _values.get(belief, 0)
	var new_value: int = clampi(current + delta, BELIEF_MIN, BELIEF_MAX)
	var applied: int = new_value - current
	_values[belief] = new_value
	GameEvents.belief_changed.emit(belief, delta, applied, new_value)
	return applied

## Loads belief values from a SaveData instance.
func load_from_save_data(data: SaveData) -> void:
	var bv: Dictionary = data.story_progress.get("belief_values", {})
	_values[BeliefType.REN] = bv.get("ren", 0)
	_values[BeliefType.YI]  = bv.get("yi",  0)
	_values[BeliefType.ZHI] = bv.get("zhi", 0)

## Persists belief values into SaveData.story_progress.
func save_to_save_data(data: SaveData) -> void:
	if not data.story_progress.has("belief_values"):
		data.story_progress["belief_values"] = {}
	data.story_progress["belief_values"] = {
		"ren": _values[BeliefType.REN],
		"yi":  _values[BeliefType.YI],
		"zhi": _values[BeliefType.ZHI],
	}

static func narrative_choice_uses_runtime_branching(narrative_choice: Dictionary) -> bool:
	return bool(narrative_choice.get("runtime_branching", false))

static func apply_runtime_narrative_choice(story_progress: Dictionary, narrative_choice: Dictionary, option_id: String = "") -> Dictionary:
	if not narrative_choice_uses_runtime_branching(narrative_choice):
		return {"success": false, "reason": "runtime_branching_disabled"}
	var node_id := String(narrative_choice.get("node_id", ""))
	if node_id == "":
		return {"success": false, "reason": "missing_node_id"}
	var selected_option_id := option_id
	if selected_option_id == "":
		selected_option_id = String(narrative_choice.get("default_option_id", ""))
	var option := _find_runtime_option(narrative_choice.get("options", []), selected_option_id)
	if option.is_empty():
		return {"success": false, "reason": "missing_option", "node_id": node_id}

	var values: Dictionary = story_progress.get("belief_values", {}).duplicate(true)
	for key in ["ren", "yi", "zhi"]:
		values[key] = clampi(int(values.get(key, 0)) + int(option.get("belief_delta", {}).get(key, 0)), BELIEF_MIN, BELIEF_MAX)
	story_progress["belief_values"] = values

	var choices: Dictionary = story_progress.get("narrative_choices", {}).duplicate(true)
	choices[node_id] = String(option.get("id", selected_option_id))
	story_progress["narrative_choices"] = choices
	return {
		"success": true,
		"node_id": node_id,
		"option_id": String(option.get("id", selected_option_id)),
		"belief_values": values,
	}

## Resets all belief values to 0. Used for new game.
func reset() -> void:
	_values[BeliefType.REN] = 0
	_values[BeliefType.YI]  = 0
	_values[BeliefType.ZHI] = 0

static func _find_runtime_option(options: Array, option_id: String) -> Dictionary:
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		if String(option.get("id", "")) == option_id:
			return option
	return {}
