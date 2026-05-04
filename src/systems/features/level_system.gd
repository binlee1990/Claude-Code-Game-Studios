class_name LevelSystem
extends RefCounted

const MAX_LEVELS_PER_GAIN := 100
const MAX_LEVEL := 200
const REALM_PRODUCTION_TARGETS := ["lingqi_production", "xiuwei_production", "lingshi_production", "herb_production"]
const ATTR_IDS := ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"]

var resource_system: ResourceSystem
var attribute_system: AttributeSystem
var production_system: OutputMultiplierSystem
var _entries := {}
var _realm_table := []


func _init(resources: ResourceSystem = null, attributes: AttributeSystem = null, production: OutputMultiplierSystem = null) -> void:
	resource_system = resources
	attribute_system = attributes
	production_system = production
	_register_default_formulas()
	_load_default_realms()
	_subscribe_save_loaded()


func register_entity(entity_id: String) -> bool:
	if entity_id.strip_edges().is_empty():
		push_warning("LevelSystem: entity_id cannot be empty")
		return false
	if _entries.has(entity_id):
		push_warning("LevelSystem: duplicate entity_id: %s" % entity_id)
		return false
	_entries[entity_id] = {"level": 1, "realm": "fanren", "current_realm_id": 0}
	_recalculate_attributes(entity_id)
	return true


func unregister_entity(entity_id: String) -> int:
	if not _entries.has(entity_id):
		return 0
	var realm := str(_entries[entity_id].get("realm", ""))
	var removed := _unregister_realm_modifiers(entity_id, realm)
	_entries.erase(entity_id)
	return removed


func has_entity(entity_id: String) -> bool:
	return _entries.has(entity_id)


func get_all_entity_ids() -> Array:
	var ids := _entries.keys()
	ids.sort()
	return ids


func gain_exp(entity_id: String, amount: BigNumber) -> int:
	if not _entries.has(entity_id):
		push_warning("LevelSystem: entity not registered: %s" % entity_id)
		return 0
	if amount == null or amount.is_zero():
		return 0
	if resource_system == null or not resource_system.spend("exp", amount):
		return 0
	var entry: Dictionary = _entries[entity_id]
	if int(entry["level"]) >= MAX_LEVEL:
		resource_system.add("exp", amount)
		return 0
	var old_level := int(entry["level"])
	var old_realm := str(entry["realm"])
	var amount_remaining := amount.copy()
	var levels_gained := 0
	while levels_gained < MAX_LEVELS_PER_GAIN and int(entry["level"]) < MAX_LEVEL:
		var threshold_float := FormulaEngine.evaluate("level_exp", {"level": int(entry["level"])})
		if threshold_float <= 0.0:
			push_warning("LevelSystem: invalid level_exp threshold; MAX_LEVELS_PER_GAIN guard triggered")
			levels_gained = MAX_LEVELS_PER_GAIN
			break
		var threshold := BigNumber.from_float(threshold_float)
		if amount_remaining.less_than(threshold):
			break
		amount_remaining = amount_remaining.subtract(threshold)
		entry["level"] = int(entry["level"]) + 1
		levels_gained += 1
	if amount_remaining.greater_than(BigNumber.ZERO):
		resource_system.add("exp", amount_remaining)
		if levels_gained == MAX_LEVELS_PER_GAIN:
			push_warning("LevelSystem: MAX_LEVELS_PER_GAIN truncated gain for %s" % entity_id)
	if levels_gained == 0:
		_entries[entity_id] = entry
		return 0
	var derived := _derive_realm(int(entry["level"]))
	var new_realm := str(derived["realm"])
	entry["realm"] = new_realm
	entry["current_realm_id"] = int(derived["id"])
	_entries[entity_id] = entry
	if new_realm != old_realm:
		_swap_realm_modifiers(entity_id, old_realm, new_realm)
	_recalculate_attributes(entity_id)
	_emit("level.changed", {"entity_id": entity_id, "old_level": old_level, "new_level": int(entry["level"]), "levels_gained": levels_gained})
	if new_realm != old_realm:
		_emit("realm.advanced", {"entity_id": entity_id, "old_realm": old_realm, "new_realm": new_realm})
	return levels_gained


