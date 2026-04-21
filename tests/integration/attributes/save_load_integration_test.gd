# tests/integration/attributes/save_load_integration_test.gd
# Story 007: Attribute Save/Load Integration
# Validates AC-S1, AC-S2, AC-S3, AC-S4, AC-S5

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "TestUnit"
	_unit.unit_id = &"save_test_char"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _setup_complex_state() -> void:
	var attrs: Array[int] = [
		AttributeNames.Attribute.STR, AttributeNames.Attribute.AGI,
		AttributeNames.Attribute.CON, AttributeNames.Attribute.INT,
		AttributeNames.Attribute.CHA, AttributeNames.Attribute.LUK,
		AttributeNames.Attribute.WIL, AttributeNames.Attribute.RES,
		AttributeNames.Attribute.SOU
	]
	var values: Array[int] = [85, 72, 60, 45, 33, 28, 15, 22, 10]
	var potentials: Array[int] = [4, 6, 3, 2, 5, 1, 3, 4, 2]
	# barrier states: STR=stage2 (1 broken), AGI=stage3 (1+2 broken), others=stage1 (none broken)
	var barrier_stages: Array[int] = [2, 3, 1, 1, 1, 1, 1, 1, 1]
	var barriers_data: Array[Dictionary] = [
		{1: true, 2: false, 3: false},   # STR
		{1: true, 2: true, 3: false},    # AGI
		{1: false, 2: false, 3: false},  # CON
		{1: false, 2: false, 3: false},  # INT
		{1: false, 2: false, 3: false},  # CHA
		{1: false, 2: false, 3: false},  # LUK
		{1: false, 2: false, 3: false},  # WIL
		{1: false, 2: false, 3: false},  # RES
		{1: false, 2: false, 3: false},  # SOU
	]
	# thresholds: STR=50 reached, INT=50+100 reached, others none
	var thresholds_data: Array[Dictionary] = [
		{50: true, 100: false, 150: false},   # STR
		{50: false, 100: false, 150: false},  # AGI
		{50: false, 100: false, 150: false},  # CON
		{50: true, 100: true, 150: false},    # INT
		{50: false, 100: false, 150: false},  # CHA
		{50: false, 100: false, 150: false},  # LUK
		{50: false, 100: false, 150: false},  # WIL
		{50: false, 100: false, 150: false},  # RES
		{50: false, 100: false, 150: false},  # SOU
	]
	for i in attrs.size():
		var comp: AttributeComponent = _unit.attributes.get_component(attrs[i])
		comp.load_data({
			"value": values[i],
			"potential": potentials[i],
			"barrier_stage": barrier_stages[i],
			"barriers_broken": barriers_data[i],
			"thresholds_reached": thresholds_data[i]
		})


# AC-S1: All 9 attribute values round-trip

func test_attribute_values_round_trip() -> void:
	_setup_complex_state()
	var saved: Dictionary = _unit.serialize()

	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedUnit"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	var expected_values: Dictionary = {
		AttributeNames.Attribute.STR: 85, AttributeNames.Attribute.AGI: 72,
		AttributeNames.Attribute.CON: 60, AttributeNames.Attribute.INT: 45,
		AttributeNames.Attribute.CHA: 33, AttributeNames.Attribute.LUK: 28,
		AttributeNames.Attribute.WIL: 15, AttributeNames.Attribute.RES: 22,
		AttributeNames.Attribute.SOU: 10
	}
	for attr in expected_values:
		assert_eq(loaded_unit.get_attribute(attr), expected_values[attr],
			"%s value matches after load" % AttributeNames.Attribute.keys()[attr])
	loaded_unit.queue_free()

