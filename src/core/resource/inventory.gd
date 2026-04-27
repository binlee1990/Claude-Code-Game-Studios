extends Node

## Manages all囤积 (stockpilable) resources for the player.

signal resource_changed(resource_type: int, old_amount: int, new_amount: int)
signal resource_overflow(resource_type: int, discarded: int)

var _resources: Dictionary = {}

func _ready() -> void:
	reset()

## Reset all tracked resources to zero.
func reset() -> void:
	_resources.clear()
	for res in ResourceTypes.all_resource_ids():
		_resources[res] = 0

## Get current amount of a resource
func get_amount(resource_type: int) -> int:
	return _resources.get(resource_type, 0)

## Add resources, respecting stack limits. Returns actual amount added.
func add_resource(resource_type: int, amount: int) -> int:
	if amount <= 0:
		return 0
	var current: int = get_amount(resource_type)
	var limit: int = ResourceTypes.get_stack_limit(resource_type)
	var new_amount: int
	var discarded: int = 0

	if limit < 0:
		# No limit (achievement points)
		new_amount = current + amount
	else:
		new_amount = mini(current + amount, limit)
		discarded = (current + amount) - new_amount

	var old: int = current
	_resources[resource_type] = new_amount
	resource_changed.emit(resource_type, old, new_amount)
	if discarded > 0:
		resource_overflow.emit(resource_type, discarded)
	return new_amount - old

## Remove resources. Returns false if insufficient.
func remove_resource(resource_type: int, amount: int) -> bool:
	if amount <= 0:
		return true
	var current: int = get_amount(resource_type)
	if current < amount:
		return false
	var old: int = current
	_resources[resource_type] = current - amount
	resource_changed.emit(resource_type, old, current - amount)
	return true

## Check if has enough of a resource
func has_resource(resource_type: int, amount: int) -> bool:
	return get_amount(resource_type) >= amount

## Preview the resource cost for an enhancement attempt at current_level.
func peek_cost(current_level: int, base_cost: int = 100) -> Dictionary:
	return ResourceFormulas.calculate_enhancement_cost(base_cost, current_level)

func can_pay_cost(cost: Dictionary) -> bool:
	return get_cost_shortage(cost).is_empty()

func get_cost_shortage(cost: Dictionary) -> Dictionary:
	var shortage := {}
	var required_gold := int(cost.get("gold", 0))
	var required_materials := int(cost.get("materials", 0))
	if required_gold > get_amount(ResourceTypes.ResourceId.GOLD):
		shortage["gold"] = required_gold - get_amount(ResourceTypes.ResourceId.GOLD)
	if required_materials > get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL):
		shortage["materials"] = required_materials - get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	return shortage

## Serialize inventory data
func serialize() -> Dictionary:
	return _resources.duplicate()

## Load from serialized data
func deserialize(data: Dictionary) -> void:
	reset()
	for key in data:
		_resources[int(key)] = data[key]
