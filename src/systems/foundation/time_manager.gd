class_name TimeManager
extends Node

const MAX_OFFLINE_SECONDS := 28800.0
const MAX_SPEED := 100.0
const MIN_SPEED := 0.0

static var instance: TimeManager

var _speed_sources := {}
var _real_ref := 0.0
var _game_ref := 0.0
var _frozen := false
var _test_real_time := -1.0


func _ready() -> void:
	if instance == null:
		instance = self
	_reset_snapshot(get_real_time(), 0.0)


## Returns the active autoload instance when one has been registered by the scene tree.
static func get_instance() -> TimeManager:
	return instance


## Overrides the real-time source for deterministic tests; pass a negative value to clear it.
func set_test_real_time(value: float) -> void:
	_test_real_time = value


## Returns authoritative real Unix time in seconds.
func get_real_time() -> float:
	if _test_real_time >= 0.0:
		return _test_real_time
	return Time.get_unix_time_from_system()


## Returns accelerated game time in seconds.
func get_game_time() -> float:
	if _frozen:
		return _game_ref
	return _game_ref + max(0.0, get_real_time() - _real_ref) * get_effective_speed()


## Returns the current multiplicative speed, clamped to MAX_SPEED.
func get_effective_speed() -> float:
	var speed := 1.0
	for value in _speed_sources.values():
		speed *= float(value)
	return clamp(speed, MIN_SPEED, MAX_SPEED)


## Returns game-time delta since a caller-owned timestamp.
func get_game_delta_since(last_game_time: float) -> float:
	return max(0.0, get_game_time() - last_game_time)


## Returns real-time delta since a caller-owned timestamp.
func get_real_delta_since(last_real_time: float) -> float:
	return max(0.0, get_real_time() - last_real_time)


## Adds or replaces a multiplicative speed source.
func add_speed_source(source_id: String, multiplier: float) -> void:
	if source_id.strip_edges().is_empty():
		push_warning("Speed source id cannot be empty")
		return
	_sync_snapshot()
	if multiplier <= 0.0:
		push_warning("Invalid speed multiplier: %s from source %s, clamped to 1.0" % [str(multiplier), source_id])
		multiplier = 1.0
	_speed_sources[source_id] = multiplier
	_emit_time_event("time.speed_changed", {"effective_speed": get_effective_speed()})


## Removes a speed source if present. Missing sources are ignored.
func remove_speed_source(source_id: String) -> void:
	if not _speed_sources.has(source_id):
		return
	_sync_snapshot()
	_speed_sources.erase(source_id)
	_emit_time_event("time.speed_changed", {"effective_speed": get_effective_speed()})


## Freezes game time while real time continues.
func freeze() -> void:
	if _frozen:
		return
	_sync_snapshot()
	_frozen = true
	_emit_time_event("time.frozen", {"game_time": _game_ref})


## Unfreezes game time and uses the current speed from this point onward.
func unfreeze() -> void:
	if not _frozen:
		return
	_real_ref = get_real_time()
	_frozen = false
	_emit_time_event("time.unfrozen", {"game_time": _game_ref})


## Calculates and emits capped offline delta from an exit timestamp.
func calculate_offline_delta(exit_real_timestamp: float) -> Dictionary:
	var raw_delta := get_real_time() - exit_real_timestamp
	if raw_delta < 0.0:
		push_warning("System clock went backwards: delta=%ss" % str(raw_delta))
		raw_delta = 0.0
	var real_delta: float = min(raw_delta, MAX_OFFLINE_SECONDS)
	var payload := {
		"real_delta": real_delta,
		"game_delta": real_delta,
	}
	if real_delta > 0.0:
		_emit_time_event("time.offline_delta", payload)
	return payload


## Collects save data for the SaveManager namespace.
func collect_save_data() -> Dictionary:
	return {
		"exit_real_timestamp": get_real_time(),
		"game_ref": get_game_time(),
		"real_ref": get_real_time(),
		"speed_sources": _speed_sources.duplicate(),
		"frozen": _frozen,
	}


## Restores save data and emits offline delta when an exit timestamp exists.
func restore_save_data(data: Dictionary) -> Dictionary:
	_speed_sources = data.get("speed_sources", {}).duplicate()
	_game_ref = float(data.get("game_ref", 0.0))
	_real_ref = float(data.get("real_ref", get_real_time()))
	_frozen = bool(data.get("frozen", false))
	if data.has("exit_real_timestamp"):
		return calculate_offline_delta(float(data["exit_real_timestamp"]))
	return {"real_delta": 0.0, "game_delta": 0.0}


## Resets all mutable state for isolated tests.
func reset_for_test(real_time: float = 0.0) -> void:
	_speed_sources.clear()
	_frozen = false
	_test_real_time = real_time
	_reset_snapshot(real_time, 0.0)


func _sync_snapshot() -> void:
	_game_ref = get_game_time()
	_real_ref = get_real_time()


func _reset_snapshot(real_ref: float, game_ref: float) -> void:
	_real_ref = real_ref
	_game_ref = game_ref


func _emit_time_event(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
