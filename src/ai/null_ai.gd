class_name NullAI extends AIController

func take_turn(_units: Array, _world_state: WorldState) -> ActionList:
	return ActionList.new()
