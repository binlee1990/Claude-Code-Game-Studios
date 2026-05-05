class_name HUDSystem
extends RefCounted

var resource_system: ResourceSystem
var storage_limits: StorageLimitSystem
var level_system: LevelSystem
var ui_manager: UIManager
var resource_rows := {}
var offline_summary_visible := false
var offline_summary := {}
var level_badge := ""
var level_badge_icon_path := ""
var layout_refresh_count := 0
var _refresh_pending := false
var _ftue_stage := 0
var _last_realm := "fanren"
var _realm_ceremony_pending := false


func _init(resources: ResourceSystem = null, storage: StorageLimitSystem = null, levels: LevelSystem = null, ui: UIManager = null) -> void:
	resource_system = resources
	storage_limits = storage
	level_system = levels
	ui_manager = ui
	_subscribe_ftue()
	_subscribe_realm()


func _subscribe_ftue() -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("ftue.stage_changed", _on_ftue_stage_changed)


func _on_ftue_stage_changed(payload: Dictionary) -> void:
	_ftue_stage = payload.get("new_stage", _ftue_stage)
	request_refresh()


func _subscribe_realm() -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("realm.advanced", _on_realm_advanced)


func _on_realm_advanced(payload: Dictionary) -> void:
	if str(payload.get("entity_id", "")) != "player":
		return
	var new_realm: String = payload.get("new_realm", "")
	var old_realm: String = payload.get("old_realm", "")
	_last_realm = new_realm
	_realm_ceremony_pending = true
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit("hud.realm_ceremony", {"old_realm": old_realm, "new_realm": new_realm})


## Return which HUD fields should be visible at current FTUE stage.
## Screen-flow.md §3: 4 fields (Stage 0) → 12 fields (Stage 5).
func get_field_visibility() -> Dictionary:
	match _ftue_stage:
		0:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": false, "zone_selector": false,
				"lingshi": false, "herb": false,
				"zone_info": false, "breakthrough_hint": false,
				"offline_indicator": false, "stance_switch": false,
			}
		1:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": true, "zone_selector": true,
				"lingshi": false, "herb": false,
				"zone_info": false, "breakthrough_hint": false,
				"offline_indicator": false, "stance_switch": false,
			}
		2:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": true, "zone_selector": true,
				"lingshi": true, "herb": true,
				"zone_info": false, "breakthrough_hint": false,
				"offline_indicator": false, "stance_switch": false,
			}
		3:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": true, "zone_selector": true,
				"lingshi": true, "herb": true,
				"zone_info": true, "breakthrough_hint": true,
				"offline_indicator": false, "stance_switch": false,
			}
		4:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": true, "zone_selector": true,
				"lingshi": true, "herb": true,
				"zone_info": true, "breakthrough_hint": true,
				"offline_indicator": false, "stance_switch": true,
			}
		_:
			return {
				"lingqi": true, "xiuwei": true, "level_realm": true, "settings": true,
				"combat_status": true, "zone_selector": true,
				"lingshi": true, "herb": true,
				"zone_info": true, "breakthrough_hint": true,
				"offline_indicator": true, "stance_switch": true,
			}


func handle_resource_changed(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	refresh_resource(resource_id)
	request_refresh()


func refresh_resource(resource_id: String) -> void:
	if resource_system == null or resource_id.is_empty():
		return
	var value := resource_system.get_value(resource_id)
	var row := {"text": NumberFormatter.format(value), "state": "normal"}
	var definition := resource_system.get_definition(resource_id)
	var metadata = definition.get("metadata", {})
	if typeof(metadata) == TYPE_DICTIONARY:
		var icon_path := str(metadata.get("icon_path", ""))
		if not icon_path.is_empty():
			row["icon_path"] = icon_path
	if storage_limits != null:
		var state := storage_limits.get_capacity_state(resource_id)
		row["fill_ratio"] = state.get("fill_ratio", 0.0)
		if str(state.get("state", "")) == "warning" or str(state.get("state", "")) == "full":
			row["state"] = str(state["state"])
	resource_rows[resource_id] = row


func handle_offline_settled(summary: Dictionary) -> void:
	offline_summary_visible = true
	offline_summary = summary.duplicate(true)
	request_refresh()


func handle_level_changed(payload: Dictionary) -> void:
	if str(payload.get("entity_id", "")) != "player" or level_system == null:
		return
	var realm := level_system.get_realm("player")
	level_badge = "Lv.%d %s" % [level_system.get_level("player"), realm]
	level_badge_icon_path = _realm_icon_path(realm)
	request_refresh()


func request_refresh() -> void:
	_refresh_pending = true
	if ui_manager != null:
		ui_manager.request_layout_rebuild()


func flush_refresh() -> void:
	if not _refresh_pending:
		return
	layout_refresh_count += 1
	_refresh_pending = false
	if ui_manager != null:
		ui_manager.flush_layout()


func _realm_icon_path(realm: String) -> String:
	match realm:
		"fanren":
			return "res://assets/ui/icons/realm/mortal.png"
		"lianqi":
			return "res://assets/ui/icons/realm/qi_refining.png"
		"zhuji":
			return "res://assets/ui/icons/realm/foundation.png"
		"jindan":
			return "res://assets/ui/icons/realm/golden_core.png"
		"yuanying":
			return "res://assets/ui/icons/realm/yuanying.png"
		"huashen":
			return "res://assets/ui/icons/realm/huashen.png"
		"heti":
			return "res://assets/ui/icons/realm/heti.png"
		_:
			return ""
