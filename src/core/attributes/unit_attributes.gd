class_name UnitAttributes
extends Node

## Manages all 9 attributes for a unit

signal attribute_changed(attr_type: int, new_value: int, old_value: int)
signal threshold_unlocked(attr_type: int, threshold: int)
signal crush_evaluated(attacker_value: int, defender_value: int, did_crush: bool, crush_direction: int)

@onready var str_component: AttributeComponent = %STRComponent
@onready var agi_component: AttributeComponent = %AGIComponent
@onready var con_component: AttributeComponent = %CONComponent
@onready var int_component: AttributeComponent = %INTComponent
@onready var cha_component: AttributeComponent = %CHAComponent
@onready var luk_component: AttributeComponent = %LUKComponent
@onready var wil_component: AttributeComponent = %WILComponent
@onready var res_component: AttributeComponent = %RESComponent
@onready var sou_component: AttributeComponent = %SOUComponent

var _components: Dictionary = {}
var _barrier_states: Dictionary = {1: false, 2: false, 3: false}

func _ready() -> void:
	_setup_components()
	_connect_signals()

func _setup_components() -> void:
	_components = {
		AttributeNames.Attribute.STR: str_component,
		AttributeNames.Attribute.AGI: agi_component,
		AttributeNames.Attribute.CON: con_component,
		AttributeNames.Attribute.INT: int_component,
		AttributeNames.Attribute.CHA: cha_component,
		AttributeNames.HiddenAttribute.LUK: luk_component,
		AttributeNames.HiddenAttribute.WIL: wil_component,
		AttributeNames.HiddenAttribute.RES: res_component,
		AttributeNames.HiddenAttribute.SOU: sou_component,
	}

func _connect_signals() -> void:
	for attr_type in _components:
		var comp: AttributeComponent = _components[attr_type]
		comp.attribute_value_changed.connect(_on_attribute_value_changed.bind(attr_type))
		comp.threshold_reached.connect(_on_threshold_reached.bind(attr_type))
		comp.barrier_broken.connect(_on_barrier_broken.bind(attr_type))

func _on_attribute_value_changed(attr_type: int, new_value: int, old_value: int) -> void:
	attribute_changed.emit(attr_type, new_value, old_value)

func _on_threshold_reached(attr_type: int, threshold: int) -> void:
	if not AttributeNames.is_hidden_attribute(attr_type):
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

## Evaluate crush condition
func evaluate_crush(
	attacker_value: int,
	defender_value: int,
	attribute_type: int
) -> Dictionary:
	var delta: int = attacker_value - defender_value
	var did_crush: bool = absi(delta) > AttributeNames.CRUSH_THRESHOLD
	var crush_direction: int = 0  # 0 = none, 1 = attacker crushes defender, -1 = defender crushes attacker

	if did_crush:
		if delta > 0:
			crush_direction = 1
		else:
			crush_direction = -1

	crush_evaluated.emit(attacker_value, defender_value, did_crush, crush_direction)

	return {
		"did_crush": did_crush,
		"crush_direction": crush_direction,
		"damage_multiplier": AttributeNames.CRUSH_DAMAGE_MULTIPLIER if did_crush else 1.0,
		"defense_multiplier": AttributeNames.CRUSH_DEFENSE_MULTIPLIER if did_crush else 1.0,
		"delta": delta
	}

## Get all attributes snapshot
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
