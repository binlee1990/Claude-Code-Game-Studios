class_name TurnConfig extends Resource

@export var turn_cap: int = 30

func validate() -> bool:
	assert(turn_cap >= 1 and turn_cap <= 99, "turn_cap out of range [1,99]: %d" % turn_cap)
	return true
