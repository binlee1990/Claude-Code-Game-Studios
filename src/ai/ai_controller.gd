class_name AIController extends RefCounted

func take_turn(_units: Array[Unit], _world_state: Dictionary) -> Array:
	assert(false, "take_turn() must be overridden by subclass")
	return []
