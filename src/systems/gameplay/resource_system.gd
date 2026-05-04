class_name ResourceSystem
extends RefCounted

const RESET_RANK := {
	"none": 0,
	"breakthrough": 1,
	"ascension": 2,
	"rebirth": 3,
}

var _resources := {}


## Registers one resource definition. Duplicate IDs are rejected.
func register(definition: Dictionary) -> bool:
	var id := str(definition.get("id", "")).strip_edges()
	if id.is_empty():
		push_warning("Resource id cannot be empty")
		return false
	if _resources.has(id):
		push_warning("Duplicate resource id: %s" % id)
		return false
	var cap := _to_big_number(definition.get("cap", BigNumber.MAX))
	_resources[id] = {
		"id": id,
		"current": BigNumber.zero(),
		"cap": cap,
		"has_cap": bool(definition.get("has_cap", false)),
		"category": str(definition.get("category", "currency")),
		"reset_scope": str(definition.get("reset_scope", "none")),
		"metadata": definition.get("metadata", {}),
	}
	return true


## Adds an amount and returns the actual amount accepted after cap clamping.
func add(resource_id: String, amount: BigNumber) -> BigNumber:
	if amount == null or amount.is_zero():
		return BigNumber.zero()
	if not _resources.has(resource_id):
		push_warning("Resource not found: %s" % resource_id)
		return BigNumber.zero()
	var entry: Dictionary = _resources[resource_id]
	var old_value: BigNumber = entry["current"]
	var desired := old_value.add(amount)
	var new_value := desired
	if bool(entry["has_cap"]) and desired.greater_than(entry["cap"]):
		new_value = entry["cap"].copy()
	var actual_added := new_value.subtract(old_value)
	entry["current"] = new_value
	_resources[resource_id] = entry
	if not actual_added.is_zero():
		_emit_resource_event("resource.%s.changed" % resource_id, {
			"resource_id": resource_id,
			"old_value": old_value,
			"new_value": new_value,
			"delta": actual_added,
		})
	var lost := amount.subtract(actual_added)
	if bool(entry["has_cap"]) and not lost.is_zero():
		_emit_resource_event("resource.%s.overflow" % resource_id, {
			"resource_id": resource_id,
			"attempted": amount,
			"actual_added": actual_added,
			"lost": lost,
		})
	return actual_added


## Spends an amount atomically for one resource.
func spend(resource_id: String, amount: BigNumber) -> bool:
	if amount == null or amount.is_zero():
		return true
	if not _resources.has(resource_id):
		push_warning("Resource not found: %s" % resource_id)
		return false
	var entry: Dictionary = _resources[resource_id]
	var old_value: BigNumber = entry["current"]
	if old_value.less_than(amount):
		return false
	var new_value := old_value.subtract(amount)
	entry["current"] = new_value
	_resources[resource_id] = entry
	if not amount.is_zero():
		_emit_resource_event("resource.%s.changed" % resource_id, {
			"resource_id": resource_id,
			"old_value": old_value,
			"new_value": new_value,
			"delta": amount,
		})
	return true


## Sets a resource value, clamped to cap when enabled.
func set_value(resource_id: String, value: BigNumber) -> void:
	if not _resources.has(resource_id):
		push_warning("Resource not found: %s" % resource_id)
		return
	var entry: Dictionary = _resources[resource_id]
	var old_value: BigNumber = entry["current"]
	var new_value := value.copy()
	if bool(entry["has_cap"]) and new_value.greater_than(entry["cap"]):
		new_value = entry["cap"].copy()
	if old_value.equals(new_value):
		return
	entry["current"] = new_value
	_resources[resource_id] = entry
	_emit_resource_event("resource.%s.changed" % resource_id, {
		"resource_id": resource_id,
		"old_value": old_value,
		"new_value": new_value,
		"delta": new_value.subtract(old_value) if new_value.greater_or_equal(old_value) else old_value.subtract(new_value),
	})


## Returns the current resource value or ZERO when missing.
func get_value(resource_id: String) -> BigNumber:
	if not _resources.has(resource_id):
		return BigNumber.zero()
	return _resources[resource_id]["current"].copy()


