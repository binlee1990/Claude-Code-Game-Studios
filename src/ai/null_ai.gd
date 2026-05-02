class_name NullAI extends AIController

func take_turn(_units: Array[Unit], _world_state: WorldState) -> ActionList:
	return ActionList.new()
