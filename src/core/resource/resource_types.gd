class_name ResourceTypes
extends RefCounted

## Resource type enum — all stockpilable resources.
## `Resource` is avoided as the enum name because it collides with Godot's
## builtin `Resource` type in external references from tests/scripts.
enum ResourceId {
	GOLD,
	BASIC_MATERIAL,
	FRUIT_STR,
	FRUIT_AGI,
	FRUIT_CON,
	FRUIT_INT,
	FRUIT_CHA,
	FRUIT_LUK,
	FRUIT_WIL,
	FRUIT_RES,
	FRUIT_SOU,
	RARE_MATERIAL,
	PROTECT_SYMBOL,
	BARRIER_RESOURCE,
	ACHIEVEMENT,
}

## Stack limits per resource type
const STACK_LIMITS: Dictionary = {
	ResourceId.GOLD: 9999999,
	ResourceId.BASIC_MATERIAL: 9999,
	ResourceId.FRUIT_STR: 99,
	ResourceId.FRUIT_AGI: 99,
	ResourceId.FRUIT_CON: 99,
	ResourceId.FRUIT_INT: 99,
	ResourceId.FRUIT_CHA: 99,
	ResourceId.FRUIT_LUK: 99,
	ResourceId.FRUIT_WIL: 99,
	ResourceId.FRUIT_RES: 99,
	ResourceId.FRUIT_SOU: 99,
	ResourceId.RARE_MATERIAL: 999,
	ResourceId.PROTECT_SYMBOL: 99,
	ResourceId.BARRIER_RESOURCE: 99,
	ResourceId.ACHIEVEMENT: -1,  # No limit
}

## Fruit resource IDs mapped to attribute types
const FRUIT_ATTR_MAP: Dictionary = {
	ResourceId.FRUIT_STR: AttributeNames.Attribute.STR,
	ResourceId.FRUIT_AGI: AttributeNames.Attribute.AGI,
	ResourceId.FRUIT_CON: AttributeNames.Attribute.CON,
	ResourceId.FRUIT_INT: AttributeNames.Attribute.INT,
	ResourceId.FRUIT_CHA: AttributeNames.Attribute.CHA,
	ResourceId.FRUIT_LUK: AttributeNames.Attribute.LUK,
	ResourceId.FRUIT_WIL: AttributeNames.Attribute.WIL,
	ResourceId.FRUIT_RES: AttributeNames.Attribute.RES,
	ResourceId.FRUIT_SOU: AttributeNames.Attribute.SOU,
}

static func all_resource_ids() -> Array:
	return ResourceId.values()

static func get_resource_name(resource_type: int) -> String:
	var names: PackedStringArray = ResourceId.keys()
	if resource_type < 0 or resource_type >= names.size():
		return "UNKNOWN"
	return names[resource_type]

static func get_stack_limit(resource_type: int) -> int:
	return STACK_LIMITS.get(resource_type, 0)

static func has_limit(resource_type: int) -> bool:
	return STACK_LIMITS.get(resource_type, -1) >= 0

static func is_fruit(resource_type: int) -> bool:
	return FRUIT_ATTR_MAP.has(resource_type)

static func fruit_to_attr(resource_type: int) -> int:
	return FRUIT_ATTR_MAP.get(resource_type, -1)
