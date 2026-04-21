# tests/unit/class/stat_bonuses_test.gd
# Story 005: Class Stat Bonuses
# Validates AC.5.1 through AC.5.3

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
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

func _make_advanced_warrior() -> void:
	_set_attr(AttributeNames.Attribute.STR, 55)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)


# AC.5.1: Bonus table application for all classes

func test_warrior_bonuses() -> void:
	_set_attr(AttributeNames.Attribute.STR, 30)
	_set_attr(AttributeNames.Attribute.CON, 20)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 40, "STR +10")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 25, "CON +5")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 10, "AGI +0")

func test_mage_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.BASIC_MAGE, ClassNames.ClassState.BASIC_ACTIVE, {}, false
	)
	_set_attr(AttributeNames.Attribute.INT, 45)
	_set_attr(AttributeNames.Attribute.CON, 20)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.INT), 60, "INT +15")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 15, "CON -5")

func test_archer_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.BASIC_ARCHER, ClassNames.ClassState.BASIC_ACTIVE, {}, false
	)
	_set_attr(AttributeNames.Attribute.AGI, 30)
	_set_attr(AttributeNames.Attribute.STR, 20)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 40, "AGI +10")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 25, "STR +5")

func test_rogue_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.BASIC_ROGUE, ClassNames.ClassState.BASIC_ACTIVE, {}, false
	)
	_set_attr(AttributeNames.Attribute.AGI, 25)
	_set_attr(AttributeNames.Attribute.LUK, 10)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 40, "AGI +15")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.LUK), 15, "LUK +5")

func test_cleric_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.BASIC_CLERIC, ClassNames.ClassState.BASIC_ACTIVE, {}, false
	)
	_set_attr(AttributeNames.Attribute.CHA, 30)
	_set_attr(AttributeNames.Attribute.INT, 20)
	_set_attr(AttributeNames.Attribute.RES, 10)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CHA), 40, "CHA +10")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.INT), 25, "INT +5")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.RES), 15, "RES +5")

func test_knight_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.BASIC_KNIGHT, ClassNames.ClassState.BASIC_ACTIVE, {}, false
	)
	_set_attr(AttributeNames.Attribute.CON, 30)
	_set_attr(AttributeNames.Attribute.STR, 20)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 45, "CON +15")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 25, "STR +5")

func test_swordmaster_bonuses() -> void:
	_make_advanced_warrior()
	_set_attr(AttributeNames.Attribute.STR, 55)
	_set_attr(AttributeNames.Attribute.AGI, 45)
	_set_attr(AttributeNames.Attribute.CON, 30)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 70, "STR +15")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 50, "AGI +5")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 35, "CON +5")

func test_assassin_bonuses() -> void:
	_set_attr(AttributeNames.Attribute.AGI, 55)
	_set_attr(AttributeNames.Attribute.LUK, 45)
	_unit.class_component._class_exp[ClassNames.ClassID.ADV_ASSASSIN] = 600
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_ASSASSIN)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 75, "AGI +20")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.LUK), 55, "LUK +10")

func test_special_bonuses() -> void:
	_unit.class_component.initialize(
		ClassNames.ClassID.SPC_DRAGONKNIGHT, ClassNames.ClassState.SPECIAL_ACTIVE,
		{ClassNames.ClassID.BASIC_WARRIOR: 500, ClassNames.ClassID.ADV_SWORDMASTER: 500,
		 ClassNames.ClassID.SPC_DRAGONKNIGHT: 300}, false
	)
	_set_attr(AttributeNames.Attribute.STR, 60)
	_set_attr(AttributeNames.Attribute.CON, 40)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 80, "STR +20")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 50, "CON +10")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.WIL), 15, "WIL +5")
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.RES), 15, "RES +5")


# AC.5.1: Calculation order (base → class → equipment placeholder)

func test_calculation_order() -> void:
	_set_attr(AttributeNames.Attribute.STR, 50)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 60, "50 base + 10 warrior = 60")


# AC.5.2: Equipment revalidation signaled (class_changed already emits)

func test_class_change_signals_equipment_revalidation() -> void:
	var signals: Array = []
	var handler := func(u: Node, o: int, n: int) -> void: signals.append(n)
	GameEvents.class_changed.connect(handler)
	_make_advanced_warrior()
	GameEvents.class_changed.disconnect(handler)
	assert_eq(signals.size(), 1, "class_changed emitted for equipment system")


# AC.5.3: Bonus suspension when below threshold

func test_bonus_suspended_below_primary_threshold() -> void:
	_make_advanced_warrior()
	_set_attr(AttributeNames.Attribute.STR, 48)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 48, "Bonus suspended, only base")
	assert_eq(_unit.class_component.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE, "State not revoked")

func test_bonus_suspended_below_secondary_threshold() -> void:
	_make_advanced_warrior()
	_set_attr(AttributeNames.Attribute.AGI, 30)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.AGI), 30, "Bonus suspended")
	assert_eq(_unit.class_component.get_state(), ClassNames.ClassState.ADVANCED_ACTIVE, "State preserved")

func test_bonus_restored_when_threshold_met_again() -> void:
	_make_advanced_warrior()
	_set_attr(AttributeNames.Attribute.STR, 48)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 48, "Suspended")
	_set_attr(AttributeNames.Attribute.STR, 52)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 67, "Restored: 52+15")

func test_basic_class_bonus_never_suspended() -> void:
	_set_attr(AttributeNames.Attribute.STR, 1)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 11, "Basic bonus always active even at STR=1")

func test_is_bonus_active_method() -> void:
	_make_advanced_warrior()
	var attr_callable: Callable = func(a: int) -> int: return _unit.attributes.get_value(a)
	assert_true(_unit.class_component.is_bonus_active(attr_callable), "Active when above threshold")
	_set_attr(AttributeNames.Attribute.STR, 48)
	assert_false(_unit.class_component.is_bonus_active(attr_callable), "Suspended when below threshold")
