class_name UnitStats extends Resource

@export var max_hp: int = 10
@export var atk: int = 5
@export var def: int = 2
@export var mov: int = 4
@export var rng: int = 1

func validate() -> bool:
	if max_hp < 5 or max_hp > 20:
		push_error("max_hp out of range [5,20]: %d" % max_hp)
		return false
	if atk < 3 or atk > 8:
		push_error("atk out of range [3,8]: %d" % atk)
		return false
	if def < 0 or def > 5:
		push_error("def out of range [0,5]: %d" % def)
		return false
	if mov < 2 or mov > 6:
		push_error("mov out of range [2,6]: %d" % mov)
		return false
	if rng < 1 or rng > 3:
		push_error("rng out of range [1,3]: %d" % rng)
		return false
	return true
