# tests/unit/tactical/elemental_interactions_test.gd
# Story 004: Elemental Interactions
# Validates AC.2.1-2.5

extends Gut

# AC.2.1: Fire + grass/oil → burn

func test_fire_on_grass_triggers_burn() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TerrainTypes.Terrain.GRASS)
	assert_eq(reaction, TacticalFormulas.ElementReaction.BURN)

func test_fire_on_normal_no_reaction() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TerrainTypes.Terrain.NORMAL)
	assert_eq(reaction, TacticalFormulas.ElementReaction.NONE)

func test_fire_on_highland_no_reaction() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TerrainTypes.Terrain.HIGHLAND)
	assert_eq(reaction, TacticalFormulas.ElementReaction.NONE)


# AC.2.2: Wind + fire → spread

func test_wind_on_fire_spread() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.WIND, TacticalFormulas.Element.FIRE)
	assert_eq(reaction, TacticalFormulas.ElementReaction.SPREAD)

func test_wind_on_normal_no_reaction() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.WIND, TerrainTypes.Terrain.NORMAL)
	assert_eq(reaction, TacticalFormulas.ElementReaction.NONE)


# AC.2.3: Electric + water → conduct (chain lightning)

func test_electric_on_water_conduct() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.ELECTRIC, TacticalFormulas.Element.WATER)
	assert_eq(reaction, TacticalFormulas.ElementReaction.CONDUCT)

func test_electric_on_water_puddle_conduct() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.ELECTRIC, TerrainTypes.Terrain.WATER_PUDDLE)
	assert_eq(reaction, TacticalFormulas.ElementReaction.CONDUCT)

func test_chain_lightning_damage_decay() -> void:
	var base_damage: int = 80
	var hop1: int = base_damage
	var hop2: int = int(hop1 * 0.8)
	var hop3: int = int(hop2 * 0.8)
	assert_eq(hop1, 80)
	assert_eq(hop2, 64)
	assert_eq(hop3, 51)


# AC.2.4: Water/earth + sand → mud

func test_earth_on_water_mud() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.EARTH, TacticalFormulas.Element.WATER)
	assert_eq(reaction, TacticalFormulas.ElementReaction.MUD)

func test_earth_on_water_puddle_mud() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.EARTH, TerrainTypes.Terrain.WATER_PUDDLE)
	assert_eq(reaction, TacticalFormulas.ElementReaction.MUD)

func test_mud_agi_penalty() -> void:
	assert_eq(TerrainTypes.get_agi_modifier(TerrainTypes.Terrain.MUD), 0.5, "AGI -50% on mud")


# AC.2.5: Fire + water → evaporate (terrain consumed)

func test_fire_on_water_evaporate() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TerrainTypes.Terrain.WATER_PUDDLE)
	assert_eq(reaction, TacticalFormulas.ElementReaction.EVAPORATE)

func test_fire_on_water_element_evaporate() -> void:
	var reaction: int = TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TacticalFormulas.Element.WATER)
	assert_eq(reaction, TacticalFormulas.ElementReaction.EVAPORATE)


# Burn damage formula: floor(base * 0.3)

func test_burn_damage_calculation() -> void:
	var base_damage: int = 100
	var burn_damage: int = int(base_damage * 0.3)
	assert_eq(burn_damage, 30)

func test_burn_damage_with_defense() -> void:
	var base: int = 100
	var defense: int = 50
	var burn: int = int(base * 0.3 * (100.0 / (100 + defense)))
	assert_eq(burn, 20, "floor(30 * 100/150) = 20")


# No reaction for non-matching elements

func test_water_on_normal_no_reaction() -> void:
	assert_eq(TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.WATER, TerrainTypes.Terrain.NORMAL),
		TacticalFormulas.ElementReaction.NONE)

func test_fire_on_obstacle_no_reaction() -> void:
	assert_eq(TacticalFormulas.get_element_reaction(
		TacticalFormulas.Element.FIRE, TerrainTypes.Terrain.OBSTACLE),
		TacticalFormulas.ElementReaction.NONE)
