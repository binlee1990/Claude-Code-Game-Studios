class_name TerrainTypes
extends RefCounted

## Terrain type enum
enum Terrain {
	NORMAL,
	GRASS,
	WATER_PUDDLE,
	SAND,
	MUD,
	HIGHLAND,
	OBSTACLE,
}

## Height levels
const HEIGHT_LOW: int = 0
const HEIGHT_PLAIN: int = 1
const HEIGHT_HIGH: int = 2

## Terrain properties: { height, movement_cost, blocks_movement, blocks_los, is_ignitable, agi_modifier }
const TERRAIN_PROPS: Dictionary = {
	Terrain.NORMAL:       {"height": HEIGHT_PLAIN, "movement_cost": 1.0, "blocks": false, "blocks_los": false, "ignitable": false, "agi_mod": 1.0},
	Terrain.GRASS:        {"height": HEIGHT_PLAIN, "movement_cost": 1.0, "blocks": false, "blocks_los": false, "ignitable": true,  "agi_mod": 1.0},
	Terrain.WATER_PUDDLE: {"height": HEIGHT_LOW,   "movement_cost": 1.5, "blocks": false, "blocks_los": false, "ignitable": false, "agi_mod": 1.0},
	Terrain.SAND:         {"height": HEIGHT_PLAIN, "movement_cost": 2.0, "blocks": false, "blocks_los": false, "ignitable": false, "agi_mod": 1.0},
	Terrain.MUD:          {"height": HEIGHT_LOW,   "movement_cost": 2.0, "blocks": false, "blocks_los": false, "ignitable": false, "agi_mod": 0.5},
	Terrain.HIGHLAND:     {"height": HEIGHT_HIGH,  "movement_cost": 1.0, "blocks": false, "blocks_los": false, "ignitable": false, "agi_mod": 1.0},
	Terrain.OBSTACLE:     {"height": HEIGHT_PLAIN, "movement_cost": 0.0, "blocks": true,  "blocks_los": true,  "ignitable": false, "agi_mod": 1.0},
}

static func get_height(terrain: int) -> int:
	return TERRAIN_PROPS[terrain]["height"]

static func get_movement_cost(terrain: int) -> float:
	return TERRAIN_PROPS[terrain]["movement_cost"]

static func blocks_movement(terrain: int) -> bool:
	return TERRAIN_PROPS[terrain]["blocks"]

static func blocks_line_of_sight(terrain: int) -> bool:
	return TERRAIN_PROPS[terrain]["blocks_los"]

static func get_agi_modifier(terrain: int) -> float:
	return TERRAIN_PROPS[terrain]["agi_mod"]

static func is_ignitable(terrain: int) -> bool:
	return TERRAIN_PROPS[terrain]["ignitable"]
