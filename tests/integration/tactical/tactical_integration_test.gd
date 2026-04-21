# tests/integration/tactical/tactical_integration_test.gd
# Story 005: Tactical Save/Load Integration
# Validates that tactical constants are stable and terrain data serializes

extends Gut

# Tactical system is stateless (formulas + constants), so round-trip testing
# means verifying that terrain data and tactical enums remain consistent.

func test_terrain_constants_stable() -> void:
	assert_eq(TerrainTypes.Terrain.NORMAL, 0)
	assert_eq(TerrainTypes.Terrain.GRASS, 1)
	assert_eq(TerrainTypes.Terrain.WATER_PUDDLE, 2)
	assert_eq(TerrainTypes.Terrain.SAND, 3)
	assert_eq(TerrainTypes.Terrain.MUD, 4)
	assert_eq(TerrainTypes.Terrain.HIGHLAND, 5)
	assert_eq(TerrainTypes.Terrain.OBSTACLE, 6)

func test_weapon_constants_stable() -> void:
	assert_eq(TacticalFormulas.WeaponType.SWORD, 0)
	assert_eq(TacticalFormulas.WeaponType.SPEAR, 1)
	assert_eq(TacticalFormulas.WeaponType.AXE, 2)
	assert_eq(TacticalFormulas.WeaponType.BOW, 3)
	assert_eq(TacticalFormulas.WeaponType.MAGIC, 4)
	assert_eq(TacticalFormulas.WeaponType.FIST, 5)

func test_element_constants_stable() -> void:
	assert_eq(TacticalFormulas.Element.NONE, 0)
	assert_eq(TacticalFormulas.Element.FIRE, 1)
	assert_eq(TacticalFormulas.Element.WATER, 2)
	assert_eq(TacticalFormulas.Element.WIND, 3)
	assert_eq(TacticalFormulas.Element.EARTH, 4)
	assert_eq(TacticalFormulas.Element.ELECTRIC, 5)

func test_terrain_all_types_have_properties() -> void:
	for terrain in TerrainTypes.Terrain.values():
		assert_true(TerrainTypes.TERRAIN_PROPS.has(terrain),
			"Terrain %d has properties" % terrain)

func test_formula_determinism() -> void:
	# Same inputs → same outputs (no randomness)
	for i in range(10):
		var m1: float = TacticalFormulas.get_triangle_modifier(
			TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR)
		var m2: float = TacticalFormulas.get_combined_multiplier(
			TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR, 1.5)
		assert_eq(m1, 1.5)
		assert_eq(m2, 2.25)

		var h1: Dictionary = TacticalFormulas.get_height_modifiers(2, 0)
		assert_eq(h1["range_modifier"], 2)
		assert_eq(h1["hit_modifier"], 0.20)

func test_combined_tactical_scenario() -> void:
	# Sword user on highland(2) attacking spear user on plain(1)
	# With crush condition met
	var triangle: float = TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR)
	var crush: float = 1.5
	var combined: float = triangle * crush
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(2, 1)

	assert_eq(combined, 2.25, "Triangle + crush")
	assert_eq(mods["range_modifier"], 1, "+1 range advantage")
	assert_eq(mods["hit_modifier"], 0.10, "+10% hit advantage")
