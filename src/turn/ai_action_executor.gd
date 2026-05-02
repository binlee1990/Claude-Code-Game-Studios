class_name AIActionExecutor extends RefCounted

const UnitState = preload("res://src/core/unit_state.gd")

var emit_warnings: bool = true

func execute(
	plan: ActionPlan,
	active_faction: Faction.Type,
	map: Map,
	attack_resolver: AttackResolver,
) -> Unit:
	if plan == null:
		_warn("AIActionExecutor: null ActionPlan skipped")
		return null
	if map == null or attack_resolver == null:
		_warn("AIActionExecutor: map and attack resolver must be injected")
		return null

	var unit := plan.unit
	if not _can_execute_unit(unit, active_faction):
		return null

	if plan.move_target != unit.grid_position:
		if not _execute_move(unit, plan.move_target, map):
			_finish_unit(unit)
			return unit

	if plan.attack_target != null:
		_execute_attack(unit, plan.attack_target, attack_resolver)

	if not unit.has_acted_this_turn:
		_finish_unit(unit)
	return unit

func _can_execute_unit(unit: Unit, active_faction: Faction.Type) -> bool:
	if not is_instance_valid(unit):
		_warn("AIActionExecutor: invalid unit skipped")
		return false
	if unit.faction != active_faction:
		_warn("AIActionExecutor: unit faction does not match active faction")
		return false
	if not unit.is_alive():
		return false
	if unit.has_acted_this_turn:
		return false
	return true

func _execute_move(unit: Unit, target: Vector2i, map: Map) -> bool:
	var from := unit.grid_position
	if unit.action_state == UnitState.IDLE:
		unit.action_state = UnitState.SELECTED
	if not map.move_unit(unit, from, target):
		_warn("AIActionExecutor: move rejected from %s to %s" % [from, target])
		return false
	unit.action_state = UnitState.MOVED
	return true

func _execute_attack(unit: Unit, target: Unit, attack_resolver: AttackResolver) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		_warn("AIActionExecutor: attack target is invalid or dead")
		return
	if unit.action_state == UnitState.IDLE:
		unit.action_state = UnitState.SELECTED
	var result := attack_resolver.execute_attack(unit, target)
	if not result.is_valid:
		_warn("AIActionExecutor: attack rejected")

func _finish_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or not unit.is_alive():
		return
	unit.has_acted_this_turn = true
	unit.action_state = UnitState.ACTED

func _warn(message: String) -> void:
	if emit_warnings:
		push_warning(message)
