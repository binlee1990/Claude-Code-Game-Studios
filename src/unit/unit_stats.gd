class_name UnitStats extends Resource

@export var max_hp: int = 10
@export var atk: int = 5
@export var def: int = 2
@export var mov: int = 4
@export var rng: int = 1

func validate(emit_errors: bool = true) -> bool:
	if max_hp < 5 or max_hp > 20:
		return _fail("max_hp out of range [5,20]: %d" % max_hp, emit_errors)
	if atk < 3 or atk > 8:
		return _fail("atk out of range [3,8]: %d" % atk, emit_errors)
	if def < 0 or def > 5:
		return _fail("def out of range [0,5]: %d" % def, emit_errors)
	if mov < 2 or mov > 6:
		return _fail("mov out of range [2,6]: %d" % mov, emit_errors)
	if rng < 1 or rng > 3:
		return _fail("rng out of range [1,3]: %d" % rng, emit_errors)
	return true

func _fail(message: String, emit_errors: bool) -> bool:
	if emit_errors:
		push_error(message)
	return false
