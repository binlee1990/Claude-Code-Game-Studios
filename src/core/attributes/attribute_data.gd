class_name AttributeData
extends Resource

## Stores the value (V) and potential (P) for a single attribute

signal value_changed(new_value: int, old_value: int)
signal potential_changed(new_potential: int, old_potential: int)

@export var _value: int = AttributeNames.DEFAULT_ATTRIBUTE_VALUE :
	set(v):
		var old = _value
		_value = mini(v, AttributeNames.MAX_ATTRIBUTE_VALUE)
		if _value != old:
			value_changed.emit(_value, old)

@export var _potential: int = AttributeNames.DEFAULT_POTENTIAL :
	set(p):
		var old = _potential
		_potential = clampi(p, AttributeNames.PotentialGrade.E, AttributeNames.PotentialGrade.S)
		if _potential != old:
			potential_changed.emit(_potential, old)

func _init(
	p_value: int = AttributeNames.DEFAULT_ATTRIBUTE_VALUE,
	p_potential: int = AttributeNames.DEFAULT_POTENTIAL
) -> void:
	_value = p_value
	_potential = p_potential

## Get current value (V)
func get_value() -> int:
	return _value

## Set value with clamping
func set_value(v: int) -> void:
	_value = v

## Get current potential (P) - returns 1-6
func get_potential() -> int:
	return _potential

## Get potential grade letter (E/D/C/B/A/S)
func get_potential_grade() -> String:
	return AttributeNames.get_potential_name(_potential)

## Apply growth from level up, capped by the given barrier limit or 999
func apply_growth(cap: int = AttributeNames.MAX_ATTRIBUTE_VALUE) -> int:
	var old_value := _value
	var effective_cap := mini(cap, AttributeNames.MAX_ATTRIBUTE_VALUE)
	_value = mini(_value + _potential, effective_cap)
	if _value != old_value:
		value_changed.emit(_value, old_value)
	return _value - old_value

## Check if at barrier threshold and barrier not broken
func is_at_barrier_threshold(stage: int) -> bool:
	return _value >= AttributeNames.get_barrier_threshold(stage)

## Check if can use fruit (potential < S and not at unbroken barrier)
func can_use_fruit(barrier_broken: bool, barrier_stage: int) -> bool:
	if _potential >= AttributeNames.PotentialGrade.S:
		return false
	if not barrier_broken:
		var threshold: int = AttributeNames.get_barrier_threshold(barrier_stage)
		if _value >= threshold:
			return false
	return true

## Apply fruit to increase potential
func apply_fruit() -> bool:
	if _potential >= AttributeNames.PotentialGrade.S:
		return false
	_potential += 1
	return true
