class_name AIController extends RefCounted

func take_turn(_units: Array, _world_state: WorldState) -> ActionList:
	assert(false, "take_turn() must be overridden by subclass")
	return ActionList.new()
