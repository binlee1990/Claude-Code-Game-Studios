# tests/unit/class/state_machine_test.gd
# Story 001: Class Data Model & State Machine
# Validates AC.1.1 through AC.1.5

extends Gut

var _component: ClassComponent

func before_each() -> void:
	_component = ClassComponent.new()
	_component.name = "ClassComponent"
	add_child(_component)

func after_each() -> void:
	if is_instance_valid(_component):
		_component.queue_free()


# AC.1.1: New character enters BASIC_ACTIVE as BASIC_WARRIOR

func test_initial_state_is_basic_active() -> void:
	assert_eq(_component.get_state(), ClassNames.ClassState.BASIC_ACTIVE)

func test_initial_class_is_warrior() -> void:
	assert_eq(_component.get_class_id(), ClassNames.ClassID.BASIC_WARRIOR)

func test_initial_exp_is_zero() -> void:
	assert_eq(_component.get_current_class_exp(), 0)

func test_initial_level_is_one() -> void:
	assert_eq(_component.get_class_level(), 1)

func test_initial_not_terminal() -> void:
	assert_false(_component.is_terminal())


# AC.1.2: BASIC_ACTIVE → ADVANCED_UNLOCKED

func test_basic_to_advanced_unlocked() -> void:
	var result: bool = _component.try_unlock_advanced()
	assert_true(result, "Transition succeeds")
	assert_eq(_component.get_state(), ClassNames.ClassState.ADVANCED_UNLOCKED)

func test_unlock_emits_state_signal() -> void:
	var signals: Array = []
	_component.class_state_changed.connect(func(old, new): signals.append({"old": old, "new": new}))
	_component.try_unlock_advanced()
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["old"], ClassNames.ClassState.BASIC_ACTIVE)
	assert_eq(signals[0]["new"], ClassNames.ClassState.ADVANCED_UNLOCKED)

func test_cannot_unlock_advanced_from_wrong_state() -> void:
	_component.try_unlock_advanced()
	assert_false(_component.try_unlock_advanced(), "Already ADVANCED_UNLOCKED, can't re-unlock")


# AC.1.3: ADVANCED_UNLOCKED → ADVANCED_ACTIVE (confirm) or → BASIC_ACTIVE (decline)

func test_confirm_advanced_class_change() -> void:
	_component.try_unlock_advanced()
	var result: bool = _component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_true(result, "Class change succeeds")
	assert_eq(_component.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE)
	assert_eq(_component.get_class_id(), ClassNames.ClassID.ADV_SWORDMASTER)

func test_confirm_emits_class_changed_signal() -> void:
	_component.try_unlock_advanced()
	var signals: Array = []
	_component.class_changed.connect(func(old_c, new_c): signals.append({"old": old_c, "new": new_c}))
	_component.confirm_class_change(ClassNames.ClassID.ADV_BATTLEMAGE)
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["old"], ClassNames.ClassID.BASIC_WARRIOR)
	assert_eq(signals[0]["new"], ClassNames.ClassID.ADV_BATTLEMAGE)

func test_confirm_rejects_basic_class() -> void:
	_component.try_unlock_advanced()
	assert_false(_component.confirm_class_change(ClassNames.ClassID.BASIC_MAGE), "Can't change to basic class")
	assert_eq(_component.get_state(), ClassNames.ClassState.ADVANCED_UNLOCKED, "State unchanged")

func test_confirm_rejects_special_class() -> void:
	_component.try_unlock_advanced()
	assert_false(_component.confirm_class_change(ClassNames.ClassID.SPC_DRAGONKNIGHT), "Can't change to special class from ADVANCED_UNLOCKED")

func test_decline_returns_to_basic_active() -> void:
	_component.try_unlock_advanced()
	var result: bool = _component.decline_class_change()
	assert_true(result)
	assert_eq(_component.get_state(), ClassNames.ClassState.BASIC_ACTIVE)
	assert_true(_component.is_choice_recorded())

func test_decline_preserves_class() -> void:
	_component.try_unlock_advanced()
	_component.decline_class_change()
	assert_eq(_component.get_class_id(), ClassNames.ClassID.BASIC_WARRIOR)


# AC.1.4: ADVANCED_ACTIVE → SPECIAL_UNLOCKED

func test_advanced_to_special_unlocked() -> void:
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	var result: bool = _component.try_unlock_special()
	assert_true(result, "Special unlock succeeds")
	assert_eq(_component.get_state(), ClassNames.ClassState.SPECIAL_UNLOCKED)

func test_cannot_unlock_special_from_basic() -> void:
	assert_false(_component.try_unlock_special(), "Can't unlock special from BASIC_ACTIVE")


# AC.1.5: SPECIAL_ACTIVE is terminal

func test_special_active_is_terminal() -> void:
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	_component.try_unlock_special()
	_component.confirm_class_change(ClassNames.ClassID.SPC_DRAGONKNIGHT)
	assert_eq(_component.get_state(), ClassNames.ClassState.SPECIAL_ACTIVE)
	assert_true(_component.is_terminal())

func test_no_transitions_from_terminal() -> void:
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	_component.try_unlock_special()
	_component.confirm_class_change(ClassNames.ClassID.SPC_DRAGONKNIGHT)
	assert_false(_component.try_unlock_advanced(), "No re-unlock from terminal")
	assert_false(_component.try_unlock_special(), "No re-unlock special from terminal")
	assert_false(_component.confirm_class_change(ClassNames.ClassID.ADV_PALADIN), "No class change from terminal")
	assert_eq(_component.get_state(), ClassNames.ClassState.SPECIAL_ACTIVE)


# Class experience and level

func test_add_class_exp() -> void:
	_component.add_class_exp(100)
	assert_eq(_component.get_current_class_exp(), 100)

func test_class_exp_capped() -> void:
	var added: int = _component.add_class_exp(9999)
	assert_eq(_component.get_current_class_exp(), ClassNames.EXP_CAP_BASIC)
	assert_eq(added, ClassNames.EXP_CAP_BASIC, "Only actual gain returned")

func test_class_level_at_1000() -> void:
	_component.add_class_exp(1000)
	assert_eq(_component.get_class_level(), 2)

func test_class_exp_per_class_tracked() -> void:
	_component.add_class_exp(200)
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	_component.add_class_exp(300)
	assert_eq(_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 200, "Old class exp preserved")
	assert_eq(_component.get_current_class_exp(), 300, "New class exp tracked")


# Serialization round-trip

func test_serialization_round_trip() -> void:
	_component.add_class_exp(400)
	_component.try_unlock_advanced()
	_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	_component.add_class_exp(250)

	var data: Dictionary = _component.get_data()
	var loaded := ClassComponent.new()
	loaded.name = "LoadedCC"
	add_child(loaded)
	loaded.load_data(data)

	assert_eq(loaded.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE)
	assert_eq(loaded.get_class_id(), ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(loaded.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 400)
	assert_eq(loaded.get_current_class_exp(), 250)
	loaded.queue_free()
