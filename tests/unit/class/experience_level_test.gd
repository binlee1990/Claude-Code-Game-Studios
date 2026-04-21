# tests/unit/class/experience_level_test.gd
# Story 003: Class Experience & Level System
# Validates AC.3.1-3.5, AC.6.1-6.3

extends Gut

var _component: ClassComponent

func before_each() -> void:
	_component = ClassComponent.new()
	_component.name = "ClassComponent"
	add_child(_component)

func after_each() -> void:
	if is_instance_valid(_component):
		_component.queue_free()


# AC.3.2: Experience formula

func test_exp_standard_kill_battle() -> void:
	# 300 damage + kill + battle = min(floor(300*0.02), 500) + 10 + 20 = 36
	var gained: int = _component.report_damage_dealt(300, true, true)
	assert_eq(gained, 36)
	assert_eq(_component.get_current_class_exp(), 36)

func test_exp_standard_no_kill_battle() -> void:
	# 300 damage + no kill + battle = min(6, 500) + 0 + 20 = 26
	var gained: int = _component.report_damage_dealt(300, false, true)
	assert_eq(gained, 26)

func test_exp_formula_high_damage() -> void:
	# 800 damage: floor(800*0.02) = 16, capped at 500 → 16 + 0 + 20 = 36
	var gained: int = _component.report_damage_dealt(800, false, true)
	assert_eq(gained, 36)

func test_exp_formula_very_high_damage_capped() -> void:
	# 30000 damage: floor(30000*0.02) = 600, capped at 500 → 500 + 10 + 20 = 530
	var gained: int = _component.report_damage_dealt(30000, true, true)
	assert_eq(gained, 530)

func test_exp_boundary_exact_cap() -> void:
	# 25000 damage: floor(25000*0.02) = 500, exactly at cap → 500 + 10 + 20 = 530
	var gained: int = _component.report_damage_dealt(25000, true, true)
	assert_eq(gained, 530)

func test_exp_1_damage() -> void:
	# floor(1*0.02) = 0 → 0 + 0 + 20 = 20
	var gained: int = _component.report_damage_dealt(1, false, true)
	assert_eq(gained, 20)

func test_exp_49_damage() -> void:
	# floor(49*0.02) = 0 → 0 + 0 + 20 = 20
	var gained: int = _component.report_damage_dealt(49, false, true)
	assert_eq(gained, 20)

func test_exp_50_damage() -> void:
	# floor(50*0.02) = 1 → 1 + 0 + 20 = 21
	var gained: int = _component.report_damage_dealt(50, false, true)
	assert_eq(gained, 21)


# AC.3.3: Kill bonus

func test_kill_bonus_10() -> void:
	# 0 damage + kill = 0 + 10 + 20 = 30
	var gained: int = _component.report_damage_dealt(0, true, true)
	assert_eq(gained, 30)

func test_no_kill_bonus() -> void:
	var gained: int = _component.report_damage_dealt(0, false, true)
	assert_eq(gained, 20, "No kill bonus when is_kill=false")


# AC.3.4: Battle bonus always 20

func test_battle_bonus_win() -> void:
	var gained: int = _component.report_damage_dealt(0, false, true)
	assert_eq(gained, 20)

func test_no_battle_bonus() -> void:
	var gained: int = _component.report_damage_dealt(100, true, false)
	assert_eq(gained, 2, "Only damage portion, no battle bonus")
	# floor(100*0.02) = 2 + 10 (kill) + 0 (no battle) = 12
	assert_eq(_component.get_current_class_exp(), 12)


# AC.3.5: Zero damage still awards 20

func test_zero_damage_battle() -> void:
	var gained: int = _component.report_damage_dealt(0, false, true)
	assert_eq(gained, 20)


# AC.3.1: report_damage_dealt accumulates

func test_multiple_reports_accumulate() -> void:
	_component.report_damage_dealt(300, true, true)   # 36
	_component.report_damage_dealt(500, false, true)  # min(10,500)+0+20 = 30
	assert_eq(_component.get_current_class_exp(), 66)


# AC.6.1: Level formula: floor(E_c / CAP_c) + 1

func test_level_1_at_zero() -> void:
	assert_eq(_component.get_class_level(), 1)

func test_level_1_under_cap() -> void:
	_component.add_class_exp(999)
	assert_eq(_component.get_class_level(), 1, "Under 1000 cap → level 1")

func test_level_2_at_cap() -> void:
	_component.add_class_exp(1000)
	assert_eq(_component.get_class_level(), 2)

func test_level_3_double_cap() -> void:
	_component.add_class_exp(2000)
	assert_eq(_component.get_class_level(), 3)

func test_level_with_remainder() -> void:
	_component.add_class_exp(1500)
	assert_eq(_component.get_class_level(), 2, "floor(1500/1000)+1 = 2")


# AC.6.2: Basic class CAP=1000

func test_basic_cap_is_1000() -> void:
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.BASIC_WARRIOR), 1000)
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.BASIC_MAGE), 1000)


# AC.6.3: Advanced/Special class CAP=2000

func test_advanced_cap_is_2000() -> void:
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.ADV_SWORDMASTER), 2000)
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.ADV_PALADIN), 2000)

func test_special_cap_is_2000() -> void:
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.SPC_DRAGONKNIGHT), 2000)
	assert_eq(ClassNames.get_exp_cap(ClassNames.ClassID.SPC_SOVEREIGN), 2000)

func test_advanced_level_3() -> void:
	# Swordmaster with 5500 exp → floor(5500/2000)+1 = 3
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	_component.add_class_exp(5500)
	assert_eq(_component.get_class_level(), 3)


# Exp cap per class

func test_exp_does_not_exceed_cap() -> void:
	_component.add_class_exp(99999)
	assert_eq(_component.get_current_class_exp(), 1000, "Basic class capped at 1000")

func test_calculate_exp_gain_static() -> void:
	assert_eq(ClassNames.calculate_exp_gain(300, true, true), 36)
	assert_eq(ClassNames.calculate_exp_gain(0, false, true), 20)
	assert_eq(ClassNames.calculate_exp_gain(30000, true, true), 530)
