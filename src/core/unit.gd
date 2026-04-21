class_name Unit
extends Node

## Base unit class - pure logic unit without visual representation.
## Creates UnitAttributes programmatically if no child is found in the scene.

signal unit_created(unit: Unit)
signal unit_destroyed(unit: Unit)

@export var unit_id: StringName = &""
@export var display_name: String = ""

var attributes: UnitAttributes

func _ready() -> void:
	_ensure_attributes()
	unit_created.emit(self)

func _exit_tree() -> void:
	unit_destroyed.emit(self)

func _ensure_attributes() -> void:
	for child in get_children():
		if child is UnitAttributes:
			attributes = child
			return
	attributes = UnitAttributes.new()
	attributes.name = "UnitAttributes"
	add_child(attributes)

## Get a specific attribute value
func get_attribute(attr_type: int) -> int:
	return attributes.get_value(attr_type)

## Get attribute potential
func get_potential(attr_type: int) -> int:
	return attributes.get_potential(attr_type)

## Get full attribute snapshot
func get_attributes_snapshot() -> Dictionary:
	return attributes.get_snapshot()

## Apply level up growth to all attributes
func apply_level_up() -> Dictionary:
	return attributes.apply_growth_to_all()

## Use fruit on attribute to increase potential
func use_fruit(attr_type: int) -> bool:
	return attributes.use_fruit(attr_type)

## Evaluate crush condition against another unit
func evaluate_crush_against(target: Unit, attribute_type: int) -> Dictionary:
	var attacker_value: int = attributes.get_value(attribute_type)
	var defender_value: int = target.attributes.get_value(attribute_type)
	return attributes.evaluate_crush(attacker_value, defender_value, attribute_type)

## Serialize unit data
func serialize() -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"attributes": attributes.serialize()
	}

## Load unit data
func deserialize(data: Dictionary) -> void:
	if "unit_id" in data:
		unit_id = data["unit_id"]
	if "display_name" in data:
		display_name = data["display_name"]
	if "attributes" in data:
		attributes.deserialize(data["attributes"])