## Returns the resource cap or MAX for uncapped resources.
func get_max(resource_id: String) -> BigNumber:
	if not _resources.has(resource_id):
		return BigNumber.zero()
	var entry: Dictionary = _resources[resource_id]
	if not bool(entry["has_cap"]):
		return BigNumber.max_value()
	return entry["cap"].copy()


## Sets a resource cap and clamps current value down if needed.
func set_max(resource_id: String, new_cap: BigNumber) -> void:
	if new_cap == null or new_cap.is_zero():
		push_warning("Resource cap cannot be zero: %s" % resource_id)
		return
	if not _resources.has(resource_id):
		push_warning("Resource not found: %s" % resource_id)
		return
	var entry: Dictionary = _resources[resource_id]
	var old_cap: BigNumber = entry["cap"]
	if old_cap.equals(new_cap):
		return
	var old_value: BigNumber = entry["current"]
	entry["cap"] = new_cap.copy()
	entry["has_cap"] = true
	_resources[resource_id] = entry
	_emit_resource_event("resource.%s.cap_changed" % resource_id, {
		"resource_id": resource_id,
		"old_cap": old_cap,
		"new_cap": new_cap,
	})
	if old_value.greater_than(new_cap):
		entry["current"] = new_cap.copy()
		_resources[resource_id] = entry
		var lost := old_value.subtract(new_cap)
		_emit_resource_event("resource.%s.changed" % resource_id, {
			"resource_id": resource_id,
			"old_value": old_value,
			"new_value": new_cap,
			"delta": lost,
		})
		_emit_resource_event("resource.%s.overflow" % resource_id, {
			"resource_id": resource_id,
			"attempted": old_value,
			"actual_added": new_cap,
			"lost": lost,
		})


## Returns whether the resource has at least the amount.
func can_afford(resource_id: String, amount: BigNumber) -> bool:
	return get_value(resource_id).greater_or_equal(amount)


## Returns true when the resource is registered.
func has_resource(resource_id: String) -> bool:
	return _resources.has(resource_id)


## Returns all registered resource IDs.
func get_all_ids() -> Array:
	return _resources.keys()


## Returns definition metadata without mutable values.
func get_definition(resource_id: String) -> Dictionary:
	if not _resources.has(resource_id):
		return {}
	var entry: Dictionary = _resources[resource_id]
	return {
		"category": entry["category"],
		"reset_scope": entry["reset_scope"],
		"has_cap": entry["has_cap"],
		"metadata": entry["metadata"],
	}


## Adds multiple resources sequentially and returns actual additions by ID.
func batch_add(changes: Dictionary) -> Dictionary:
	var result := {}
	for id in changes.keys():
		result[id] = add(str(id), _to_big_number(changes[id]))
	return result


## Resets resources whose reset scope is included by the requested scope.
func reset_by_scope(scope: String) -> int:
	if not RESET_RANK.has(scope):
		push_warning("Invalid reset scope: %s" % scope)
		return 0
	var rank := int(RESET_RANK[scope])
	if rank == 0:
		return 0
	var count := 0
	for id in _resources.keys():
		var resource_rank := int(RESET_RANK.get(_resources[id]["reset_scope"], 0))
		if resource_rank > 0 and resource_rank <= rank:
			count += 1
			set_value(id, BigNumber.zero())
	return count


## Returns a save snapshot with BigNumber dictionaries.
func snapshot() -> Dictionary:
	var resources := {}
	for id in _resources.keys():
		var entry: Dictionary = _resources[id]
		resources[id] = {
			"current": entry["current"].to_dict(),
			"cap": entry["cap"].to_dict(),
		}
	return {"version": 1, "resources": resources}


## Restores current and cap values from a snapshot.
func restore(data: Dictionary) -> void:
	var resources: Dictionary = data.get("resources", {})
	for id in resources.keys():
		if not _resources.has(id):
			push_warning("Skipping unknown resource in restore: %s" % str(id))
			continue
		var item: Dictionary = resources[id]
		set_max(str(id), BigNumber.from_dict(item.get("cap", {})))
		set_value(str(id), BigNumber.from_dict(item.get("current", {})))


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


func _emit_resource_event(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)

