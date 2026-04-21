class_name AttributeComponent
extends Node

## Manages a single attribute for a unit

signal attribute_value_changed(attribute_type: int, new_value: int, old_value: int)
signal threshold_reached(attribute_type: int, threshold: int)
signal barrier_broken(attribute_type: int, stage: int)

@export var attribute_type: AttributeNames.Attribute = AttributeNames.Attribute.STR
@export var initial_value: int = AttributeNames.DEFAULT_ATTRIBUTE_VALUE
@export var initial_potential: int = AttributeNames.DEFAULT_POTENTIAL

var _data: AttributeData
var _barrier_stage: int = 1
var _barriers_broken: Dictionary = {1: false, 2: false, 3: false}
var _thresholds_reached: Dictionary = {50: false, 100: false, 150: false}

func _ready() -> void:
	_data = AttributeData.new(initial_value, initial_potential)
	_data.value_changed.connect(_on_value_changed)
	_data.potential_changed.connect(_on_potential_changed)

func _on_value_changed(new_value: int, old_value: int) -> void:
	attribute_value_changed.emit(attribute_type, new_value, old_value)
	_check_threshold(new_value)

func _on_potential_changed(new_potential: int, old_potential: int) -> void:
	pass

func _check_threshold(value: int) -> void:
	for threshold in AttributeNames.THRESHOLD_REWARDS:
		if value >= threshold and not _thresholds_reached[threshold]:
			_thresholds_reached[threshold] = true
			threshold_reached.emit(attribute_type, threshold)

## Check if barrier breakthrough is possible for the current stage
func can_break_barrier() -> bool:
	if _barrier_stage > 3:
		return false
	if _barriers_broken.get(_barrier_stage, false):
		return false
	var threshold: int = AttributeNames.get_barrier_threshold(_barrier_stage)
	return _data.get_value() >= threshold

## Execute barrier breakthrough for the current stage. Returns false if not possible.
func execute_breakthrough() -> bool:
	if not can_break_barrier():
		return false
	_barriers_broken[_barrier_stage] = true
	barrier_broken.emit(attribute_type, _barrier_stage)
	_barrier_stage += 1
	return true

## Get current value
func get_value() -> int:
	return _data.get_value()

## Get current potential
func get_potential() -> int:
	return _data.get_potential()

## Get potential grade string
func get_potential_grade() -> String:
	return _data.get_potential_grade()

## Apply level up growth, respecting barrier cap
func apply_growth() -> int:
	return _data.apply_growth(_get_growth_cap())

func _get_growth_cap() -> int:
	for stage in range(1, 4):
		if not _barriers_broken.get(stage, false):
			return AttributeNames.get_barrier_threshold(stage)
	return AttributeNames.MAX_ATTRIBUTE_VALUE

## Check if can use fruit
func can_use_fruit() -> bool:
	return _data.can_use_fruit(_barriers_broken.get(_barrier_stage, true), _barrier_stage)

## Apply fruit to increase potential (checks barrier and cap conditions)
func apply_fruit() -> bool:
	if not can_use_fruit():
		return false
	return _data.apply_fruit()

## Get barrier state for current stage
func is_current_barrier_broken() -> bool:
	return _barriers_broken.get(_barrier_stage, true)

## Get current barrier threshold
func get_current_barrier_threshold() -> int:
	return AttributeNames.get_barrier_threshold(_barrier_stage)

## Check if has reached specific threshold
func has_reached_threshold(threshold: int) -> bool:
	return _thresholds_reached.get(threshold, false)

## Force set value (for loading saved games)
func set_value(value: int) -> void:
	_data.set_value(value)

## Force set potential (for loading saved games)
func set_potential(potential: int) -> void:
	_data._potential = potential

## Get data for serialization
func get_data() -> Dictionary:
	return {
		"value": _data.get_value(),
		"potential": _data.get_potential(),
		"barrier_stage": _barrier_stage,
		"barriers_broken": _barriers_broken,
		"thresholds_reached": _thresholds_reached
	}

## Load from serialized data
func load_data(data: Dictionary) -> void:
	if "value" in data:
		_data._value = data["value"]
	if "potential" in data:
		_data._potential = data["potential"]
	if "barrier_stage" in data:
		_barrier_stage = data["barrier_stage"]
	if "barriers_broken" in data:
		_barriers_broken = data["barriers_broken"]
	if "thresholds_reached" in data:
		_thresholds_reached = data["thresholds_reached"]