func try_level_up(entity_id: String) -> bool:
	if not OS.is_debug_build() or not _entries.has(entity_id):
		return false
	var entry: Dictionary = _entries[entity_id]
	entry["level"] = min(MAX_LEVEL, int(entry["level"]) + 1)
	_entries[entity_id] = entry
	_recalculate_attributes(entity_id)
	return true


func get_level(entity_id: String) -> int:
	return int(_entries.get(entity_id, {}).get("level", 0))


func get_realm(entity_id: String) -> String:
	return str(_entries.get(entity_id, {}).get("realm", ""))


func get_realm_id(entity_id: String) -> int:
	return int(_entries.get(entity_id, {}).get("current_realm_id", -1))


func get_exp_to_next(entity_id: String) -> BigNumber:
	if not _entries.has(entity_id):
		return BigNumber.zero()
	return BigNumber.from_float(FormulaEngine.evaluate("level_exp", {"level": get_level(entity_id)}))


func get_progress_ratio(entity_id: String) -> float:
	if resource_system == null or not _entries.has(entity_id):
		return 0.0
	var needed := get_exp_to_next(entity_id)
	if needed.is_zero():
		return 0.0
	return clamp(resource_system.get_value("exp").to_float() / needed.to_float(), 0.0, 1.0)


func get_realm_progress(entity_id: String) -> Dictionary:
	if not _entries.has(entity_id):
		return {}
	var level := get_level(entity_id)
	var current := _derive_realm(level)
	var next_level := MAX_LEVEL
	for realm in _realm_table:
		if int(realm["start_level"]) > level:
			next_level = int(realm["start_level"])
			break
	return {"current_realm": current["realm"], "level_in_realm": level - int(current["start_level"]) + 1, "next_realm_level": next_level, "level_to_next_realm": max(0, next_level - level)}


func reset(entity_id: String, scope: String) -> void:
	if scope == "none" or not _entries.has(entity_id):
		return
	var entry: Dictionary = _entries[entity_id]
	var old_level := int(entry["level"])
	var old_realm := str(entry["realm"])
	_unregister_realm_modifiers(entity_id, old_realm)
	entry["level"] = 1
	entry["realm"] = "fanren"
	entry["current_realm_id"] = 0
	_entries[entity_id] = entry
	_recalculate_attributes(entity_id)
	_emit("level.changed", {"entity_id": entity_id, "old_level": old_level, "new_level": 1, "levels_gained": 1 - old_level})
	_emit("realm.advanced", {"entity_id": entity_id, "old_realm": old_realm, "new_realm": "fanren"})


func snapshot() -> Dictionary:
	return {"version": 1, "entities": _entries.duplicate(true)}


func restore(data: Dictionary) -> void:
	_entries.clear()
	var entities: Dictionary = data.get("entities", {})
	for entity_id in entities.keys():
		var entry: Dictionary = entities[entity_id]
		var derived := _derive_realm(int(entry.get("level", 1)))
		_entries[str(entity_id)] = {"level": int(entry.get("level", 1)), "realm": str(entry.get("realm", derived["realm"])), "current_realm_id": int(entry.get("current_realm_id", derived["id"]))}


func _on_save_loaded(_payload: Dictionary = {}) -> void:
	for entity_id in _entries.keys():
		var entry: Dictionary = _entries[entity_id]
		var derived := _derive_realm(int(entry["level"]))
		if str(entry.get("realm", "")) != str(derived["realm"]):
			push_warning("LevelSystem: restored realm mismatch for %s" % str(entity_id))
			entry["realm"] = str(derived["realm"])
			entry["current_realm_id"] = int(derived["id"])
			_entries[entity_id] = entry
		_swap_realm_modifiers(str(entity_id), str(entry["realm"]), str(entry["realm"]))


func _load_default_realms() -> void:
	_realm_table = [
		{"id": 0, "realm": "fanren", "start_level": 1, "modifier_value": 0.0},
		{"id": 1, "realm": "lianqi", "start_level": 10, "modifier_value": 0.20},
		{"id": 2, "realm": "zhuji", "start_level": 30, "modifier_value": 0.50},
		{"id": 3, "realm": "jindan", "start_level": 60, "modifier_value": 0.80},
		{"id": 4, "realm": "yuanying", "start_level": 100, "modifier_value": 1.20},
		{"id": 5, "realm": "huashen", "start_level": 150, "modifier_value": 1.60},
		{"id": 6, "realm": "heti", "start_level": 200, "modifier_value": 2.00},
	]


