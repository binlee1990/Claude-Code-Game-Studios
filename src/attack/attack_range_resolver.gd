class_name AttackRangeResolver extends RefCounted

const MovementResolver = preload("res://src/movement/movement_resolver.gd")

func get_valid_targets(attacker: Unit, all_units: Array, map: Map) -> Array:
	var targets: Array = []
	for u in all_units:
		if not is_instance_valid(u):
			continue
		if u.faction == attacker.faction:
			continue
		if not u.is_alive():
			continue
		var dist := MovementResolver.manhattan(attacker.grid_position, u.grid_position)
		if dist == 0 or dist > attacker.rng:
			continue
		targets.append(u)
	targets.sort_custom(func(a: Unit, b: Unit) -> bool:
		var da := MovementResolver.manhattan(attacker.grid_position, a.grid_position)
		var db := MovementResolver.manhattan(attacker.grid_position, b.grid_position)
		if da != db:
			return da < db
		return a.hp < b.hp
	)
	return targets
