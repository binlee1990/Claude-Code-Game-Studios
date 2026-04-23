# tests/integration/class/save_load_integration_test.gd
# Story 006: Class Save/Load Integration
# Validates AC.7.1 through AC.7.3

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	_unit.unit_id = &"save_class_char"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _set_attr(attr: int, value: int) -> void:
	var comp: AttributeComponent = _unit.attributes.get_component(attr)
	comp.load_data({
		"value": value, "potential": 3,
		"barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false},
		"thresholds_reached": {}
	})


# AC.7.1: Full class state round-trip

func test_advanced_class_state_round_trip() -> void:
	_unit.class_component.add_class_exp(800)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 350
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)

	assert_eq(loaded.class_component.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE)
	assert_eq(loaded.class_component.get_class_id(), ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 800)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.ADV_SWORDMASTER), 350)
	loaded.queue_free()

func test_basic_class_state_round_trip() -> void:
	_unit.class_component.add_class_exp(450)
	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)
	assert_eq(loaded.class_component.get_state(), ClassNames.ClassState.BASIC_ACTIVE)
	assert_eq(loaded.class_component.get_class_id(), ClassNames.ClassID.BASIC_WARRIOR)
	assert_eq(loaded.class_component.get_current_class_exp(), 450)
	loaded.queue_free()

func test_multiple_class_experiences_round_trip() -> void:
	_unit.class_component.add_class_exp(500)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_PALADIN] = 200
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_BATTLEMAGE] = 100
	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 500)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.ADV_PALADIN), 200)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.ADV_BATTLEMAGE), 100)
	loaded.queue_free()


# AC.7.2: Decision record persistence

func test_choice_recorded_persists() -> void:
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.decline_class_change()
	assert_true(_unit.class_component.is_choice_recorded())

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)
	assert_true(loaded.class_component.is_choice_recorded(), "Choice record restored")
	assert_eq(loaded.class_component.get_state(), ClassNames.ClassState.BASIC_ACTIVE)
	loaded.queue_free()


# AC.7.3: State machine resumption

func test_special_active_terminal_round_trip() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.SPC_DRAGONKNIGHT, ClassNames.ClassState.SPECIAL_ACTIVE,
		{ClassNames.ClassID.BASIC_WARRIOR: 1000, ClassNames.ClassID.ADV_SWORDMASTER: 2000,
		 ClassNames.ClassID.SPC_DRAGONKNIGHT: 500}, false
	)
	assert_true(_unit.class_component.is_terminal())

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)

	assert_eq(loaded.class_component.get_state(), ClassNames.ClassState.SPECIAL_ACTIVE)
	assert_eq(loaded.class_component.get_class_id(), ClassNames.ClassID.SPC_DRAGONKNIGHT)
	assert_true(loaded.class_component.is_terminal())
	assert_false(loaded.class_component.try_unlock_advanced(), "No transitions from terminal after load")
	assert_false(loaded.class_component.confirm_class_change(ClassNames.ClassID.ADV_PALADIN))
	loaded.queue_free()

func test_double_round_trip_stable() -> void:
	_unit.class_component.add_class_exp(300)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 200
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)

	var saved1: Dictionary = _unit.serialize()
	var loaded1 := Unit.new()
	loaded1.name = "L1"
	add_child(loaded1)
	loaded1.deserialize(saved1)

	var saved2: Dictionary = loaded1.serialize()
	var loaded2 := Unit.new()
	loaded2.name = "L2"
	add_child(loaded2)
	loaded2.deserialize(saved2)

	assert_eq(loaded2.class_component.get_state(), loaded1.class_component.get_state())
	assert_eq(loaded2.class_component.get_class_id(), loaded1.class_component.get_class_id())
	assert_eq(loaded2.class_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 300)
	assert_eq(loaded2.class_component.get_current_class_exp(), 200)

	loaded1.queue_free()
	loaded2.queue_free()

func test_attributes_and_class_together() -> void:
	_set_attr(AttributeNames.Attribute.STR, 55)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_unit.class_component.add_class_exp(600)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "Loaded"
	add_child(loaded)
	loaded.deserialize(saved)

	assert_eq(loaded.get_attribute(AttributeNames.Attribute.STR), 55, "Attributes preserved")
	assert_eq(loaded.get_effective_attribute(AttributeNames.Attribute.STR), 70, "55+15 bonus restored")
	assert_eq(loaded.class_component.get_class_id(), ClassNames.ClassID.ADV_SWORDMASTER)
	loaded.queue_free()