func _derive_realm(level: int) -> Dictionary:
	var current: Dictionary = _realm_table[0]
	for realm in _realm_table:
		if level >= int(realm["start_level"]):
			current = realm
	return current


func _swap_realm_modifiers(entity_id: String, old_realm: String, new_realm: String) -> int:
	var removed := 0
	if not old_realm.is_empty():
		removed += _unregister_realm_modifiers(entity_id, old_realm)
	var realm := _realm_by_name(new_realm)
	if realm.is_empty() or str(realm["realm"]) == "fanren":
		return removed
	var source := _realm_source(entity_id, new_realm)
	var value := float(realm["modifier_value"])
	var attr_engine := _attribute_engine()
	if attr_engine != null:
		for attr_id in ATTR_IDS:
			attr_engine.register({"target": "%s.%s" % [entity_id, attr_id], "type": ModifierEngine.MULT, "value": value, "pool": "realm", "source": source})
	var prod_engine := _production_engine()
	if prod_engine != null:
		for target in REALM_PRODUCTION_TARGETS:
			prod_engine.register({"target": target, "type": ModifierEngine.MULT, "value": value, "pool": "realm", "source": source})
	return removed


func _unregister_realm_modifiers(entity_id: String, realm: String) -> int:
	if realm.is_empty():
		return 0
	var source := _realm_source(entity_id, realm)
	var removed := 0
	var attr_engine := _attribute_engine()
	if attr_engine != null:
		removed += attr_engine.unregister_by_source(source)
	var prod_engine := _production_engine()
	if prod_engine != null:
		removed += prod_engine.unregister_by_source(source)
	return removed


func _recalculate_attributes(entity_id: String) -> void:
	if attribute_system == null or not attribute_system.has_entity(entity_id):
		return
	var level := get_level(entity_id)
	var realm_id := get_realm_id(entity_id)
	for attr_id in ATTR_IDS:
		var formula_id := "%s_growth" % attr_id
		var value := FormulaEngine.evaluate(formula_id, {"level": level, "realm_id": realm_id})
		if value < 1.0:
			value = 1.0
		attribute_system.set_base(entity_id, attr_id, BigNumber.from_float(value))


func _realm_by_name(realm_name: String) -> Dictionary:
	for realm in _realm_table:
		if str(realm["realm"]) == realm_name:
			return realm
	push_warning("LevelSystem: unknown realm: %s" % realm_name)
	return {}


func _realm_source(entity_id: String, realm: String) -> String:
	return "level_system.realm.%s.%s" % [entity_id, realm]


func _attribute_engine() -> ModifierEngine:
	if attribute_system == null:
		return null
	return attribute_system.modifier_engine


func _production_engine() -> ModifierEngine:
	if production_system == null:
		return null
	return production_system.modifier_engine


func _subscribe_save_loaded() -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe("save.loaded", _on_save_loaded)


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)


func _register_default_formulas() -> void:
	FormulaEngine.register_formula("level_exp", "10.4 * level + softcap((level - 3) * (level - 3) * (level - 3) * 2.7, 0.0, 1.0)", ["level"])
	FormulaEngine.register_formula("hp_max_growth", "100.0 + (level - 1) * (level - 1) * (1.0 + realm_id * 0.35)", ["level", "realm_id"])
	FormulaEngine.register_formula("atk_growth", "100.0 + level * 8.0 + realm_id * 20.0", ["level", "realm_id"])
	FormulaEngine.register_formula("def_growth", "20.0 + level * 3.0 + realm_id * 10.0", ["level", "realm_id"])
	FormulaEngine.register_formula("spd_growth", "10.0 + level * 0.5 + realm_id * 2.0", ["level", "realm_id"])
	FormulaEngine.register_formula("crit_rate_growth", "clamp(0.05 + level * 0.0015 + realm_id * 0.01, 0.0, 1.0)", ["level", "realm_id"])
	FormulaEngine.register_formula("crit_dmg_growth", "2.0 + level * 0.01 + realm_id * 0.10", ["level", "realm_id"])
