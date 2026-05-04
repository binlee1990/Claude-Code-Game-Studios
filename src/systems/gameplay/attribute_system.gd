class_name AttributeSystem
extends RefCounted

const DEFAULT_SCHEMAS := {
	"player_set": ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"],
	"enemy_basic_set": ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"],
}

var modifier_engine: ModifierEngine
var suppress_restore_events := false
var _attributes := {}
var _meta := {}
var _target_cache := {}


func _init(engine: ModifierEngine = null) -> void:
	modifier_engine = engine if engine != null else ModifierEngine.new()


## Registers an entity and initializes all schema attributes.
func register_entity(entity_id: String, definition: Dictionary) -> bool:
	if entity_id.strip_edges().is_empty():
		push_warning("Entity id cannot be empty")
		return false
	if _meta.has(entity_id):
		push_warning("Duplicate entity id: %s" % entity_id)
		return false
	if not definition.has("category") or not definition.has("attribute_set"):
		push_warning("Entity definition missing category or attribute_set")
		return false
	var attribute_set := str(definition["attribute_set"])
	if not DEFAULT_SCHEMAS.has(attribute_set):
		push_warning("Unknown attribute set: %s" % attribute_set)
		return false
	_meta[entity_id] = {
		"category": str(definition["category"]),
		"attribute_set": attribute_set,
		"registered_at": Time.get_unix_time_from_system(),
	}
	var values := {}
	var initial: Dictionary = definition.get("attributes", {})
	for attr_id in DEFAULT_SCHEMAS[attribute_set]:
		values[attr_id] = _to_big_number(initial.get(attr_id, BigNumber.zero()))
		_target_cache["%s|%s" % [entity_id, attr_id]] = StringName("%s.%s" % [entity_id, attr_id])
	_attributes[entity_id] = values
	return true


## Unregisters an entity and returns removed attribute count.
func unregister_entity(entity_id: String) -> int:
	if not _meta.has(entity_id):
		return 0
	var count := int(_attributes.get(entity_id, {}).size())
	_meta.erase(entity_id)
	_attributes.erase(entity_id)
	_emit_attribute_event("attribute.%s.unregistered" % entity_id, {"entity_id": entity_id})
	return count


## Returns true when an entity is registered.
func has_entity(entity_id: String) -> bool:
	return _meta.has(entity_id)


## Returns all registered entity IDs.
func get_all_entity_ids() -> Array:
	return _meta.keys()


## Sets one base attribute value.
func set_base(entity_id: String, attr_id: String, value: BigNumber) -> void:
	if not _attributes.has(entity_id):
		push_warning("Entity not found: %s" % entity_id)
		return
	if not _attributes[entity_id].has(attr_id):
		push_warning("Attribute not in schema: %s/%s" % [entity_id, attr_id])
		return
	var old_value: BigNumber = _attributes[entity_id][attr_id]
	var new_value := value.copy()
	if old_value.equals(new_value):
		return
	_attributes[entity_id][attr_id] = new_value
	_emit_attribute_event("attribute.%s.%s.base_changed" % [entity_id, attr_id], {
		"entity_id": entity_id,
		"attr_id": attr_id,
		"old_value": old_value,
		"new_value": new_value,
		"delta": new_value.subtract(old_value) if new_value.greater_or_equal(old_value) else old_value.subtract(new_value),
	})


## Returns one base attribute value, or ZERO when missing.
func get_base(entity_id: String, attr_id: String) -> BigNumber:
	if not _attributes.has(entity_id) or not _attributes[entity_id].has(attr_id):
		return BigNumber.zero()
	return _attributes[entity_id][attr_id].copy()


## Returns one final attribute value after ModifierEngine integration.
func get_final(entity_id: String, attr_id: String) -> BigNumber:
	if not has_attribute(entity_id, attr_id):
		return BigNumber.zero()
	return modifier_engine.apply(str(make_target(entity_id, attr_id)), get_base(entity_id, attr_id))


## Returns true when an entity owns an attribute.
func has_attribute(entity_id: String, attr_id: String) -> bool:
	return _attributes.has(entity_id) and _attributes[entity_id].has(attr_id)


## Sets multiple base attributes sequentially.
func set_base_batch(entity_id: String, changes: Dictionary) -> void:
	for attr_id in changes.keys():
		set_base(entity_id, str(attr_id), _to_big_number(changes[attr_id]))


## Returns a copy of base attributes for one entity.
func get_attribute_set(entity_id: String) -> Dictionary:
	if not _attributes.has(entity_id):
		return {}
	var result := {}
	for attr_id in _attributes[entity_id].keys():
		result[attr_id] = _attributes[entity_id][attr_id].copy()
	return result


## Returns a copy of final attributes for one entity.
func get_final_set(entity_id: String) -> Dictionary:
	if not _attributes.has(entity_id):
		return {}
	var result := {}
	for attr_id in _attributes[entity_id].keys():
		result[attr_id] = get_final(entity_id, attr_id)
	return result


## Returns the canonical ModifierEngine target for an entity attribute.
func make_target(entity_id: String, attr_id: String) -> StringName:
	if entity_id.strip_edges().is_empty() or attr_id.strip_edges().is_empty():
		push_warning("Cannot make empty attribute target")
		return StringName("")
	var key := "%s|%s" % [entity_id, attr_id]
	if not _target_cache.has(key):
		_target_cache[key] = StringName("%s.%s" % [entity_id, attr_id])
	return _target_cache[key]


## Returns a save snapshot with BigNumber dictionaries.
func snapshot() -> Dictionary:
	var entities := {}
	for entity_id in _attributes.keys():
		var attrs := {}
		for attr_id in _attributes[entity_id].keys():
			attrs[attr_id] = _attributes[entity_id][attr_id].to_dict()
		entities[entity_id] = {
			"meta": _meta[entity_id].duplicate(),
			"attributes": attrs,
		}
	return {"version": 1, "entities": entities}


## Restores entities and base attributes from a snapshot.
func restore(data: Dictionary) -> void:
	var previous_suppress := suppress_restore_events
	suppress_restore_events = true
	_attributes.clear()
	_meta.clear()
	var entities: Dictionary = data.get("entities", {})
	for entity_id in entities.keys():
		var item: Dictionary = entities[entity_id]
		if register_entity(str(entity_id), item.get("meta", {})):
			var attrs: Dictionary = item.get("attributes", {})
			for attr_id in attrs.keys():
				set_base(str(entity_id), str(attr_id), BigNumber.from_dict(attrs[attr_id]))
	suppress_restore_events = previous_suppress


func _to_big_number(value: Variant) -> BigNumber:
	if value is BigNumber:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		return BigNumber.from_dict(value)
	if typeof(value) == TYPE_STRING:
		return BigNumber.from_string(value)
	if typeof(value) == TYPE_INT:
		return BigNumber.from_int(value)
	if typeof(value) == TYPE_FLOAT:
		return BigNumber.from_float(value)
	return BigNumber.zero()


func _emit_attribute_event(event_name: String, payload: Dictionary) -> void:
	if suppress_restore_events:
		return
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
