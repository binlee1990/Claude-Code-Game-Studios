class_name OutputMultiplierSystem
extends RefCounted

const PASSIVE_POOLS := ["realm", "equipment", "zone", "buff"]
const REQUIRED_SOURCE_FIELDS := ["resource_id", "source_type", "value", "source_id"]

var modifier_engine: ModifierEngine
var data_config: Object
var base_rates := {}
var fractional_carry := {}
var resource_configs := {}
var active_sources := {}
var _listening_for_expiry := false


func _init(engine: ModifierEngine = null, config: Object = null) -> void:
	modifier_engine = engine if engine != null else ModifierEngine.new()
	data_config = config


func set_data_config(config: Object) -> void:
	data_config = config


func set_modifier_engine(engine: ModifierEngine) -> void:
	modifier_engine = engine if engine != null else ModifierEngine.new()


## Loads production_config from DataConfig and initializes base rates plus fractional carry.
func load_config() -> void:
	var previous_carry := fractional_carry.duplicate()
	base_rates.clear()
	resource_configs.clear()
	fractional_carry.clear()
	var table = _read_config_table()
	if table == null:
		table = {}
	if typeof(table) != TYPE_DICTIONARY:
		push_warning("OutputMultiplierSystem: production_config must be a Dictionary")
		table = {}
	for resource_id in table.keys():
		var raw = table[resource_id]
		if typeof(raw) != TYPE_DICTIONARY:
			push_warning("OutputMultiplierSystem: invalid resource config skipped: %s" % str(resource_id))
			continue
		var config: Dictionary = raw
		var id := str(resource_id)
		var passive_sources := []
		for source_type in config.get("passive_sources", []):
			passive_sources.append(str(source_type))
		resource_configs[id] = {
			"base_rate_per_second": _parse_float(config.get("base_rate_per_second", 0.0)),
			"allows_passive": bool(config.get("allows_passive", false)),
			"passive_sources": passive_sources,
		}
		base_rates[id] = float(resource_configs[id]["base_rate_per_second"])
		fractional_carry[id] = float(previous_carry.get(id, 0.0))
	_subscribe_modifier_expiry()


func reload_config() -> void:
	if data_config != null and data_config.has_method("reload_table"):
		data_config.call("reload_table", "production_config")
	load_config()


func activate_source(source_def: Dictionary) -> String:
	var missing := []
	for field in REQUIRED_SOURCE_FIELDS:
		if not source_def.has(field):
			missing.append(field)
	if not missing.is_empty():
		push_warning("OutputMultiplierSystem: source missing fields: %s" % str(missing))
		return ""
	var resource_id := str(source_def["resource_id"]).strip_edges()
	var source_type := str(source_def["source_type"]).strip_edges()
	var source_id := str(source_def["source_id"]).strip_edges()
	var value := float(source_def["value"])
	if active_sources.has(source_id):
		push_warning("OutputMultiplierSystem: source already active: %s" % source_id)
		return ""
	if not _can_use_resource(resource_id, true):
		return ""
	if not _is_passive_source_allowed(resource_id, source_type):
		push_warning("OutputMultiplierSystem: source_type '%s' is not allowed for resource '%s'" % [source_type, resource_id])
		return ""
	if source_id.is_empty():
		push_warning("OutputMultiplierSystem: source_id cannot be empty")
		return ""
	if is_nan(value) or is_inf(value) or value == 0.0:
		push_warning("OutputMultiplierSystem: invalid multiplier value '%s' from source '%s'" % [str(value), source_id])
		return ""
	var modifier_id := modifier_engine.register({
		"target": make_target(resource_id),
		"type": ModifierEngine.MULT,
		"value": value,
		"pool": source_type,
		"source": source_id,
		"duration": float(source_def.get("duration", 0.0)),
	})
	if modifier_id.is_empty():
		return ""
	active_sources[source_id] = {"modifier_id": modifier_id, "resource_id": resource_id}
	_emit_multiplier_changed(resource_id, source_id, "activated")
	return modifier_id


func deactivate_source(source_id: String) -> int:
	if not active_sources.has(source_id):
		return 0
	var source: Dictionary = active_sources[source_id]
	var removed := 0
	if modifier_engine.unregister(str(source["modifier_id"])):
		removed = 1
	active_sources.erase(source_id)
	if removed > 0:
		_emit_multiplier_changed(str(source["resource_id"]), source_id, "deactivated")
	return removed


