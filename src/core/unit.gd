class_name Unit
extends Node

## Base unit class - pure logic unit without visual representation.
## Creates UnitAttributes programmatically if no child is found in the scene.

signal unit_created(unit: Unit)
signal unit_destroyed(unit: Unit)

@export var unit_id: StringName = &""
@export var display_name: String = ""

var attributes: UnitAttributes
var class_component: ClassComponent
var skill_component: SkillComponent

func _ready() -> void:
	_ensure_attributes()
	attributes.attribute_changed.connect(_on_attribute_changed)
	attributes.threshold_unlocked.connect(_on_threshold_unlocked)
	_ensure_class()
	_ensure_skills()
	class_component.class_changed.connect(_on_class_changed)
	skill_component.bind_to_unit(self, class_component)
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

func _ensure_class() -> void:
	for child in get_children():
		if child is ClassComponent:
			class_component = child
			return
	class_component = ClassComponent.new()
	class_component.name = "ClassComponent"
	add_child(class_component)

func _ensure_skills() -> void:
	for child in get_children():
		if child is SkillComponent:
			skill_component = child
			return
	skill_component = SkillComponent.new()
	skill_component.name = "SkillComponent"
	add_child(skill_component)

func _on_attribute_changed(attr_type: int, new_value: int, old_value: int) -> void:
	GameEvents.attribute_changed.emit(self, attr_type, old_value, new_value)

func _on_threshold_unlocked(attr_type: int, threshold: int) -> void:
	GameEvents.threshold_unlocked.emit(self, attr_type, threshold)

func _on_class_changed(old_class: int, new_class: int) -> void:
	GameEvents.class_changed.emit(self, old_class, new_class)

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

## Execute class change with CAN_UNLOCK validation
func execute_class_change(class_id: int, achievement_points: int = 0) -> Dictionary:
	var attr_callable: Callable = func(attr_type: int) -> int: return attributes.get_value(attr_type)
	return class_component.execute_class_change(class_id, attr_callable, achievement_points)

## Report combat damage for class experience
func report_damage_dealt(damage: int, is_kill: bool, is_battle: bool = true) -> int:
	return class_component.report_damage_dealt(damage, is_kill, is_battle)

## Learn a normal skill by id.
func learn_skill(skill_id: StringName) -> bool:
	return skill_component.learn_normal_skill(skill_id)

## Return a skill instance by id, or null when unknown.
func get_skill(skill_id: StringName) -> SkillData:
	return skill_component.get_skill(skill_id)

## Get effective attribute value (base + class bonus, suspended if below threshold)
func get_effective_attribute(attr_type: int) -> int:
	var base: int = attributes.get_value(attr_type)
	var attr_callable: Callable = func(a: int) -> int: return attributes.get_value(a)
	if not class_component.is_bonus_active(attr_callable):
		return base
	return base + class_component.get_class_bonus(attr_type)

## Serialize unit data
func serialize() -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"attributes": attributes.serialize(),
		"class": class_component.get_data(),
		"skills": skill_component.get_data(),
	}

## Load unit data
func deserialize(data: Dictionary) -> void:
	if "unit_id" in data:
		unit_id = data["unit_id"]
	if "display_name" in data:
		display_name = data["display_name"]
	if "attributes" in data:
		attributes.deserialize(data["attributes"])
	if "class" in data:
		class_component.load_data(data["class"])
	if "skills" in data:
		skill_component.load_data(data["skills"])
