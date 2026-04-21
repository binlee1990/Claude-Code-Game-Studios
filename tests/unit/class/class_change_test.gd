# tests/unit/class/class_change_test.gd
# Story 004: Class Change Flow
# Validates AC.4.1 through AC.4.6

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	_unit.unit_id = &"char_test"
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


# AC.4.1: Attributes preserved after class change

func test_attributes_preserved_after_change() -> void:
	_set_attr(AttributeNames.Attribute.STR, 52)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_set_attr(AttributeNames.Attribute.CON, 30)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.STR), 52)
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.AGI), 45)
	assert_eq(_unit.get_attribute(AttributeNames.Attribute.CON), 30)

func test_potentials_preserved_after_change() -> void:
	_set_attr(AttributeNames.Attribute.STR, 52)
	var comp: AttributeComponent = _unit.attributes.get_component(AttributeNames.Attribute.STR)
	comp.set_potential(5)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.get_potential(AttributeNames.Attribute.STR), 5)


# AC.4.2: New class exp resets to 0

func test_new_class_exp_resets() -> void:
	_unit.class_component.add_class_exp(600)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.class_component.get_current_class_exp(), 0, "New class starts at 0")


# AC.4.3: Other class exp preserved

func test_old_class_exp_preserved() -> void:
	_unit.class_component.add_class_exp(800)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(
		_unit.class_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR),
		800,
		"Old warrior exp preserved"
	)


# AC.4.4: Bonuses apply immediately

func test_bonus_applies_immediately() -> void:
	_set_attr(AttributeNames.Attribute.STR, 52)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 67, "52 + 15 SWORDMASTER bonus")

func test_basic_warrior_bonus() -> void:
	_set_attr(AttributeNames.Attribute.STR, 30)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 40, "30 + 10 warrior bonus")

func test_bonus_changes_on_class_change() -> void:
	_set_attr(AttributeNames.Attribute.AGI, 50)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 50, "Warrior has 0 AGI bonus")
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 55, "50 + 5 SWORDMASTER AGI bonus")


# AC.4.5: Class change triggers threshold check (via signal)

func test_class_change_emits_class_component_signal() -> void:
	var signals: Array = []
	_unit.class_component.class_changed.connect(func(old_c, new_c): signals.append({"old": old_c, "new": new_c}))
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(signals.size(), 1)
	assert_eq(signals[0]["old"], ClassNames.ClassID.BASIC_WARRIOR)
	assert_eq(signals[0]["new"], ClassNames.ClassID.ADV_SWORDMASTER)


# AC.4.6: GameEvents.class_changed emitted

func test_game_events_class_changed() -> void:
	var ge_signals: Array = []
	var handler := func(u: Node, old_c: int, new_c: int) -> void:
		ge_signals.append({"unit": u, "old_class": old_c, "new_class": new_c})
	GameEvents.class_changed.connect(handler)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	GameEvents.class_changed.disconnect(handler)
	assert_eq(ge_signals.size(), 1)
	assert_eq(ge_signals[0]["unit"].unit_id, &"char_test")
	assert_eq(ge_signals[0]["old_class"], ClassNames.ClassID.BASIC_WARRIOR)
	assert_eq(ge_signals[0]["new_class"], ClassNames.ClassID.ADV_SWORDMASTER)


# execute_class_change with validation

func test_execute_change_validates_can_unlock() -> void:
	_set_attr(AttributeNames.Attribute.STR, 30)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	var result: Dictionary = _unit.execute_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_false(result["success"], "STR too low, should fail")

func test_execute_change_succeeds_when_conditions_met() -> void:
	_set_attr(AttributeNames.Attribute.STR, 52)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	_unit.class_component.try_unlock_advanced()
	var result: Dictionary = _unit.execute_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_true(result["success"])
	assert_eq(_unit.class_component.get_class_id(), ClassNames.ClassID.ADV_SWORDMASTER)

func test_execute_change_via_unit_convenience() -> void:
	_set_attr(AttributeNames.Attribute.STR, 52)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	_unit.class_component.try_unlock_advanced()
	_unit.execute_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 67, "Bonus applied via Unit method")


# Round-trip includes class data

func test_serialization_includes_class() -> void:
	_unit.class_component.add_class_exp(400)
	var data: Dictionary = _unit.serialize()
	assert_true("class" in data, "Serialized data has class key")
	assert_eq(data["class"]["current_class"], ClassNames.ClassID.BASIC_WARRIOR)
	assert_eq(data["class"]["class_exp"][ClassNames.ClassID.BASIC_WARRIOR], 400)

func test_deserialization_restores_class() -> void:
	_unit.class_component.add_class_exp(300)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_PALADIN)
	_unit.class_component.add_class_exp(150)

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "LoadedUnit"
	add_child(loaded)
	loaded.deserialize(saved)

	assert_eq(loaded.class_component.get_class_id(), ClassNames.ClassID.ADV_PALADIN)
	assert_eq(loaded.class_component.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE)
	assert_eq(loaded.class_component.get_class_exp(ClassNames.ClassID.BASIC_WARRIOR), 300)
	assert_eq(loaded.class_component.get_current_class_exp(), 150)
	loaded.queue_free()
