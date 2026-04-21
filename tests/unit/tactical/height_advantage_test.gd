# tests/unit/tactical/height_advantage_test.gd
# Story 003: Height Advantage
# Validates AC.3.1-3.4

extends Gut

# AC.3.1: High attacks low → range +1, hit +10% per level

func test_high_attacks_low_range_bonus() -> void:
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(2, 0)
	assert_eq(mods["range_modifier"], 2, "+2 range for 2 level diff")
	assert_eq(mods["hit_modifier"], 0.20, "+20% hit for 2 level diff")

func test_high_attacks_low_effective_range() -> void:
	var effective: int = TacticalFormulas.get_effective_range(3, 2, 0)
	assert_eq(effective, 5, "base 3 + 2 height = 5")

func test_one_level_above() -> void:
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(2, 1)
	assert_eq(mods["range_modifier"], 1)
	assert_eq(mods["hit_modifier"], 0.10)


# AC.3.2: Low attacks high → range -1, hit -10% per level

func test_low_attacks_high_range_penalty() -> void:
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(0, 2)
	assert_eq(mods["range_modifier"], -2, "-2 range for -2 level diff")
	assert_eq(mods["hit_modifier"], -0.20, "-20% hit")

func test_low_attacks_high_effective_range() -> void:
	var effective: int = TacticalFormulas.get_effective_range(3, 0, 2)
	assert_eq(effective, 1, "base 3 - 2 = 1")

func test_effective_range_can_go_below_1() -> void:
	var effective: int = TacticalFormulas.get_effective_range(1, 0, 2)
	assert_eq(effective, -1, "Attack impossible at negative range")


# AC.3.3: Same level → no modifiers

func test_same_level_no_modifier() -> void:
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(1, 1)
	assert_eq(mods["range_modifier"], 0)
	assert_eq(mods["hit_modifier"], 0.0)

func test_same_level_effective_range_unchanged() -> void:
	var effective: int = TacticalFormulas.get_effective_range(3, 1, 1)
	assert_eq(effective, 3)


# AC.3.4: Ranged weapon height effect

func test_bow_on_highland_target_plain() -> void:
	var effective: int = TacticalFormulas.get_effective_range(4, 2, 1)
	assert_eq(effective, 5, "Bow range 4 + height diff 1 = 5")

func test_magic_height_bonus() -> void:
	var mods: Dictionary = TacticalFormulas.get_height_modifiers(2, 0)
	var magic_range: int = 5 + mods["range_modifier"]
	assert_eq(magic_range, 7, "Magic range 5 + 2 height = 7")

func test_height_diff_zero_both_sides() -> void:
	var atk_mods: Dictionary = TacticalFormulas.get_height_modifiers(0, 0)
	assert_eq(atk_mods["range_modifier"], 0)
	assert_eq(atk_mods["hit_modifier"], 0.0)


# Height constants

func test_height_levels() -> void:
	assert_eq(TerrainTypes.HEIGHT_LOW, 0)
	assert_eq(TerrainTypes.HEIGHT_PLAIN, 1)
	assert_eq(TerrainTypes.HEIGHT_HIGH, 2)
