class_name EventBus
extends Node

const MAX_SUBSCRIBERS_PER_EVENT := 128
const MAX_EMIT_DEPTH := 8
const HIGH_EMIT_FREQUENCY_THRESHOLD := 50

static var instance: EventBus

var debug_enabled := false
var _subscribers := {}
var _pattern_subscribers := []
var _pending_operations := []
var _emitting := false
var _emit_stack := []
var _coalesced_events := {}
var _frame_emit_counts := {}


func _ready() -> void:
	if instance == null:
		instance = self


func _process(_delta: float) -> void:
	flush_coalesced()
	_report_high_frequency_events()
	_frame_emit_counts.clear()


## Returns the active autoload instance when one has been registered by the scene tree.
static func get_instance() -> EventBus:
	return instance


## Enables or disables debug logging for event delivery.
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled


## Subscribes a callable to an exact event name.
func subscribe(event_name: String, target: Callable) -> void:
	if _emitting:
		_pending_operations.append({"op": "subscribe", "event": event_name, "callable": target, "once": false})
		return
	_subscribe_now(event_name, target, false)


## Subscribes a callable to an exact event name and removes it after first delivery.
func subscribe_once(event_name: String, target: Callable) -> void:
	if _emitting:
		_pending_operations.append({"op": "subscribe", "event": event_name, "callable": target, "once": true})
		return
	_subscribe_now(event_name, target, true)


## Removes an exact event subscription. Missing subscriptions are ignored.
func unsubscribe(event_name: String, target: Callable) -> void:
	if _emitting:
		_pending_operations.append({"op": "unsubscribe", "event": event_name, "callable": target})
		return
	_unsubscribe_now(event_name, target)


## Subscribes a callable to every event whose name begins with the prefix.
func subscribe_pattern(prefix: String, target: Callable) -> void:
	var clean_prefix := prefix.strip_edges()
	if clean_prefix.is_empty():
		push_warning("subscribe_pattern: prefix must not be empty")
		return
	if _emitting:
		_pending_operations.append({"op": "subscribe_pattern", "prefix": clean_prefix, "callable": target})
		return
	_subscribe_pattern_now(clean_prefix, target)


## Removes a pattern subscription. Exact and pattern subscriptions are independent.
func unsubscribe_pattern(prefix: String, target: Callable) -> void:
	if _emitting:
		_pending_operations.append({"op": "unsubscribe_pattern", "prefix": prefix, "callable": target})
		return
	_unsubscribe_pattern_now(prefix, target)


## Emits an exact event synchronously to exact subscribers, then matching pattern subscribers.
func emit(event_name: String, payload: Dictionary = {}) -> void:
	if _emit_stack.has(event_name):
		push_warning("Recursive emit detected: %s" % event_name)
		return
	if _emit_stack.size() >= MAX_EMIT_DEPTH:
		push_warning("Emit depth exceeded while emitting: %s" % event_name)
		return
	_count_frame_emit(event_name)
	if debug_enabled:
		print("EventBus.emit %s exact=%d pattern=%d" % [event_name, _subscribers.get(event_name, []).size(), _pattern_subscribers.size()])
	_emit_stack.append(event_name)
	_emitting = true
	_emit_exact(event_name, payload)
	_emit_patterns(event_name, payload)
	_emitting = false
	_emit_stack.pop_back()
	_apply_pending_operations()


## Coalesces latest-state display events for delivery at frame end or explicit flush.
func emit_coalesced(event_name: String, payload: Dictionary, coalesce_key: String = "") -> void:
	var key := "%s|%s" % [event_name, coalesce_key]
	_coalesced_events[key] = {"event": event_name, "payload": payload}


## Delivers all coalesced events immediately. Tests can call this directly.
func flush_coalesced() -> void:
	if _coalesced_events.is_empty():
		return
	var pending := _coalesced_events.values()
	_coalesced_events.clear()
	for item in pending:
		emit(item["event"], item["payload"])


