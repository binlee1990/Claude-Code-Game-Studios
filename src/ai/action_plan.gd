class_name ActionPlan extends RefCounted

const ActionType = preload("res://src/ai/action_type.gd")

var unit: Unit
var type = ActionType.WAIT
var move_target: Vector2i
var attack_target: Unit

func _init(p_unit: Unit, p_type, p_move_target: Vector2i, p_attack_target: Unit = null) -> void:
	assert(p_unit != null, "ActionPlan: unit must not be null")
	unit = p_unit
	type = p_type
	move_target = p_move_target
	attack_target = p_attack_target