func get_production_rate(resource_id: String) -> float:
	if not _can_use_resource(resource_id, false):
		return 0.0
	return float(base_rates.get(resource_id, 0.0)) * get_multiplier(resource_id)


func get_tick_amount(resource_id: String, delta_seconds: float) -> BigNumber:
	if delta_seconds <= 0.0:
		push_warning("OutputMultiplierSystem: delta_seconds must be positive")
		return BigNumber.zero()
	if not fractional_carry.has(resource_id):
		fractional_carry[resource_id] = 0.0
	var accumulated := get_production_rate(resource_id) * delta_seconds + float(fractional_carry.get(resource_id, 0.0))
	if accumulated < 1.0:
		fractional_carry[resource_id] = accumulated
		return BigNumber.zero()
	fractional_carry[resource_id] = 0.0
	return BigNumber.from_float(accumulated)


func get_multiplier(resource_id: String) -> float:
	if not _can_use_resource(resource_id, false):
		return 0.0
	return modifier_engine.get_multiplier(make_target(resource_id))


func get_breakdown(resource_id: String) -> Dictionary:
	if not _can_use_resource(resource_id, false):
		return {
			"base_rate": 0.0,
			"add_sum": 0.0,
			"pools": {},
			"final_multiplier": 0.0,
			"rate_per_second": 0.0,
			"fractional_carry": float(fractional_carry.get(resource_id, 0.0)),
		}
	var target := make_target(resource_id)
	var raw_breakdown := modifier_engine.get_breakdown(target)
	var pools: Dictionary = raw_breakdown.get("pools", {})
	var normalized_pools := {}
	for pool in PASSIVE_POOLS:
		normalized_pools[pool] = float(pools.get(pool, 1.0))
	var final_multiplier := float(raw_breakdown.get("final_mult", 1.0))
	return {
		"base_rate": float(base_rates.get(resource_id, 0.0)),
		"add_sum": float(raw_breakdown.get("add_sum", 0.0)),
		"pools": normalized_pools,
		"final_multiplier": final_multiplier,
		"rate_per_second": float(base_rates.get(resource_id, 0.0)) * final_multiplier,
		"fractional_carry": float(fractional_carry.get(resource_id, 0.0)),
	}


func make_target(resource_id: String) -> String:
	return "%s_production" % resource_id


func _read_config_table() -> Variant:
	if data_config == null or not data_config.has_method("get_all"):
		push_warning("OutputMultiplierSystem: DataConfig unavailable; using empty production config")
		return {}
	return data_config.call("get_all", "production_config")


func _can_use_resource(resource_id: String, warn_passive: bool) -> bool:
	if not resource_configs.has(resource_id):
		push_warning("OutputMultiplierSystem: unknown resource_id: %s" % resource_id)
		return false
	if not bool(resource_configs[resource_id].get("allows_passive", false)):
		if warn_passive:
			push_warning("OutputMultiplierSystem: resource does not allow passive production: %s" % resource_id)
		return false
	return true


func _is_passive_source_allowed(resource_id: String, source_type: String) -> bool:
	var sources: Array = resource_configs[resource_id].get("passive_sources", [])
	return sources.has(source_type)


func _parse_float(value: Variant) -> float:
	if typeof(value) == TYPE_STRING:
		var text := str(value).strip_edges()
		if text.is_valid_float():
			return text.to_float()
		return 0.0
	return float(value)


func _subscribe_modifier_expiry() -> void:
	if _listening_for_expiry:
		return
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.subscribe("modifier_expired", _on_modifier_expired)
	_listening_for_expiry = true


func _on_modifier_expired(modifier: Dictionary) -> void:
	var source_id := str(modifier.get("source", ""))
	if not active_sources.has(source_id):
		return
	var source: Dictionary = active_sources[source_id]
	active_sources.erase(source_id)
	_emit_multiplier_changed(str(source["resource_id"]), source_id, "deactivated")


func _emit_multiplier_changed(resource_id: String, source_id: String, action: String) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit("production_multiplier_changed", {
			"resource_id": resource_id,
			"source_id": source_id,
			"action": action,
			"new_multiplier": get_multiplier(resource_id),
		})
