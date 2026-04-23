class_name UnitAttributes
extends Node

## Manages all 9 attributes for a unit.
## Discovers AttributeComponent children dynamically, or creates defaults if none exist.

signal attribute_changed(attr_type: int, new_value: int, old_value: int)
signal threshold_unlocked(attr_type: int, threshold: int)
signal crush_evaluated(attacker_value: int, defender_value: int, did_crush: bool, crush_direction: int)

var _components: Dictionary = {}
var _barrier_states: Dictionary = {1: false, 2: false, 3: false}

func _ready() -> void:
	_setup_components()
	_connect_signals()

func _setup_components() -> void:
	_components = {}
	for child in get_children():
		if child is AttributeComponent:
			_components[child.attribute_type] = child
	if _components.is_empty():
		_create_default_components()

func _create_default_components() -> void:
	var names := [
		"STRComponent", "AGIComponent", "CONComponent", "INTComponent", "CHAComponent",
		"LUKComponent", "WILComponent", "RESComponent", "SOUComponent"
	]
	var types: Array[int] = [
		AttributeNames.Attribute.STR, AttributeNames.Attribute.AGI,
		AttributeNames.Attribute.CON, AttributeNames.Attribute.INT,
		AttributeNames.Attribute.CHA, AttributeNames.Attribute.LUK,
		AttributeNames.Attribute.WIL, AttributeNames.Attribute.RES,
		AttributeNames.Attribute.SOU
	]
	for i in names.size():
		var comp := AttributeComponent.new()
		comp.name = names[i]
		comp.attribute_type = types[i]
		add_child(comp)
		_components[types[i]] = comp

func _connect_signals() -> void:
	for attr_type in _components:
		var comp: AttributeComponent = _components[attr_type]
		comp.attribute_value_changed.connect(_on_attribute_value_changed)
		comp.threshold_reached.connect(_on_threshold_reached)
		comp.barrier_broken.connect(_on_barrier_broken)

func _on_attribute_value_changed(attr_type: int, new_value: int, old_value: int) -> void:
	attribute_changed.emit(attr_type, new_value, old_value)

func _on_threshold_reached(attr_type: int, threshold: int) -> void:
	if not AttributeNames.is_hidden(attr_type):
		threshold_unlocked.emit(attr_type, threshold)

func _on_barrier_broken(attr_type: int, stage: int) -> void:
	_barrier_states[stage] = true

## Get attribute component by type
func get_component(attr_type: int) -> AttributeComponent:
	return _components.get(attr_type)

## Get attribute value
func get_value(attr_type: int) -> int:
	if _components.has(attr_type):
		return _components[attr_type].get_value()
	return 0

## Get attribute potential
func get_potential(attr_type: int) -> int:
	if _components.has(attr_type):
		return _components[attr_type].get_potential()
	return AttributeNames.PotentialGrade.E

## Apply growth to all attributes (on level up)
func apply_growth_to_all() -> Dictionary:
	var results: Dictionary = {}
	for attr_type in _components:
		var comp: AttributeComponent = _components[attr_type]
		results[attr_type] = comp.apply_growth()
	return results

## Use fruit on attribute
func use_fruit(attr_type: int) -> bool:
	if _components.has(attr_type):
		return _components[attr_type].apply_fruit()
	return false

## Check if barrier breakthrough is possible
func can_break_barrier(attr_type: int) -> bool:
	if _components.has(attr_type):
		return _components[attr_type].can_break_barrier()
	return false

## Execute barrier breakthrough
func execute_breakthrough(attr_type: int) -> bool:
	if _components.has(attr_type):
		return _components[attr_type].execute_breakthrough()
	return false

## Evaluate crush condition
func evaluate_crush(
	attacker_value: int,
	defender_value: int,
	attribute_type: int,
	is_damage_action: bool = true
) -> Dictionary:
	var applicable := is_damage_action
	var delta: int = attacker_value - defender_value
	var did_crush: bool = absi(delta) > AttributeNames.CRUSH_THRESHOLD
	var crush_direction: int = 0  # 0 = none, 1 = attacker crushes, -1 = defender crushes

	if did_crush:
		crush_direction = 1 if delta > 0 else -1

	crush_evaluated.emit(attacker_value, defender_value, did_crush, crush_direction)

	return {
		"did_crush": did_crush,
		"crush_direction": crush_direction,
		"damage_multiplier": AttributeNames.CRUSH_DAMAGE_MULTIPLIER if (did_crush and applicable) else 1.0,
		"defense_multiplier": AttributeNames.CRUSH_DEFENSE_MULTIPLIER if (did_crush and applicable) else 1.0,
		"delta": delta,
		"applicable": applicable
	}

## Get all attributes snapshot (returns a fresh copy each call)
func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for attr_type in _components:
		var comp: AttributeComponent = _components[attr_type]
		snapshot[attr_type] = {
			"value": comp.get_value(),
			"potential": comp.get_potential(),
			"potential_grade": comp.get_potential_grade()
		}
	return snapshot

## Serialize all attribute data
func serialize() -> Dictionary:
	var data: Dictionary = {
		"barrier_states": _barrier_states.duplicate()
	}
	for attr_type in _components:
		data[str(attr_type)] = _components[attr_type].get_data()
	return data

## Load attribute data
func deserialize(data: Dictionary) -> void:
	if "barrier_states" in data:
		_barrier_states = data["barrier_states"].duplicate()
	for attr_type in _components:
		var key: String = str(attr_type)
		if key in data:
			_components[attr_type].load_data(data[key])
