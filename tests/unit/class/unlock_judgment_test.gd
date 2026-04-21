# tests/unit/class/unlock_judgment_test.gd
# Story 002: Class Unlock Judgment (CAN_UNLOCK)
# Validates AC.2.1 through AC.2.4

extends Gut

var _component: ClassComponent
var _attrs: Dictionary

func before_each() -> void:
	_component = ClassComponent.new()
	_component.name = "ClassComponent"
	add_child(_component)
	_attrs = {
		AttributeNames.Attribute.STR: 10, AttributeNames.Attribute.AGI: 10,
		AttributeNames.Attribute.CON: 10, AttributeNames.Attribute.INT: 10,
		AttributeNames.Attribute.CHA: 10, AttributeNames.Attribute.LUK: 10,
		AttributeNames.Attribute.WIL: 10, AttributeNames.Attribute.RES: 10,
		AttributeNames.Attribute.SOU: 10,
	}

func after_each() -> void:
	if is_instance_valid(_component):
		_component.queue_free()

func _get_attr(attr_type: int) -> int:
	return _attrs.get(attr_type, 0)


# AC.2.1: Three-condition AND logic

func test_all_conditions_met_returns_true() -> void:
	_attrs[AttributeNames.Attribute.STR] = 52
	_attrs[AttributeNames.Attribute.AGI] = 45
	_component.add_class_exp(600)
	# Need to add exp for the target class specifically
	_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_SWORDMASTER, _get_attr)
	assert_true(result["can_unlock"])
	assert_eq(result["reasons"].size(), 0)

func test_exact_threshold_returns_true() -> void:
	_attrs[AttributeNames.Attribute.STR] = 50
	_attrs[AttributeNames.Attribute.AGI] = 40
	_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 500
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_SWORDMASTER, _get_attr)
	assert_true(result["can_unlock"], "Exact threshold should pass")

func test_primary_one_short_returns_false() -> void:
	_attrs[AttributeNames.Attribute.STR] = 49
	_attrs[AttributeNames.Attribute.AGI] = 45
	_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 600
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_SWORDMASTER, _get_attr)
	assert_false(result["can_unlock"])
	assert_eq(result["reasons"].size(), 1)
	assert_true(str(result["reasons"][0]).contains("STR"), "Reports STR shortfall")

func test_secondary_one_short_returns_false() -> void:
	_attrs[AttributeNames.Attribute.INT] = 50
	_attrs[AttributeNames.Attribute.STR] = 39
	_component._class_exp[ClassNames.ClassID.ADV_BATTLEMAGE] = 500
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_BATTLEMAGE, _get_attr)
	assert_false(result["can_unlock"])
	assert_eq(result["reasons"].size(), 1)
	assert_true(str(result["reasons"][0]).contains("STR"), "Reports secondary attr shortfall")

func test_exp_short_returns_false() -> void:
	_attrs[AttributeNames.Attribute.STR] = 52
	_attrs[AttributeNames.Attribute.AGI] = 45
	_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 499
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_SWORDMASTER, _get_attr)
	assert_false(result["can_unlock"])
	assert_eq(result["reasons"].size(), 1)
	assert_true(str(result["reasons"][0]).contains("experience"), "Reports exp shortfall")

func test_multiple_failures_reported() -> void:
	_attrs[AttributeNames.Attribute.INT] = 30
	_attrs[AttributeNames.Attribute.STR] = 20
	_component._class_exp[ClassNames.ClassID.ADV_BATTLEMAGE] = 100
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_BATTLEMAGE, _get_attr)
	assert_false(result["can_unlock"])
	assert_eq(result["reasons"].size(), 3, "All three conditions fail")

