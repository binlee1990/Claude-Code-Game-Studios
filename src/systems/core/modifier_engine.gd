class_name ModifierEngine
extends RefCounted

const ADD := 0
const MULT := 1
const DEFAULT_POOL := "default"

var _modifiers := {}
var _target_cache := {}
var _next_id := 1


## Registers a modifier and returns its generated ID. Invalid data returns an empty string.
func register(data: Dictionary) -> String:
	var missing := []
	for field in ["target", "type", "value"]:
		if not data.has(field):
			missing.append(field)
	if not missing.is_empty():
		push_warning("Modifier missing fields: %s" % str(missing))
		return ""
	var value := float(data["value"])
	if is_nan(value) or is_inf(value):
		push_warning("Invalid modifier value: %s for source '%s'" % [str(value), str(data.get("source", ""))])
		return ""
	var target := str(data["target"]).strip_edges()
	if target.is_empty():
		push_warning("Modifier target cannot be empty")
		return ""
	var modifier_type := int(data["type"])
	var pool := str(data.get("pool", "")).strip_edges()
	if modifier_type == MULT and pool.is_empty():
		push_warning("Empty pool for MULT modifier from '%s', defaulted to 'default'" % str(data.get("source", "")))
		pool = DEFAULT_POOL
	var id := "mod_%d" % _next_id
	_next_id += 1
	_modifiers[id] = {
		"id": id,
		"target": target,
		"type": modifier_type,
		"value": value,
		"pool": pool,
		"source": str(data.get("source", "")),
		"duration": float(data.get("duration", 0.0)),
		"remaining": float(data.get("duration", 0.0)),
	}
	_mark_dirty(target)
	return id


## Unregisters one modifier by ID.
func unregister(id: String) -> bool:
	if not _modifiers.has(id):
		return false
	var target := str(_modifiers[id]["target"])
	_modifiers.erase(id)
	_mark_dirty(target)
	return true


## Unregisters every modifier from a source and returns the removed count.
func unregister_by_source(source: String) -> int:
	var removed := 0
	var ids := _modifiers.keys()
	for id in ids:
		if str(_modifiers[id].get("source", "")) == source:
			unregister(id)
			removed += 1
	return removed


## Advances duration-based modifiers and expires them when remaining time reaches zero.
func update(delta: float) -> void:
	if delta < 0.0:
		delta = 0.0
	var expired := []
	for id in _modifiers.keys():
		var modifier: Dictionary = _modifiers[id]
		if float(modifier.get("duration", 0.0)) <= 0.0:
			continue
		modifier["remaining"] = float(modifier.get("remaining", 0.0)) - delta
		_modifiers[id] = modifier
		if float(modifier["remaining"]) <= 0.0:
			expired.append(id)
	for id in expired:
		var modifier: Dictionary = _modifiers[id]
		unregister(id)
		_emit_modifier_expired(modifier)


## Returns the flat additive sum for a target.
func get_add_sum(target: String) -> float:
	return _get_breakdown_cached(target)["add_sum"]


## Returns one pool multiplier for a target.
func get_pool_multiplier(target: String, pool: String) -> float:
	var pools: Dictionary = _get_breakdown_cached(target)["pools"]
	return float(pools.get(pool, 1.0))


## Returns the final cross-pool multiplier for a target.
func get_multiplier(target: String) -> float:
	return _get_breakdown_cached(target)["final_mult"]


## Applies additive and multiplicative modifiers to a BigNumber base.
func apply(target: String, base: BigNumber) -> BigNumber:
	var add_sum := get_add_sum(target)
	var adjusted := base.copy()
	if add_sum > 0.0:
		adjusted = adjusted.add(BigNumber.from_float(add_sum))
	elif add_sum < 0.0:
		adjusted = adjusted.subtract(BigNumber.from_float(abs(add_sum)))
	return adjusted.multiply_float(get_multiplier(target))


## Returns the additive, pool, and final multiplier breakdown for a target.
func get_breakdown(target: String) -> Dictionary:
	return _get_breakdown_cached(target).duplicate(true)


## Returns all unique targets currently referenced by registered modifiers.
func get_all_targets() -> Array:
	var targets := {}
	for modifier in _modifiers.values():
		targets[modifier["target"]] = true
	return targets.keys()


## Clears all modifiers and cached target values.
func clear_all() -> void:
	_modifiers.clear()
	_target_cache.clear()
	_next_id = 1


func _get_breakdown_cached(target: String) -> Dictionary:
	var cached: Dictionary = _target_cache.get(target, {})
	if cached.get("dirty", true) == false:
		return cached["value"]
	var value := _calculate_breakdown(target)
	_target_cache[target] = {"dirty": false, "value": value}
	return value


func _calculate_breakdown(target: String) -> Dictionary:
	var add_sum := 0.0
	var pool_sums := {}
	for modifier in _modifiers.values():
		if str(modifier["target"]) != target:
			continue
		if int(modifier["type"]) == ADD:
			add_sum += float(modifier["value"])
		elif int(modifier["type"]) == MULT:
			var pool := str(modifier.get("pool", DEFAULT_POOL))
			pool_sums[pool] = float(pool_sums.get(pool, 0.0)) + float(modifier["value"])
	var pools := {}
	var final_mult := 1.0
	for pool in pool_sums.keys():
		var pool_mult := 1.0 + float(pool_sums[pool])
		if pool_mult < 0.0:
			push_warning("Pool '%s' for target '%s' has negative multiplier, clamped to 0.0" % [pool, target])
			pool_mult = 0.0
		pools[pool] = pool_mult
		final_mult *= pool_mult
	if final_mult < 0.0:
		final_mult = 0.0
	return {
		"add_sum": add_sum,
		"pools": pools,
		"final_mult": final_mult,
	}


func _mark_dirty(target: String) -> void:
	if _target_cache.has(target):
		_target_cache[target]["dirty"] = true


func _emit_modifier_expired(modifier: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit("modifier_expired", modifier)
