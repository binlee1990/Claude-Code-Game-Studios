class_name CombatSystem
extends Node

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, ANIMATING, BATTLE_END }

var _state: BattleState = BattleState.IDLE
var _current_turn: int = 0
var _turn_order: Array = []
var _current_actor_index: int = 0

func start_battle(battle_id: String, map_id: String, difficulty: int) -> void:
	_state = BattleState.PLAYER_TURN
	_current_turn = 1
	_calculate_turn_order()
	GameEvents.battle_started.emit(battle_id, map_id, difficulty)

func _calculate_turn_order() -> void:
	_turn_order.sort_custom(func(a, b): return a.speed > b.speed)

func execute_turn(actor_id: int) -> void:
	GameEvents.turn_started.emit(actor_id, _current_turn)

func end_turn(actor_id: int) -> void:
	GameEvents.turn_ended.emit(actor_id, _current_turn)
	_current_actor_index += 1
	if _current_actor_index >= _turn_order.size():
		_next_round()

func _next_round() -> void:
	_current_turn += 1
	_current_actor_index = 0
