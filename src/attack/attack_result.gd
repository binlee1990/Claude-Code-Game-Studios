class_name AttackResult extends RefCounted

var attacker: Unit
var target: Unit
var damage: int
var lethal: bool
var is_valid: bool

func _init(p_attacker: Unit = null, p_target: Unit = null, p_damage: int = 0, p_lethal: bool = false) -> void:
	attacker = p_attacker
	target = p_target
	damage = p_damage
	lethal = p_lethal
	is_valid = p_attacker != null

static func resolve_damage(atk: int, def: int) -> int:
	return maxi(atk - def, 1)
