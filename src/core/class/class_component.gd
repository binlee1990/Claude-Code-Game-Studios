class_name ClassComponent
extends Node

## Manages a unit's class state machine and class experience.

signal class_state_changed(old_state: int, new_state: int)
signal class_changed(old_class: int, new_class: int)

var _state: int = ClassNames.ClassState.NONE
var _current_class: int = ClassNames.ClassID.BASIC_WARRIOR
var _class_exp: Dictionary = {}  # class_id -> accumulated experience
var _choice_recorded: bool = false

func _ready() -> void:
	if _state == ClassNames.ClassState.NONE:
		_transition_to(ClassNames.ClassState.BASIC_ACTIVE)

## Get current class state
func get_state() -> int:
	return _state

## Get current active class
func get_class_id() -> int:
	return _current_class

## Get class experience for a specific class
func get_class_exp(class_id: int) -> int:
	return _class_exp.get(class_id, 0)

## Get current active class experience
func get_current_class_exp() -> int:
	return _class_exp.get(_current_class, 0)

## Get class level for current class
func get_class_level() -> int:
	var exp: int = get_current_class_exp()
	var cap: int = ClassNames.get_exp_cap(_current_class)
	return int(exp / cap) + 1

## Whether player declined a class change
func is_choice_recorded() -> bool:
	return _choice_recorded

## Attempt transition to ADVANCED_UNLOCKED
func try_unlock_advanced() -> bool:
	if _state != ClassNames.ClassState.BASIC_ACTIVE:
		return false
	_transition_to(ClassNames.ClassState.ADVANCED_UNLOCKED)
	return true

## Confirm class change to advanced class
func confirm_class_change(new_class: int) -> bool:
	if _state == ClassNames.ClassState.ADVANCED_UNLOCKED:
		if not ClassNames.is_advanced(new_class):
			return false
		var old_class: int = _current_class
		_current_class = new_class
		_transition_to(ClassNames.ClassState.ADVANCED_ACTIVE)
		class_changed.emit(old_class, new_class)
		return true
	if _state == ClassNames.ClassState.SPECIAL_UNLOCKED:
		if not ClassNames.is_special(new_class):
			return false
		var old_class: int = _current_class
		_current_class = new_class
		_transition_to(ClassNames.ClassState.SPECIAL_ACTIVE)
		class_changed.emit(old_class, new_class)
		return true
	return false

## Player declines class change (stays at current tier)
func decline_class_change() -> bool:
	if _state == ClassNames.ClassState.ADVANCED_UNLOCKED:
		_choice_recorded = true
		_transition_to(ClassNames.ClassState.BASIC_ACTIVE)
		return true
	if _state == ClassNames.ClassState.SPECIAL_UNLOCKED:
		_choice_recorded = true
		return true
	return false

## Attempt transition to SPECIAL_UNLOCKED
func try_unlock_special() -> bool:
	if _state != ClassNames.ClassState.ADVANCED_ACTIVE:
		return false
	_transition_to(ClassNames.ClassState.SPECIAL_UNLOCKED)
	return true

## Add experience to current class (capped at exp_cap)
func add_class_exp(amount: int) -> int:
	var cap: int = ClassNames.get_exp_cap(_current_class)
	var current: int = get_current_class_exp()
	var new_exp: int = mini(current + amount, cap)
	_class_exp[_current_class] = new_exp
	return new_exp - current

## Report combat performance and apply class experience
func report_damage_dealt(damage_dealt: int, is_kill: bool, is_battle: bool = true) -> int:
	var exp: int = ClassNames.calculate_exp_gain(damage_dealt, is_kill, is_battle)
	return add_class_exp(exp)

## Evaluate CAN_UNLOCK for a target class.
## Returns Dictionary: { "can_unlock": bool, "reasons": String[] }
## `attributes` is a callable: (attr_type: int) -> int
## `achievement_points` is the player's current achievement points (for special classes)
func can_unlock(class_id: int, attributes: Callable, achievement_points: int = 0) -> Dictionary:
	var reasons: Array[String] = []

	# Basic classes always unlock
	if ClassNames.is_basic(class_id):
		return {"can_unlock": true, "reasons": reasons}

	var def: Dictionary = ClassNames.CLASS_DEFS[class_id]

	# Special classes check achievement points
	if ClassNames.is_special(class_id):
		var cost: int = def["spc_cost"]
		if achievement_points < cost:
			reasons.append("Achievement points insufficient (%d/%d)" % [achievement_points, cost])
		if reasons.size() > 0:
			return {"can_unlock": false, "reasons": reasons}
		return {"can_unlock": true, "reasons": reasons}

	# Advanced classes: check primary attr, secondary attr, class experience
	var primary_attr: int = def["primary_attr"]
	var secondary_attr: int = def["secondary_attr"]
	var primary_threshold: int = def["primary_threshold"]
	var secondary_threshold: int = def["secondary_threshold"]
	var exp_required: int = def["exp_required"]

	var primary_value: int = attributes.call(primary_attr)
	var secondary_value: int = attributes.call(secondary_attr)
	var class_exp: int = get_class_exp(class_id)

	if primary_value < primary_threshold:
		reasons.append("%s needs %d more" % [
			AttributeNames.Attribute.keys()[primary_attr],
			primary_threshold - primary_value
		])
	if secondary_value < secondary_threshold:
		reasons.append("%s needs %d more" % [
			AttributeNames.Attribute.keys()[secondary_attr],
			secondary_threshold - secondary_value
		])
	if class_exp < exp_required:
		reasons.append("Class experience needs %d more" % [exp_required - class_exp])

	return {"can_unlock": reasons.is_empty(), "reasons": reasons}

## Check if this is a terminal state
func is_terminal() -> bool:
	return _state == ClassNames.ClassState.SPECIAL_ACTIVE

## Initialize with a specific class (for loading saved games)
func initialize(class_id: int, state: int, class_exp: Dictionary, choice_recorded: bool) -> void:
	_current_class = class_id
	_state = state
	_class_exp = class_exp.duplicate()
	_choice_recorded = choice_recorded

## Serialize class data
func get_data() -> Dictionary:
	return {
		"state": _state,
		"current_class": _current_class,
		"class_exp": _class_exp.duplicate(),
		"choice_recorded": _choice_recorded,
	}

## Load from serialized data
func load_data(data: Dictionary) -> void:
	if "state" in data:
		_state = data["state"]
	if "current_class" in data:
		_current_class = data["current_class"]
	if "class_exp" in data:
		_class_exp = data["class_exp"].duplicate()
	if "choice_recorded" in data:
		_choice_recorded = data["choice_recorded"]

func _transition_to(new_state: int) -> void:
	var old_state: int = _state
	_state = new_state
	class_state_changed.emit(old_state, new_state)
