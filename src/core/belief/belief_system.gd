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

## Resets all belief values to 0. Used for new game.
func reset() -> void:
	_values[BeliefType.REN] = 0
	_values[BeliefType.YI]  = 0
	_values[BeliefType.ZHI] = 0
