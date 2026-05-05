class_name FTUEStateMachine
extends RefCounted

## FTUE (First-Time User Experience) state machine.
##
## Tracks 6 onboarding stages (0–5). Transitions are triggered by gameplay
## events via EventBus subscriptions — not by UI polling.  Each stage
## transition emits "ftue.stage_changed" with the new stage index and a
## narrative text key so the UI can display the corresponding text from
## `design/narrative/world-skeleton.md` §4 and §6.

const STAGE_NAMES := {
	0: "first_cultivation",
	1: "combat_unlocked",
	2: "first_loot",
	3: "zone_awareness",
	4: "first_breakthrough",
	5: "first_offline_return",
}

const STAGE_NARRATIVE := {
	0: "你盘膝坐定，闭目凝神。山风穿过窗棂，带来第一缕若有若无的天地灵气。",
	1: "体内灵气似乎冲破了什么关窍……你隐约感知到山中有异动。",
	2: "你捡起了第一片灵草——这山里的东西，或许比想象的值钱。",
	3: "道基渐固，你感受到谷中传来的灵气波动——那是更深处的地方。",
	4: "灵气在丹田凝成漩涡——突破的契机到了。",
	5: "闭关归来，洞府中灵气自行汇聚。修行一日未辍。",
}

const STAGE_UNLOCKS := {
	0: [],  # cultivation screen only
	1: ["combat_screen", "left_nav_tab_2"],
	2: ["resources_screen", "left_nav_tab_3"],
	3: ["zone_selector", "zone_forest_visible"],
	4: ["cultivation_stance_condense"],
	5: ["offline_settlement_screen", "left_nav_tab_5"],
}

var _stage := 0
var _completed := false
var _event_bus: EventBus
var _has_saved := false


func _init(bus: EventBus = null) -> void:
	_event_bus = bus
	if _event_bus:
		_subscribe()


func _subscribe() -> void:
	_event_bus.subscribe("resource.lingqi.changed", _on_resource_changed)
	_event_bus.subscribe("combat.finished", _on_combat_finished)
	_event_bus.subscribe("item.acquired", _on_item_acquired)
	_event_bus.subscribe("realm.advanced", _on_realm_advanced)
	_event_bus.subscribe("offline.settled", _on_offline_settled)
	_event_bus.subscribe("zone.unlocked", _on_zone_unlocked)


## Advance to the next stage if the current one's condition is met.
## Returns the new stage, or -1 if no transition occurred.
func check_transition() -> int:
	if _completed:
		return -1
	_has_saved = false
	return _stage


func advance_to(stage: int) -> void:
	if stage <= _stage or stage > 5:
		return
	var old := _stage
	_stage = stage
	if _stage >= 5:
		_completed = true
	if _event_bus:
		_event_bus.emit("ftue.stage_changed", {
			"old_stage": old,
			"new_stage": _stage,
			"stage_name": STAGE_NAMES.get(_stage, ""),
			"narrative": STAGE_NARRATIVE.get(_stage, ""),
			"unlocks": STAGE_UNLOCKS.get(_stage, []),
			"completed": _completed,
		})


func get_stage() -> int:
	return _stage


func is_completed() -> bool:
	return _completed


func get_stage_name(stage: int = -1) -> String:
	var s := stage if stage >= 0 else _stage
	return STAGE_NAMES.get(s, "")


func get_narrative(stage: int = -1) -> String:
	var s := stage if stage >= 0 else _stage
	return STAGE_NARRATIVE.get(s, "")


func get_unlocks(stage: int = -1) -> Array:
	var s := stage if stage >= 0 else _stage
	return STAGE_UNLOCKS.get(s, [])


## Serialize for SaveManager.
func collect_state() -> Dictionary:
	_has_saved = true
	return {
		"stage": _stage,
		"completed": _completed,
	}


## Restore from save.
func restore_state(data: Dictionary) -> void:
	if data.is_empty():
		_stage = 0
		_completed = false
		return
	_stage = data.get("stage", 0)
	_completed = data.get("completed", false)


func _on_resource_changed(payload: Dictionary) -> void:
	if _stage != 0 or _completed:
		return
	var res_id: String = payload.get("resource_id", "")
	var new_val = payload.get("new_value")
	if res_id == "lingqi" and new_val != null and _to_float(new_val) >= 100.0:
		advance_to(1)


func _on_combat_finished(payload: Dictionary) -> void:
	if _stage >= 2 or _completed:
		return
	advance_to(2)


func _on_item_acquired(payload: Dictionary) -> void:
	if _stage >= 2 or _completed:
		return
	var item_id: String = payload.get("item_id", "")
	if item_id in ["herb", "lingshi"]:
		advance_to(2)


func _on_zone_unlocked(payload: Dictionary) -> void:
	if _stage >= 3 or _completed:
		return
	var zone_id: String = payload.get("zone_id", "")
	if zone_id == "zone_forest":
		advance_to(3)


func _on_realm_advanced(payload: Dictionary) -> void:
	if _stage >= 4 or _completed:
		return
	var new_realm: String = payload.get("new_realm", "")
	if new_realm == "lianqi":
		advance_to(4)


func _on_offline_settled(_payload: Dictionary) -> void:
	if _stage >= 5 or _completed:
		return
	advance_to(5)


func _to_float(value: Variant) -> float:
	if value is BigNumber:
		return value.to_float()
	if typeof(value) == TYPE_DICTIONARY:
		return BigNumber.from_dict(value).to_float()
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return float(str(value))
