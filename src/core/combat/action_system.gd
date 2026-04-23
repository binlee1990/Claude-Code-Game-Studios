class_name ActionSystem
extends Node

## Manages per-unit action state during combat: acted flags, MP, available actions.

enum ActionType { MOVE, BASIC_ATTACK, SKILL, STANDBY }

const MP_RECOVERY_RATE: float = 0.1

var _unit_data: Dictionary = {}

## Initialize combat state for units.
## mp_config maps Unit -> {"max_mp": int, "skill_costs": Array[int]}
func initialize(units: Array, mp_config: Dictionary = {}) -> void:
	_unit_data.clear()
	for unit in units:
		var config: Dictionary = mp_config.get(unit, {})
		var max_mp: int = config.get("max_mp", 100)
		var skill_costs: Array = config.get("skill_costs", [])
		_unit_data[unit] = {
			"has_acted": false,
			"has_moved": false,
			"current_mp": max_mp,
			"max_mp": max_mp,
			"skill_costs": skill_costs,
		}

## Returns true if the unit can still act this round.
func can_act(unit) -> bool:
	if not _unit_data.has(unit):
		return false
	return not _unit_data[unit]["has_acted"]

## Returns true if the unit can still move this round.
func can_move(unit) -> bool:
	if not _unit_data.has(unit):
		return false
	var data: Dictionary = _unit_data[unit]
	return not data["has_acted"] and not data["has_moved"]

## Get available action types for a unit based on current state and MP.
func get_available_actions(unit) -> Array:
	if not _unit_data.has(unit):
		return []
	var data: Dictionary = _unit_data[unit]
	if data["has_acted"]:
		return []
	var has_skills: bool = data["skill_costs"].size() > 0
	# MP depleted (MP=0) with skills -> restricted actions only
	if has_skills and data["current_mp"] <= 0:
		return [ActionType.BASIC_ATTACK, ActionType.STANDBY]
	var actions: Array = []
	if not data["has_moved"]:
		actions.append(ActionType.MOVE)
	actions.append(ActionType.BASIC_ATTACK)
	if _has_affordable_skill(data):
		actions.append(ActionType.SKILL)
	actions.append(ActionType.STANDBY)
	return actions

## Execute an action for a unit. Returns true if successful.
## For SKILL actions, pass the MP cost via skill_cost parameter.
func execute_action(unit, action: int, skill_cost: int = 0) -> bool:
	if not can_act(unit):
		return false
	var data: Dictionary = _unit_data[unit]
	match action:
		ActionType.MOVE:
			if data["has_moved"]:
				return false
			data["has_moved"] = true
			return true
		ActionType.BASIC_ATTACK:
			data["has_acted"] = true
			return true
		ActionType.SKILL:
			if skill_cost <= 0 or data["current_mp"] < skill_cost:
				return false
			data["current_mp"] -= skill_cost
			data["has_acted"] = true
			return true
		ActionType.STANDBY:
			data["has_acted"] = true
			return true
		_:
			return false

## Get current MP for a unit.
func get_current_mp(unit) -> int:
	if not _unit_data.has(unit):
		return 0
	return _unit_data[unit]["current_mp"]

## Get max MP for a unit.
func get_max_mp(unit) -> int:
	if not _unit_data.has(unit):
		return 0
	return _unit_data[unit]["max_mp"]

## Reset all units for a new round: clear acted/moved flags, recover MP.
func reset_round() -> void:
	for unit in _unit_data:
		var data: Dictionary = _unit_data[unit]
		data["has_acted"] = false
		data["has_moved"] = false
		_recover_mp(data)

func _has_affordable_skill(data: Dictionary) -> bool:
	for cost in data["skill_costs"]:
		if data["current_mp"] >= cost:
			return true
	return false

func _recover_mp(data: Dictionary) -> void:
	var recovery: int = int(data["max_mp"] * MP_RECOVERY_RATE)
	data["current_mp"] = mini(data["current_mp"] + recovery, data["max_mp"])

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

## Serialize all per-unit action state to a Dictionary keyed by unit_id (String).
## Caller must ensure all units are registered via initialize() before calling.
## Implements Story 007 (design/gdd/turn-based-mode.md AC-S2).
func serialize() -> Dictionary:
	var out: Dictionary = {}
	for unit in _unit_data:
		var d: Dictionary = _unit_data[unit]
		out[String(unit.unit_id)] = {
			"has_acted": d["has_acted"],
			"has_moved": d["has_moved"],
			"current_mp": d["current_mp"],
			"max_mp": d["max_mp"],
			"skill_costs": d["skill_costs"].duplicate(),
		}
	return out

## Restore per-unit action state from serialized data.
## Caller must first call initialize() so unit-to-data entries exist.
## Units whose unit_id does not appear in data are left at their initialized defaults.
## Unknown unit IDs in data (units not registered) are silently ignored.
func deserialize(data: Dictionary) -> void:
	for unit in _unit_data:
		var key: String = String(unit.unit_id)
		if not data.has(key):
			continue
		var d: Dictionary = data[key]
		_unit_data[unit]["has_acted"] = d.get("has_acted", false)
		_unit_data[unit]["has_moved"] = d.get("has_moved", false)
		_unit_data[unit]["max_mp"] = d.get("max_mp", _unit_data[unit]["max_mp"])
		_unit_data[unit]["current_mp"] = d.get("current_mp", _unit_data[unit]["max_mp"])
		_unit_data[unit]["skill_costs"] = d.get("skill_costs", []).duplicate()
