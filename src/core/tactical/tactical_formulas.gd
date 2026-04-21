class_name TacticalFormulas
extends RefCounted

## Weapon type enum
enum WeaponType {
	SWORD,
	SPEAR,
	AXE,
	BOW,
	MAGIC,
	FIST,
}

## Weapon triangle restraint: attacker → defender → advantage
const WEAPON_ADVANTAGE: Dictionary = {
	WeaponType.SWORD: WeaponType.SPEAR,
	WeaponType.SPEAR: WeaponType.AXE,
	WeaponType.AXE: WeaponType.SWORD,
}

const RESTRAINT_MULTIPLIER: float = 1.5

## Get weapon triangle damage modifier
static func get_triangle_modifier(attacker_weapon: int, defender_weapon: int) -> float:
	if WEAPON_ADVANTAGE.get(attacker_weapon) == defender_weapon:
		return RESTRAINT_MULTIPLIER
	return 1.0

## Check if attacker has weapon advantage
static func has_advantage(attacker_weapon: int, defender_weapon: int) -> bool:
	return WEAPON_ADVANTAGE.get(attacker_weapon) == defender_weapon

## Calculate combined damage multiplier (restraint × crush)
static func get_combined_multiplier(
	attacker_weapon: int,
	defender_weapon: int,
	crush_multiplier: float
) -> float:
	var triangle: float = get_triangle_modifier(attacker_weapon, defender_weapon)
	return triangle * crush_multiplier


## Height advantage constants
const HEIGHT_RANGE_PER_LEVEL: int = 1
const HEIGHT_HIT_PER_LEVEL: float = 0.10

## Get height modifiers: returns { range_modifier: int, hit_modifier: float }
static func get_height_modifiers(attacker_height: int, defender_height: int) -> Dictionary:
	var diff: int = attacker_height - defender_height
	return {
		"range_modifier": diff * HEIGHT_RANGE_PER_LEVEL,
		"hit_modifier": diff * HEIGHT_HIT_PER_LEVEL,
	}

## Calculate effective attack range with height
static func get_effective_range(base_range: int, attacker_height: int, defender_height: int) -> int:
	var mods: Dictionary = get_height_modifiers(attacker_height, defender_height)
	return base_range + mods["range_modifier"]


## Elemental type enum
enum Element {
	NONE,
	FIRE,
	WATER,
	WIND,
	EARTH,
	ELECTRIC,
}

## Elemental interaction results
enum ElementReaction {
	NONE,
	BURN,       # Fire + Grass/Oil
	EVAPORATE,  # Fire + Water
	CONDUCT,    # Electric + Water
	SPREAD,     # Wind + Fire
	MUD,        # Earth + Water
	WET,        # Water on unit
}

## Elemental interactions: { (element, terrain_or_element) → reaction }
const ELEMENT_REACTIONS: Dictionary = {
	# Fire interactions
	[Element.FIRE, TerrainTypes.Terrain.GRASS]: ElementReaction.BURN,
	[Element.FIRE, TerrainTypes.Terrain.WATER_PUDDLE]: ElementReaction.EVAPORATE,
	[Element.FIRE, Element.WATER]: ElementReaction.EVAPORATE,
	# Electric interactions
	[Element.ELECTRIC, Element.WATER]: ElementReaction.CONDUCT,
	[Element.ELECTRIC, TerrainTypes.Terrain.WATER_PUDDLE]: ElementReaction.CONDUCT,
	# Wind interactions
	[Element.WIND, Element.FIRE]: ElementReaction.SPREAD,
	# Earth interactions
	[Element.EARTH, Element.WATER]: ElementReaction.MUD,
	[Element.EARTH, TerrainTypes.Terrain.WATER_PUDDLE]: ElementReaction.MUD,
}

## Check elemental reaction
static func get_element_reaction(element: int, target: int) -> int:
	var key: Array = [element, target]
	if ELEMENT_REACTIONS.has(key):
		return ELEMENT_REACTIONS[key]
	return ElementReaction.NONE
