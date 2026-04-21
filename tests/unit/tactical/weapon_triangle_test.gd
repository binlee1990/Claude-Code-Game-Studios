# tests/unit/tactical/weapon_triangle_test.gd
# Story 002: Weapon Triangle
# Validates AC.1.1-1.4

extends Gut

# AC.1.1: Sword > Spear

func test_sword_advantage_over_spear() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR), 1.5)

func test_sword_vs_spear_150_damage() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR, 1.0)
	assert_eq(int(100 * mult), 150)


# AC.1.2: Spear > Axe

func test_spear_advantage_over_axe() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SPEAR, TacticalFormulas.WeaponType.AXE), 1.5)


# AC.1.3: Axe > Sword

func test_axe_advantage_over_sword() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
	 TacticalFormulas.WeaponType.AXE, TacticalFormulas.WeaponType.SWORD), 1.5)


# No advantage cases

func test_no_advantage_same_weapon() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SWORD), 1.0)

func test_no_advantage_reverse() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SPEAR, TacticalFormulas.WeaponType.SWORD), 1.0)
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.AXE, TacticalFormulas.WeaponType.SPEAR), 1.0)
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.AXE), 1.0)

func test_bow_no_advantage() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.BOW, TacticalFormulas.WeaponType.SWORD), 1.0)
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.BOW), 1.0)

func test_magic_no_advantage() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.MAGIC, TacticalFormulas.WeaponType.SWORD), 1.0)

func test_fist_no_advantage() -> void:
	assert_eq(TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.FIST, TacticalFormulas.WeaponType.SWORD), 1.0)


# AC.1.4: Restraint + crush stacking → 2.25x

func test_restraint_plus_crush_stacks() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR, 1.5)
	assert_eq(mult, 2.25)

func test_no_restraint_no_crush() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.BOW, TacticalFormulas.WeaponType.SWORD, 1.0)
	assert_eq(mult, 1.0)

func test_restraint_only() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR, 1.0)
	assert_eq(mult, 1.5)

func test_crush_only() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.BOW, TacticalFormulas.WeaponType.SWORD, 1.5)
	assert_eq(mult, 1.5)

func test_stacked_damage_225() -> void:
	var mult: float = TacticalFormulas.get_combined_multiplier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR, 1.5)
	assert_eq(int(100 * mult), 225)


# has_advantage helper

func test_has_advantage_true() -> void:
	assert_true(TacticalFormulas.has_advantage(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR))

func test_has_advantage_false() -> void:
	assert_false(TacticalFormulas.has_advantage(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.AXE))
