# tests/unit/tactical/terrain_data_model_test.gd
# Story 001: Terrain Data Model
# Validates AC.4.1-4.3

extends Gut

# Height values

func test_normal_height_is_plain() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.NORMAL), TerrainTypes.HEIGHT_PLAIN)

func test_grass_height_is_plain() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.GRASS), TerrainTypes.HEIGHT_PLAIN)

func test_highland_height_is_2() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.HIGHLAND), TerrainTypes.HEIGHT_HIGH)

func test_water_puddle_height_is_low() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.WATER_PUDDLE), TerrainTypes.HEIGHT_LOW)

func test_sand_height_is_plain() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.SAND), TerrainTypes.HEIGHT_PLAIN)

func test_mud_height_is_low() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.MUD), TerrainTypes.HEIGHT_LOW)


# AC.4.1: Sand movement cost +100%

func test_sand_movement_cost_doubled() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.SAND), 2.0)

func test_normal_movement_cost() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.NORMAL), 1.0)

func test_highland_movement_cost_normal() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.HIGHLAND), 1.0)

func test_water_puddle_movement_cost() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.WATER_PUDDLE), 1.5)

func test_mud_movement_cost() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.MUD), 2.0)


# AC.4.2: Obstacles block movement and LOS

func test_obstacle_blocks_movement() -> void:
	assert_true(TerrainTypes.blocks_movement(TerrainTypes.Terrain.OBSTACLE))

func test_obstacle_blocks_line_of_sight() -> void:
	assert_true(TerrainTypes.blocks_line_of_sight(TerrainTypes.Terrain.OBSTACLE))

func test_normal_does_not_block() -> void:
	assert_false(TerrainTypes.blocks_movement(TerrainTypes.Terrain.NORMAL))
	assert_false(TerrainTypes.blocks_line_of_sight(TerrainTypes.Terrain.NORMAL))

func test_highland_does_not_block() -> void:
	assert_false(TerrainTypes.blocks_movement(TerrainTypes.Terrain.HIGHLAND))
	assert_false(TerrainTypes.blocks_line_of_sight(TerrainTypes.Terrain.HIGHLAND))


# AC.4.3: Highland height = 2

func test_highland_provides_height_2() -> void:
	assert_eq(TerrainTypes.get_height(TerrainTypes.Terrain.HIGHLAND), 2)


# Terrain modifiers

func test_mud_agi_modifier_halved() -> void:
	assert_eq(TerrainTypes.get_agi_modifier(TerrainTypes.Terrain.MUD), 0.5)

func test_normal_agi_modifier() -> void:
	assert_eq(TerrainTypes.get_agi_modifier(TerrainTypes.Terrain.NORMAL), 1.0)

func test_grass_is_ignitable() -> void:
	assert_true(TerrainTypes.is_ignitable(TerrainTypes.Terrain.GRASS))

func test_normal_not_ignitable() -> void:
	assert_false(TerrainTypes.is_ignitable(TerrainTypes.Terrain.NORMAL))

func test_obstacle_zero_movement_cost() -> void:
	assert_eq(TerrainTypes.get_movement_cost(TerrainTypes.Terrain.OBSTACLE), 0.0)
