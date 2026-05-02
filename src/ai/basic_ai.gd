class_name BasicAI extends AIController

const ActionType = preload("res://src/ai/action_type.gd")

var _movement_resolver := MovementResolver.new()
var _attack_range_resolver := AttackRangeResolver.new()

func take_turn(units: Array, world_state: WorldState) -> ActionList:
	var actions := ActionList.new()
	if units.is_empty():
		return actions
	if world_state == null or world_state.map == null:
		return _wait_for_units(units)

	var reserved_moves: Dictionary = {}
	for unit in units:
		if not _can_plan_for(unit):
			continue
		var plan := _create_plan(unit, world_state, reserved_moves)
		actions.add(plan)
		if plan.move_target != unit.grid_position:
			reserved_moves[plan.move_target] = unit
	return actions

func _create_plan(unit: Unit, world_state: WorldState, reserved_moves: Dictionary) -> ActionPlan:
	var direct_targets := _attack_range_resolver.get_valid_targets(unit, world_state.all_units, world_state.map)
	if not direct_targets.is_empty():
		return ActionPlan.new(unit, ActionType.ATTACK_ONLY, unit.grid_position, direct_targets[0])

	var movement_result := _movement_resolver.compute_reachable(unit, world_state.map)
	var move_and_attack := _find_move_and_attack_plan(unit, world_state, movement_result, reserved_moves)
	if move_and_attack != null:
		return move_and_attack

	var move_target := _find_move_toward_nearest_enemy(unit, world_state, movement_result, reserved_moves)
	if move_target != unit.grid_position:
		return ActionPlan.new(unit, ActionType.MOVE_ONLY, move_target, null)

	return ActionPlan.new(unit, ActionType.WAIT, unit.grid_position, null)

func _find_move_and_attack_plan(
	unit: Unit,
	world_state: WorldState,
	movement_result: MovementResult,
	reserved_moves: Dictionary,
) -> ActionPlan:
	var best_tile := unit.grid_position
	var best_target: Unit = null
	var best_score: Array = []

	for tile: Vector2i in movement_result.get_reachable_tiles():
		if tile == unit.grid_position:
			continue
		if reserved_moves.has(tile):
			continue
		for target in _get_alive_enemies(unit, world_state.all_units):
			var distance_to_target := MovementResolver.manhattan(tile, target.grid_position)
			if distance_to_target == 0 or distance_to_target > unit.rng:
				continue
			var score := [
				movement_result.get_distance_to(tile),
				distance_to_target,
				target.hp,
				tile.x,
				tile.y,
			]
			if best_target == null or _is_score_better(score, best_score):
				best_tile = tile
				best_target = target
				best_score = score

	if best_target == null:
		return null
	return ActionPlan.new(unit, ActionType.MOVE_AND_ATTACK, best_tile, best_target)

func _find_move_toward_nearest_enemy(
	unit: Unit,
	world_state: WorldState,
	movement_result: MovementResult,
	reserved_moves: Dictionary,
) -> Vector2i:
	var nearest_enemy := _find_nearest_enemy(unit, world_state.all_units)
	if nearest_enemy == null:
		return unit.grid_position

	var best_tile := unit.grid_position
	var best_score := [
		MovementResolver.manhattan(unit.grid_position, nearest_enemy.grid_position),
		0,
		unit.grid_position.x,
		unit.grid_position.y,
	]

	for tile: Vector2i in movement_result.get_reachable_tiles():
		if reserved_moves.has(tile):
			continue
		var move_distance := movement_result.get_distance_to(tile)
		var score := [
			MovementResolver.manhattan(tile, nearest_enemy.grid_position),
			-move_distance,
			tile.x,
			tile.y,
		]
		if _is_score_better(score, best_score):
			best_tile = tile
			best_score = score

	return best_tile

func _find_nearest_enemy(unit: Unit, all_units: Array) -> Unit:
	var best: Unit = null
	var best_score: Array = []
	for enemy in _get_alive_enemies(unit, all_units):
		var score := [
			MovementResolver.manhattan(unit.grid_position, enemy.grid_position),
			enemy.hp,
			enemy.grid_position.x,
			enemy.grid_position.y,
		]
		if best == null or _is_score_better(score, best_score):
			best = enemy
			best_score = score
	return best

func _get_alive_enemies(unit: Unit, all_units: Array) -> Array:
	var enemies: Array = []
	for other in all_units:
		if not is_instance_valid(other):
			continue
		if other.faction == unit.faction:
			continue
		if not other.is_alive():
			continue
		enemies.append(other)
	return enemies

func _wait_for_units(units: Array) -> ActionList:
	var actions := ActionList.new()
	for unit in units:
		if _can_plan_for(unit):
			actions.add(ActionPlan.new(unit, ActionType.WAIT, unit.grid_position, null))
	return actions

func _can_plan_for(unit: Unit) -> bool:
	return is_instance_valid(unit) and unit.is_alive() and not unit.has_acted_this_turn

func _is_score_better(candidate: Array, current: Array) -> bool:
	for i in range(candidate.size()):
		if candidate[i] == current[i]:
			continue
		return candidate[i] < current[i]
	return false
