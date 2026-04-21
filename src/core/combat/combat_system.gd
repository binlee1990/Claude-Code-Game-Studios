class_name CombatSystem
extends Node

## Manages combat flow: turn order, team tracking, damage, end conditions.

enum BattleState { IDLE, UNIT_TURN, ANIMATING, BATTLE_END }
enum CombatResult { NONE, VICTORY, DEFEAT, DRAW }
enum Team { PLAYER, ENEMY }

var _state: BattleState = BattleState.IDLE
var _result: CombatResult = CombatResult.NONE
var _current_turn: int = 0
var _turn_order: Array = []
var _current_actor_index: int = 0
var _combat_units: Dictionary = {}
var _interrupted: bool = false

## Register a unit with team and HP for combat.
func register_unit(unit: Unit, team: int, max_hp: int) -> void:
	_combat_units[unit] = {
		"team": team,
		"hp": max_hp,
		"max_hp": max_hp,
		"is_alive": true,
	}

## Set turn order directly (backward compat for turn-order-only usage).
func set_units(units: Array) -> void:
	_turn_order = units.duplicate()

## Initialize battle state and generate first turn order.
func start_battle(battle_id: String, map_id: String, difficulty: int) -> void:
	_current_turn = 1
	_current_actor_index = 0
	_result = CombatResult.NONE
	_interrupted = false
	if _combat_units.size() > 0:
		_turn_order = []
		for u in _combat_units:
			if _combat_units[u]["is_alive"]:
				_turn_order.append(u)
	_state = BattleState.UNIT_TURN
	_calculate_turn_order()
	GameEvents.combat_started.emit()

## Sort turn_order by AGI descending; random tie-break for same AGI.
func _calculate_turn_order() -> void:
	if _turn_order.is_empty():
		return
	var tiebreakers: Dictionary = {}
	for unit in _turn_order:
		tiebreakers[unit] = randi()
	_turn_order.sort_custom(func(a, b):
		var a_agi: int = a.get_attribute(AttributeNames.Attribute.AGI)
		var b_agi: int = b.get_attribute(AttributeNames.Attribute.AGI)
		if a_agi != b_agi:
			return a_agi > b_agi
		return tiebreakers[a] > tiebreakers[b]
	)

## Get current acting unit.
func get_current_actor() -> Unit:
	if _current_actor_index >= 0 and _current_actor_index < _turn_order.size():
		return _turn_order[_current_actor_index]
	return null

## End current actor's turn; advances to next alive unit or new round.
func end_turn() -> void:
	if _current_actor_index < _turn_order.size():
		var actor = _turn_order[_current_actor_index]
		if is_unit_alive(actor):
			GameEvents.turn_ended.emit(actor)
	_advance_to_next()

func _advance_to_next() -> void:
	_current_actor_index += 1
	while _current_actor_index < _turn_order.size():
		if is_unit_alive(_turn_order[_current_actor_index]):
			break
		_current_actor_index += 1
	if _current_actor_index >= _turn_order.size():
		_next_round()

func _next_round() -> void:
	_current_turn += 1
	_current_actor_index = 0
	if _combat_units.size() > 0:
		_turn_order = []
		for u in _combat_units:
			if _combat_units[u]["is_alive"]:
				_turn_order.append(u)
	_calculate_turn_order()

## Apply damage to target. Returns actual damage dealt.
func apply_damage(target: Unit, amount: int, source: Unit = null) -> int:
	if not _combat_units.has(target) or not _combat_units[target]["is_alive"]:
		return 0
	var data: Dictionary = _combat_units[target]
	var old_hp: int = data["hp"]
	data["hp"] = maxi(data["hp"] - amount, 0)
	var actual: int = old_hp - data["hp"]
	GameEvents.health_changed.emit(target, old_hp, data["hp"])
	if data["hp"] <= 0:
		data["is_alive"] = false
		GameEvents.unit_died.emit(target, source)
		if target == get_current_actor():
			_interrupted = true
	return actual

## Check end conditions. Returns CombatResult and updates state if battle ends.
func check_end_conditions() -> int:
	var player_alive := false
	var enemy_alive := false
	for unit in _combat_units:
		if _combat_units[unit]["is_alive"]:
			if _combat_units[unit]["team"] == Team.PLAYER:
				player_alive = true
			else:
				enemy_alive = true
	if not enemy_alive:
		_result = CombatResult.VICTORY
		_state = BattleState.BATTLE_END
		return CombatResult.VICTORY
	if not player_alive:
		_result = CombatResult.DEFEAT
		_state = BattleState.BATTLE_END
		return CombatResult.DEFEAT
	return CombatResult.NONE

## Get unit's current HP.
func get_unit_hp(unit: Unit) -> int:
	if not _combat_units.has(unit):
		return 0
	return _combat_units[unit]["hp"]

## Check if unit is alive. Unregistered units assumed alive.
func is_unit_alive(unit) -> bool:
	if not _combat_units.has(unit):
		return true
	return _combat_units[unit]["is_alive"]

## Get unit's team.
func get_unit_team(unit: Unit) -> int:
	if not _combat_units.has(unit):
		return -1
	return _combat_units[unit]["team"]

## Was current action interrupted by actor death?
func is_interrupted() -> bool:
	return _interrupted

## Clear interrupt flag.
func clear_interrupt() -> void:
	_interrupted = false

func get_turn_order() -> Array:
	return _turn_order

func get_current_turn() -> int:
	return _current_turn

func get_state() -> BattleState:
	return _state

func get_result() -> CombatResult:
	return _result
