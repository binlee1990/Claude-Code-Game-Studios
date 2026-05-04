class_name StorageLimitSystem
extends RefCounted

const WARNING_THRESHOLD := 0.85

var resource_system: ResourceSystem
var base_caps := {"lingqi": BigNumber.from_int(1000), "herb": BigNumber.from_int(500)}
var realm_cap_multiplier := 1.0


func _init(resources: ResourceSystem = null) -> void:
	resource_system = resources


func initialize() -> void:
	recompute_all()


func set_realm_cap_multiplier(multiplier: float) -> void:
	if multiplier <= 0.0 or is_nan(multiplier) or is_inf(multiplier):
		push_warning("StorageLimitSystem: invalid realm cap multiplier")
		return
	realm_cap_multiplier = multiplier
	recompute_all()


func recompute_all() -> void:
	if resource_system == null:
		return
	for resource_id in base_caps.keys():
		if not resource_system.has_resource(str(resource_id)):
			push_warning("StorageLimitSystem: resource not found: %s" % str(resource_id))
			continue
		var cap: BigNumber = base_caps[resource_id].multiply_float(realm_cap_multiplier)
		resource_system.set_max(str(resource_id), cap)


func get_capacity_state(resource_id: String) -> Dictionary:
	if resource_system == null or not resource_system.has_resource(resource_id):
		return {"state": "uncapped", "fill_ratio": 0.0, "current": BigNumber.zero(), "cap": BigNumber.max_value()}
	var definition := resource_system.get_definition(resource_id)
	if not bool(definition.get("has_cap", false)):
		return {"state": "uncapped", "fill_ratio": 0.0, "current": resource_system.get_value(resource_id), "cap": resource_system.get_max(resource_id)}
	var current := resource_system.get_value(resource_id)
	var cap := resource_system.get_max(resource_id)
	var fill_ratio := 0.0
	if not cap.is_zero():
		fill_ratio = clamp(current.to_float() / cap.to_float(), 0.0, 1.0)
	var state := "safe"
	if fill_ratio >= 1.0:
		state = "full"
	elif fill_ratio >= WARNING_THRESHOLD:
		state = "warning"
	return {"state": state, "fill_ratio": fill_ratio, "current": current, "cap": cap}


func get_remaining_capacity(resource_id: String) -> BigNumber:
	var state := get_capacity_state(resource_id)
	if str(state["state"]) == "uncapped":
		return BigNumber.max_value()
	var current: BigNumber = state["current"]
	var cap: BigNumber = state["cap"]
	return cap.subtract(current)
