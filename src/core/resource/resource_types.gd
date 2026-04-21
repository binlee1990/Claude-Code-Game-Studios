class_name ResourceTypes
extends RefCounted

## Resource type enum — all囤积 (stockpilable) resources
enum Resource {
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
	Resource.GOLD: 9999999,
	Resource.BASIC_MATERIAL: 9999,
	Resource.FRUIT_STR: 99,
	Resource.FRUIT_AGI: 99,
	Resource.FRUIT_CON: 99,
	Resource.FRUIT_INT: 99,
	Resource.FRUIT_CHA: 99,
	Resource.FRUIT_LUK: 99,
	Resource.FRUIT_WIL: 99,
	Resource.FRUIT_RES: 99,
	Resource.FRUIT_SOU: 99,
	Resource.RARE_MATERIAL: 999,
	Resource.PROTECT_SYMBOL: 99,
	Resource.BARRIER_RESOURCE: 99,
	Resource.ACHIEVEMENT: -1,  # No limit
}

## Fruit resource IDs mapped to attribute types
const FRUIT_ATTR_MAP: Dictionary = {
	Resource.FRUIT_STR: AttributeNames.Attribute.STR,
	Resource.FRUIT_AGI: AttributeNames.Attribute.AGI,
	Resource.FRUIT_CON: AttributeNames.Attribute.CON,
	Resource.FRUIT_INT: AttributeNames.Attribute.INT,
	Resource.FRUIT_CHA: AttributeNames.Attribute.CHA,
	Resource.FRUIT_LUK: AttributeNames.Attribute.LUK,
	Resource.FRUIT_WIL: AttributeNames.Attribute.WIL,
	Resource.FRUIT_RES: AttributeNames.Attribute.RES,
	Resource.FRUIT_SOU: AttributeNames.Attribute.SOU,
}

static func get_stack_limit(resource_type: int) -> int:
	return STACK_LIMITS.get(resource_type, 0)

static func has_limit(resource_type: int) -> bool:
	return STACK_LIMITS.get(resource_type, -1) >= 0

static func is_fruit(resource_type: int) -> bool:
	return FRUIT_ATTR_MAP.has(resource_type)

static func fruit_to_attr(resource_type: int) -> int:
	return FRUIT_ATTR_MAP.get(resource_type, -1)
