class_name ActionList extends RefCounted

var plans: Array = []

func add(action: ActionPlan) -> void:
	plans.append(action)

func get_actions() -> Array:
	return plans.duplicate()

func is_empty() -> bool:
	return plans.is_empty()

func size() -> int:
	return plans.size()
