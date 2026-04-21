class_name Inventory
extends Node

## Manages all囤积 (stockpilable) resources for the player.

signal resource_changed(resource_type: int, old_amount: int, new_amount: int)
signal resource_overflow(resource_type: int, discarded: int)

var _resources: Dictionary = {}

func _ready() -> void:
	# Initialize all resources to 0
	for res in ResourceTypes.Resource.values():
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

## Serialize inventory data
func serialize() -> Dictionary:
	return _resources.duplicate()

## Load from serialized data
func deserialize(data: Dictionary) -> void:
	for key in data:
		_resources[int(key)] = data[key]