## Removes all subscriptions and pending coalesced events. Intended for isolated tests.
func clear_all() -> void:
	_subscribers.clear()
	_pattern_subscribers.clear()
	_pending_operations.clear()
	_emit_stack.clear()
	_coalesced_events.clear()
	_frame_emit_counts.clear()


func _subscribe_now(event_name: String, target: Callable, once: bool) -> void:
	if not target.is_valid():
		push_warning("Invalid callable ignored during subscribe: %s" % event_name)
		return
	var list: Array = _subscribers.get(event_name, [])
	for entry in list:
		if entry["callable"] == target:
			return
	if list.size() >= MAX_SUBSCRIBERS_PER_EVENT:
		push_warning("Subscriber cap reached for %s" % event_name)
		return
	list.append({"callable": target, "once": once})
	_subscribers[event_name] = list


func _unsubscribe_now(event_name: String, target: Callable) -> void:
	if not _subscribers.has(event_name):
		return
	var list: Array = _subscribers[event_name]
	var kept := []
	for entry in list:
		if entry["callable"] != target:
			kept.append(entry)
	if kept.is_empty():
		_subscribers.erase(event_name)
	else:
		_subscribers[event_name] = kept


func _subscribe_pattern_now(prefix: String, target: Callable) -> void:
	if not target.is_valid():
		push_warning("Invalid callable ignored during pattern subscribe: %s" % prefix)
		return
	for entry in _pattern_subscribers:
		if entry["prefix"] == prefix and entry["callable"] == target:
			return
	_pattern_subscribers.append({"prefix": prefix, "callable": target})


func _unsubscribe_pattern_now(prefix: String, target: Callable) -> void:
	var kept := []
	for entry in _pattern_subscribers:
		if entry["prefix"] != prefix or entry["callable"] != target:
			kept.append(entry)
	_pattern_subscribers = kept


func _emit_exact(event_name: String, payload: Dictionary) -> void:
	var list: Array = _subscribers.get(event_name, [])
	var kept := []
	for entry in list:
		var target: Callable = entry["callable"]
		if not target.is_valid():
			push_warning("Invalid callable removed during %s" % event_name)
			continue
		target.call(payload)
		if not bool(entry["once"]):
			kept.append(entry)
	if kept.is_empty():
		_subscribers.erase(event_name)
	else:
		_subscribers[event_name] = kept


func _emit_patterns(event_name: String, payload: Dictionary) -> void:
	var kept := []
	for entry in _pattern_subscribers:
		var target: Callable = entry["callable"]
		if not target.is_valid():
			push_warning("Invalid pattern callable removed during %s" % event_name)
			continue
		kept.append(entry)
		if event_name.begins_with(str(entry["prefix"])):
			target.call(event_name, payload)
	_pattern_subscribers = kept


func _apply_pending_operations() -> void:
	var pending := _pending_operations.duplicate()
	_pending_operations.clear()
	for operation in pending:
		match operation["op"]:
			"subscribe":
				_subscribe_now(operation["event"], operation["callable"], operation["once"])
			"unsubscribe":
				_unsubscribe_now(operation["event"], operation["callable"])
			"subscribe_pattern":
				_subscribe_pattern_now(operation["prefix"], operation["callable"])
			"unsubscribe_pattern":
				_unsubscribe_pattern_now(operation["prefix"], operation["callable"])


func _count_frame_emit(event_name: String) -> void:
	_frame_emit_counts[event_name] = int(_frame_emit_counts.get(event_name, 0)) + 1


func _report_high_frequency_events() -> void:
	if not debug_enabled:
		return
	for event_name in _frame_emit_counts.keys():
		var count := int(_frame_emit_counts[event_name])
		if count > HIGH_EMIT_FREQUENCY_THRESHOLD:
			push_warning("High emit frequency: %s emitted %d times this frame" % [event_name, count])

