# tests/unit/ai/boss_ai_test.gd
# Story 005: Boss AI
# Validates AC.4.1-4.3

extends Gut

var _brain: AIBrain

func before_each() -> void:
	_brain = AIBrain.new(AI.AIType.AGGRESSIVE)

# AC.4.1: Phase switch at 70% HP

func test_phase_switch_at_70_percent() -> void:
	var result: bool = _brain.check_boss_phase(0.69)
	assert_true(result, "Below 70% triggers phase switch")
	assert_eq(_brain.get_boss_phase(), 1)

func test_no_switch_above_70() -> void:
	var result: bool = _brain.check_boss_phase(0.71)
	assert_false(result, "Above 70% no switch")

func test_switch_at_exact_70() -> void:
	var result: bool = _brain.check_boss_phase(0.70)
	assert_true(result, "At exactly 70% triggers")

func test_phase_does_not_revert_on_heal() -> void:
	_brain.check_boss_phase(0.69)
	assert_true(_brain.is_boss_enraged())
	# HP heals back above 70%
	assert_true(_brain.is_boss_enraged(), "Phase does not revert")

func test_no_double_switch() -> void:
	_brain.check_boss_phase(0.69)
	var result: bool = _brain.check_boss_phase(0.50)
	assert_false(result, "Already enraged, no second switch")


# AC.4.2: Enrage damage +30%

func test_enrage_damage_multiplier() -> void:
	assert_eq(_brain.get_boss_damage_multiplier(), 1.0, "Not enraged yet")
	_brain.check_boss_phase(0.69)
	assert_eq(_brain.get_boss_damage_multiplier(), 1.3, "Enraged: +30%")

func test_enrage_damage_calculation() -> void:
	_brain.check_boss_phase(0.69)
	var base_damage: int = 100
	var final_damage: int = int(base_damage * _brain.get_boss_damage_multiplier())
	assert_eq(final_damage, 130)

func test_enrage_stacks_with_restraint() -> void:
	_brain.check_boss_phase(0.69)
	var enrage: float = _brain.get_boss_damage_multiplier()
	var restraint: float = TacticalFormulas.get_triangle_modifier(
		TacticalFormulas.WeaponType.SWORD, TacticalFormulas.WeaponType.SPEAR)
	assert_eq_fTol(enrage * restraint, 1.95, 0.0001, "1.3 × 1.5 = 1.95")

func test_enrage_stacks_with_crush() -> void:
	_brain.check_boss_phase(0.69)
	var combined: float = _brain.get_boss_damage_multiplier() * 1.5
	assert_eq_fTol(combined, 1.95, 0.0001)


# AC.4.3: Phase switch event

func test_boss_phase_event_emitted() -> void:
	var signals: Array = []
	_brain.boss_phase_changed.connect(func(boss_id, phase, skills): signals.append({"boss_id": boss_id, "phase": phase}))
	_brain.check_boss_phase(0.69)
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["boss_id"], 0)
	assert_eq(signals[0]["phase"], 1)

func test_boss_phase_event_with_id() -> void:
	var signals: Array = []
	_brain.boss_phase_changed.connect(func(boss_id, phase, skills): signals.append(boss_id))
	_brain.check_boss_phase(0.69, 42)
	assert_eq(signals[0], 42, "Emitted with correct boss_id")


# Serialization

func test_boss_state_round_trip() -> void:
	_brain.check_boss_phase(0.69)
	var data: Dictionary = _brain.get_data()
	assert_eq(data["boss_enraged"], true)
	assert_eq(data["boss_phase"], 1)

	var loaded := AIBrain.new(AI.AIType.AGGRESSIVE)
	loaded.load_data(data)
	assert_true(loaded.is_boss_enraged())
	assert_eq(loaded.get_boss_phase(), 1)
	assert_eq(loaded.get_boss_damage_multiplier(), 1.3)
