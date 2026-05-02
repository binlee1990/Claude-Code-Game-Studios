class_name AttackResolver extends RefCounted

const MovementResolver = preload("res://src/movement/movement_resolver.gd")
const AttackResult = preload("res://src/attack/attack_result.gd")

signal counter_attack(attacker: Unit, target: Unit)
signal damage_dealt(attacker: Unit, target: Unit, damage: int)

func execute_attack(attacker: Unit, target: Unit) -> AttackResult:
	if not is_instance_valid(attacker):
		assert(false, "execute_attack: attacker is null")
		return AttackResult.new()
	if not is_instance_valid(target):
		assert(false, "execute_attack: target is null")
		return AttackResult.new()
	if not attacker.is_alive():
		return AttackResult.new()
	if attacker.has_acted_this_turn:
		return AttackResult.new()
	if attacker.action_state not in [Unit.UnitState.SELECTED, Unit.UnitState.MOVED]:
		return AttackResult.new()
	if target.faction == attacker.faction:
		return AttackResult.new()
	if not target.is_alive():
		return AttackResult.new()

	var dist := MovementResolver.manhattan(attacker.grid_position, target.grid_position)
	if dist == 0 or dist > attacker.rng:
		return AttackResult.new()

	var damage := AttackResult.resolve_damage(attacker.atk, target.def)
	target.take_damage(damage)
	var lethal := target.is_dead()
	attacker.has_acted_this_turn = true
	attacker.action_state = Unit.UnitState.ACTED

	damage_dealt.emit(attacker, target, damage)
	return AttackResult.new(attacker, target, damage, lethal)
