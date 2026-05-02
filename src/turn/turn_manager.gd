class_name TurnManager extends RefCounted

const TurnState = preload("res://src/core/turn_state.gd")

var current_state = TurnState.MATCH_NOT_STARTED
var active_faction: Faction.Type
var turn_number: int = 1
var turn_cap: int

var _all_units = []
var _victory_checker: VictoryChecker
var _ai_controller: AIController
var _turn_config: TurnConfig

signal match_started()
signal turn_started(turn_number: int)
signal faction_activated(faction: Faction.Type)
signal faction_phase_ended(faction: Faction.Type)
signal match_ended(reason: String, winner: Faction.Type)

func initialize(
	units,
	config: TurnConfig,
	victory_checker: VictoryChecker,
	ai_controller: AIController
) -> void:
	_all_units = units.duplicate()
	_turn_config = config
	turn_cap = config.turn_cap
	_victory_checker = victory_checker
	_ai_controller = ai_controller

func start_match() -> void:
	assert(current_state == TurnState.MATCH_NOT_STARTED, "start_match() called while match already in progress")
	assert(not _all_units.is_empty(), "Cannot start match with zero units")
	assert(_victory_checker != null, "VictoryChecker not injected")
	assert(_ai_controller != null, "AIController not injected")
	assert(_turn_config.validate(), "TurnConfig validation failed")

	active_faction = Faction.Type.PLAYER
	turn_number = 1
	_reset_all_units()
	_connect_unit_signals()
	current_state = TurnState.FACTION_PHASE_ACTIVE

	match_started.emit()
	turn_started.emit(1)
	faction_activated.emit(Faction.Type.PLAYER)
	_end_if_match_already_decided()

func end_current_faction_turn() -> void:
	if current_state != TurnState.FACTION_PHASE_ACTIVE:
		return
	_transition_to_ending()

func _check_auto_advance() -> bool:
	for u in _all_units:
		if not is_instance_valid(u):
			continue
		if u.faction == active_faction and u.is_alive() and not u.has_acted_this_turn:
			return false
	return true

func _on_unit_action_completed(_unit: Unit) -> void:
	if current_state != TurnState.FACTION_PHASE_ACTIVE:
		return
	if _check_auto_advance():
		_transition_to_ending()

func _on_unit_died(unit: Unit) -> void:
	if current_state != TurnState.FACTION_PHASE_ACTIVE:
		return
	_all_units.erase(unit)
	_check_faction_elimination()

func _check_faction_elimination() -> void:
	if _count_alive(active_faction) == 0 or _count_alive(_other_faction(active_faction)) == 0:
		_transition_to_ending()

func _end_if_match_already_decided() -> void:
	var result := _victory_checker.determine_winner(_all_units, turn_number, turn_cap)
	if result.winner == Faction.Type.NONE and result.reason == "":
		return
	current_state = TurnState.MATCH_ENDED
	match_ended.emit(result.reason, result.winner)

func _transition_to_ending() -> void:
	current_state = TurnState.FACTION_PHASE_ENDING
	faction_phase_ended.emit(active_faction)

	var next := _other_faction(active_faction)

	for u in _all_units:
		if is_instance_valid(u) and u.faction == next:
			u.reset_action_state()

	if active_faction == Faction.Type.ENEMY:
		turn_number += 1

	var result := _victory_checker.determine_winner(_all_units, turn_number, turn_cap)

	if result.reason != "":
		current_state = TurnState.MATCH_ENDED
		match_ended.emit(result.reason, result.winner)
	else:
		active_faction = next
		current_state = TurnState.FACTION_PHASE_ACTIVE
		faction_activated.emit(next)
		if next == Faction.Type.PLAYER:
			turn_started.emit(turn_number)

func _reset_all_units() -> void:
	for u in _all_units:
		if is_instance_valid(u):
			u.reset_action_state()

func _connect_unit_signals() -> void:
	for u in _all_units:
		if is_instance_valid(u):
			if not u.unit_died.is_connected(_on_unit_died):
				u.unit_died.connect(_on_unit_died)

func _count_alive(faction: Faction.Type) -> int:
	var count := 0
	for u in _all_units:
		if is_instance_valid(u) and u.faction == faction and u.is_alive():
			count += 1
	return count

func _other_faction(f: Faction.Type) -> Faction.Type:
	return Faction.Type.ENEMY if f == Faction.Type.PLAYER else Faction.Type.PLAYER