func test_boundary_values_round_trip() -> void:
	var attrs: Array[int] = AttributeNames.ALL_ATTRIBUTES
	for attr in attrs:
		var comp: AttributeComponent = _unit.attributes.get_component(attr)
		comp.load_data({
			"value": 0, "potential": 3,
			"barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false},
			"thresholds_reached": {50: false, 100: false, 150: false}
		})

	var saved: Dictionary = _unit.serialize()
	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedV0"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	for attr in attrs:
		assert_eq(loaded_unit.get_attribute(attr), 0,
			"%s value=0 preserved" % AttributeNames.Attribute.keys()[attr])
	loaded_unit.queue_free()

func test_max_values_round_trip() -> void:
	var attrs: Array[int] = AttributeNames.ALL_ATTRIBUTES
	for attr in attrs:
		var comp: AttributeComponent = _unit.attributes.get_component(attr)
		comp.load_data({
			"value": 999, "potential": 6,
			"barrier_stage": 4, "barriers_broken": {1: true, 2: true, 3: true},
			"thresholds_reached": {50: true, 100: true, 150: true}
		})

	var saved: Dictionary = _unit.serialize()
	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedV999"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	for attr in attrs:
		assert_eq(loaded_unit.get_attribute(attr), 999,
			"%s value=999 preserved" % AttributeNames.Attribute.keys()[attr])
	loaded_unit.queue_free()


# AC-S2: All 9 attribute potentials round-trip

func test_potentials_round_trip() -> void:
	_setup_complex_state()
	var saved: Dictionary = _unit.serialize()

	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedPotentials"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	var expected_potentials: Dictionary = {
		AttributeNames.Attribute.STR: 4, AttributeNames.Attribute.AGI: 6,
		AttributeNames.Attribute.CON: 3, AttributeNames.Attribute.INT: 2,
		AttributeNames.Attribute.CHA: 5, AttributeNames.Attribute.LUK: 1,
		AttributeNames.Attribute.WIL: 3, AttributeNames.Attribute.RES: 4,
		AttributeNames.Attribute.SOU: 2
	}
	for attr in expected_potentials:
		assert_eq(loaded_unit.get_potential(attr), expected_potentials[attr],
			"%s potential matches after load" % AttributeNames.Attribute.keys()[attr])
	loaded_unit.queue_free()

func test_potential_boundaries_round_trip() -> void:
	var attrs: Array[int] = AttributeNames.ALL_ATTRIBUTES
	# All potentials set to S(6)
	for attr in attrs:
		var comp: AttributeComponent = _unit.attributes.get_component(attr)
		comp.load_data({
			"value": 50, "potential": 6,
			"barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false},
			"thresholds_reached": {50: false, 100: false, 150: false}
		})

	var saved: Dictionary = _unit.serialize()
	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedS"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	for attr in attrs:
		assert_eq(loaded_unit.get_potential(attr), 6,
			"%s potential=6 preserved" % AttributeNames.Attribute.keys()[attr])
	loaded_unit.queue_free()


# AC-S3: Barrier states round-trip

func test_barrier_states_round_trip() -> void:
	_setup_complex_state()
	var saved: Dictionary = _unit.serialize()

	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedBarriers"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	var comp_str: AttributeComponent = loaded_unit.attributes.get_component(AttributeNames.Attribute.STR)
	assert_eq(comp_str._barrier_stage, 2, "STR barrier_stage=2")
	assert_true(comp_str._barriers_broken[1], "STR barrier 1 broken")
	assert_false(comp_str._barriers_broken[2], "STR barrier 2 not broken")
	assert_false(comp_str._barriers_broken[3], "STR barrier 3 not broken")

	var comp_agi: AttributeComponent = loaded_unit.attributes.get_component(AttributeNames.Attribute.AGI)
	assert_eq(comp_agi._barrier_stage, 3, "AGI barrier_stage=3")
	assert_true(comp_agi._barriers_broken[1], "AGI barrier 1 broken")
	assert_true(comp_agi._barriers_broken[2], "AGI barrier 2 broken")
	assert_false(comp_agi._barriers_broken[3], "AGI barrier 3 not broken")

	var comp_con: AttributeComponent = loaded_unit.attributes.get_component(AttributeNames.Attribute.CON)
	assert_eq(comp_con._barrier_stage, 1, "CON barrier_stage=1")
	assert_false(comp_con._barriers_broken[1], "CON barrier 1 not broken")
	loaded_unit.queue_free()


