# tests/unit/attributes/data_model_init_test.gd
# Story 001: Attribute Data Model & Character Init
# Validates AC-1.1 through AC-1.5 from design/gdd/attribute-growth-system.md

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()


# AC-1.1: Normal attributes initialized to V=10, P=E(1)

func test_normal_attributes_init_to_10() -> void:
	for attr: int in AttributeNames.NORMAL_ATTRIBUTES:
		assert_eq(_unit.get_attribute(attr), 10, \
			"%s should init V=10" % AttributeNames.get_attribute_name(attr))

func test_normal_attributes_potential_is_e() -> void:
	for attr: int in AttributeNames.NORMAL_ATTRIBUTES:
		assert_eq(_unit.get_potential(attr), AttributeNames.PotentialGrade.E, \
			"%s should init P=E(1)" % AttributeNames.get_attribute_name(attr))


# AC-1.2: Hidden attributes initialized to V=10, P=E(1)

func test_hidden_attributes_init_to_10() -> void:
	for attr: int in AttributeNames.HIDDEN_ATTRIBUTES:
		assert_eq(_unit.get_attribute(attr), 10, \
			"%s should init V=10" % AttributeNames.get_attribute_name(attr))

func test_hidden_attributes_potential_is_e() -> void:
	for attr: int in AttributeNames.HIDDEN_ATTRIBUTES:
		assert_eq(_unit.get_potential(attr), AttributeNames.PotentialGrade.E, \
			"%s should init P=E(1)" % AttributeNames.get_attribute_name(attr))


# AC-1.3: get_attribute_value returns correct V for each attribute

func test_get_attribute_value_all_9_are_10() -> void:
	for attr: int in AttributeNames.ALL_ATTRIBUTES:
		assert_eq(_unit.get_attribute(attr), 10, \
			"Attribute %d should return V=10" % attr)

func test_get_attribute_value_invalid_returns_zero() -> void:
	assert_eq(_unit.get_attribute(-999), 0, "Invalid attribute should return 0")


# AC-1.4: get_attribute_potential returns correct P (1-6)

func test_get_potential_all_9_are_e() -> void:
	for attr: int in AttributeNames.ALL_ATTRIBUTES:
		assert_eq(_unit.get_potential(attr), 1, \
			"Attribute %d should return P=1" % attr)

func test_get_potential_invalid_returns_e() -> void:
	assert_eq(_unit.get_potential(-999), AttributeNames.PotentialGrade.E, \
		"Invalid attribute should return P=E(1)")


# AC-1.5: get_attributes_snapshot returns all 9 attributes with V and P

func test_snapshot_has_9_entries() -> void:
	var snapshot := _unit.get_attributes_snapshot()
	assert_eq(snapshot.size(), 9, "Snapshot should contain all 9 attributes")

func test_snapshot_all_values_are_10() -> void:
	var snapshot := _unit.get_attributes_snapshot()
	for attr_key in snapshot:
		assert_eq(snapshot[attr_key]["value"], 10, \
			"Snapshot V should be 10 for key %s" % str(attr_key))

func test_snapshot_all_potentials_are_1() -> void:
	var snapshot := _unit.get_attributes_snapshot()
	for attr_key in snapshot:
		assert_eq(snapshot[attr_key]["potential"], 1, \
			"Snapshot P should be 1 for key %s" % str(attr_key))

func test_snapshot_includes_potential_grade() -> void:
	var snapshot := _unit.get_attributes_snapshot()
	for attr_key in snapshot:
		assert_eq(snapshot[attr_key]["potential_grade"], "E", \
			"Snapshot grade should be E for key %s" % str(attr_key))

func test_snapshot_is_independent_copy() -> void:
	var snap1 := _unit.get_attributes_snapshot()
	var snap2 := _unit.get_attributes_snapshot()
	snap1[AttributeNames.Attribute.STR]["value"] = 999
	assert_eq(snap2[AttributeNames.Attribute.STR]["value"], 10, \
		"Second snapshot should not be affected by first modification")
