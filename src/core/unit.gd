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
	attributes.attribute_changed.connect(_on_attribute_changed)
	attributes.threshold_unlocked.connect(_on_threshold_unlocked)
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

func _on_attribute_changed(attr_type: int, new_value: int, old_value: int) -> void:
	GameEvents.attribute_changed.emit(self, attr_type, old_value, new_value)

func _on_threshold_unlocked(attr_type: int, threshold: int) -> void:
	GameEvents.threshold_unlocked.emit(self, attr_type, threshold)

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

## Check if barrier breakthrough is possible for attribute
func can_break_barrier(attr_type: int) -> bool:
	return attributes.can_break_barrier(attr_type)

## Execute barrier breakthrough for attribute
func execute_breakthrough(attr_type: int) -> bool:
	return attributes.execute_breakthrough(attr_type)

## Evaluate crush condition against another unit
func evaluate_crush_against(target: Unit, attribute_type: int, is_damage_action: bool = true) -> Dictionary:
	var attacker_value: int = attributes.get_value(attribute_type)
	var defender_value: int = target.attributes.get_value(attribute_type)
	return attributes.evaluate_crush(attacker_value, defender_value, attribute_type, is_damage_action)

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