func test_all_advanced_classes_use_correct_attrs() -> void:
	var test_cases: Array = [
		[ClassNames.ClassID.ADV_SWORDMASTER, AttributeNames.Attribute.STR, AttributeNames.Attribute.AGI],
		[ClassNames.ClassID.ADV_BATTLEMAGE, AttributeNames.Attribute.INT, AttributeNames.Attribute.STR],
		[ClassNames.ClassID.ADV_MARKSMAN, AttributeNames.Attribute.AGI, AttributeNames.Attribute.STR],
		[ClassNames.ClassID.ADV_ASSASSIN, AttributeNames.Attribute.AGI, AttributeNames.Attribute.LUK],
		[ClassNames.ClassID.ADV_HIGHCLERIC, AttributeNames.Attribute.CHA, AttributeNames.Attribute.INT],
		[ClassNames.ClassID.ADV_PALADIN, AttributeNames.Attribute.CON, AttributeNames.Attribute.CHA],
	]
	for tc in test_cases:
		var class_id: int = tc[0]
		var primary: int = tc[1]
		var secondary: int = tc[2]
		# Reset attrs
		for k in _attrs: _attrs[k] = 10
		_attrs[primary] = 55
		_attrs[secondary] = 45
		_component._class_exp[class_id] = 600
		var result: Dictionary = _component.can_unlock(class_id, _get_attr)
		assert_true(result["can_unlock"], "%s should unlock with correct attrs" % ClassNames.ClassID.keys()[class_id])


# AC.2.2: Basic classes always return TRUE

func test_basic_warrior_always_true() -> void:
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.BASIC_WARRIOR, _get_attr)
	assert_true(result["can_unlock"])

func test_basic_mage_always_true() -> void:
	_attrs[AttributeNames.Attribute.INT] = 0
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.BASIC_MAGE, _get_attr)
	assert_true(result["can_unlock"], "Basic class ignores all conditions")

func test_basic_class_zero_exp_true() -> void:
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.BASIC_KNIGHT, _get_attr)
	assert_true(result["can_unlock"])

func test_all_basic_classes_true() -> void:
	var basics: Array[int] = [
		ClassNames.ClassID.BASIC_WARRIOR, ClassNames.ClassID.BASIC_MAGE,
		ClassNames.ClassID.BASIC_ARCHER, ClassNames.ClassID.BASIC_ROGUE,
		ClassNames.ClassID.BASIC_CLERIC, ClassNames.ClassID.BASIC_KNIGHT,
	]
	for class_id in basics:
		assert_true(
			_component.can_unlock(class_id, _get_attr)["can_unlock"],
			"%s always unlockable" % ClassNames.ClassID.keys()[class_id]
		)


# AC.2.3: Special classes check achievement points

func test_special_unlock_with_enough_points() -> void:
	var result: Dictionary = _component.can_unlock(
		ClassNames.ClassID.SPC_DRAGONKNIGHT, _get_attr, 2500)
	assert_true(result["can_unlock"])

func test_special_insufficient_points() -> void:
	var result: Dictionary = _component.can_unlock(
		ClassNames.ClassID.SPC_DRAGONKNIGHT, _get_attr, 1500)
	assert_false(result["can_unlock"])
	assert_eq(result["reasons"].size(), 1)
	assert_true(str(result["reasons"][0]).contains("1500/2000"))

func test_sovereign_needs_3000_points() -> void:
	var result: Dictionary = _component.can_unlock(
		ClassNames.ClassID.SPC_SOVEREIGN, _get_attr, 2500)
	assert_false(result["can_unlock"])
	assert_true(str(result["reasons"][0]).contains("2500/3000"))

func test_special_exact_points_passes() -> void:
	var result: Dictionary = _component.can_unlock(
		ClassNames.ClassID.SPC_NIGHTSHADE, _get_attr, 2000)
	assert_true(result["can_unlock"], "Exact 2000 points should pass")


# AC.2.4: Failure reasons are specific

func test_reason_shows_exact_shortfall() -> void:
	_attrs[AttributeNames.Attribute.STR] = 45
	_attrs[AttributeNames.Attribute.AGI] = 30
	_component._class_exp[ClassNames.ClassID.ADV_SWORDMASTER] = 400
	var result: Dictionary = _component.can_unlock(ClassNames.ClassID.ADV_SWORDMASTER, _get_attr)
	assert_false(result["can_unlock"])
	var reasons_str: String = str(result["reasons"])
	assert_true(reasons_str.contains("5 more"), "STR short by 5")
	assert_true(reasons_str.contains("10 more"), "AGI short by 10")