# AC-S4: Threshold flags round-trip

func test_threshold_flags_round_trip() -> void:
	_setup_complex_state()
	var saved: Dictionary = _unit.serialize()

	var loaded_unit := Unit.new()
	loaded_unit.name = "LoadedThresholds"
	add_child(loaded_unit)
	loaded_unit.deserialize(saved)

	var comp_str: AttributeComponent = loaded_unit.attributes.get_component(AttributeNames.Attribute.STR)
	assert_true(comp_str._thresholds_reached[50], "STR threshold 50 reached")
	assert_false(comp_str._thresholds_reached[100], "STR threshold 100 not reached")

	var comp_int: AttributeComponent = loaded_unit.attributes.get_component(AttributeNames.Attribute.INT)
	assert_true(comp_int._thresholds_reached[50], "INT threshold 50 reached")
	assert_true(comp_int._thresholds_reached[100], "INT threshold 100 reached")
	assert_false(comp_int._thresholds_reached[150], "INT threshold 150 not reached")
	loaded_unit.queue_free()


# AC-S5: Multiple round-trips produce identical state

func test_double_round_trip_identical() -> void:
	_setup_complex_state()

	# First save
	var saved1: Dictionary = _unit.serialize()

	# First load
	var loaded1 := Unit.new()
	loaded1.name = "Loaded1"
	add_child(loaded1)
	loaded1.deserialize(saved1)

	# Second save (from loaded unit)
	var saved2: Dictionary = loaded1.serialize()

	# Second load
	var loaded2 := Unit.new()
	loaded2.name = "Loaded2"
	add_child(loaded2)
	loaded2.deserialize(saved2)

	# Compare all attributes
	var attrs: Array[int] = AttributeNames.ALL_ATTRIBUTES
	for attr in attrs:
		assert_eq(loaded2.get_attribute(attr), loaded1.get_attribute(attr),
			"%s value identical across round-trips" % AttributeNames.Attribute.keys()[attr])
		assert_eq(loaded2.get_potential(attr), loaded1.get_potential(attr),
			"%s potential identical across round-trips" % AttributeNames.Attribute.keys()[attr])

	# Compare barrier and threshold states
	for attr in attrs:
		var comp1: AttributeComponent = loaded1.attributes.get_component(attr)
		var comp2: AttributeComponent = loaded2.attributes.get_component(attr)
		assert_eq(comp2._barrier_stage, comp1._barrier_stage,
			"%s barrier_stage identical" % AttributeNames.Attribute.keys()[attr])
		assert_eq(comp2._barriers_broken, comp1._barriers_broken,
			"%s barriers_broken identical" % AttributeNames.Attribute.keys()[attr])
		assert_eq(comp2._thresholds_reached, comp1._thresholds_reached,
			"%s thresholds_reached identical" % AttributeNames.Attribute.keys()[attr])

	loaded1.queue_free()
	loaded2.queue_free()

func test_serialized_data_structure_stable() -> void:
	_setup_complex_state()
	var saved: Dictionary = _unit.serialize()

	# Verify structure contains expected keys
	assert_true("attributes" in saved, "Has attributes key")
	assert_eq(saved["unit_id"], &"save_test_char", "unit_id preserved")
	assert_eq(saved["display_name"], "", "display_name preserved")

	var attrs_data: Dictionary = saved["attributes"]
	assert_true("barrier_states" in attrs_data, "Has barrier_states key")
	# Each attribute stored by its int key
	assert_true("0" in attrs_data, "STR data present")
	assert_true("8" in attrs_data, "SOU data present")
