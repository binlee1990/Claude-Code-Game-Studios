# tests/unit/turn/turn_order_test.gd
# Story 001: Turn Order & Speed Sequence
# Validates AC.1.1, AC.1.2, AC.1.3

extends Gut

var _combat: CombatSystem
var _units: Array = []

func before_each() -> void:
	_combat = CombatSystem.new()
	_combat.name = "CombatSystem"
	add_child(_combat)

func after_each() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	if is_instance_valid(_combat):
		_combat.queue_free()

func _create_unit(agi_value: int, uid: StringName = &"") -> Unit:
	var unit := Unit.new()
	unit.name = "Unit_" + str(agi_value) + "_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	var comp: AttributeComponent = unit.attributes.get_component(AttributeNames.Attribute.AGI)
	comp.load_data({
		"value": agi_value,
		"potential": 3,
		"barrier_stage": 1,
		"barriers_broken": {1: false, 2: false, 3: false},
		"thresholds_reached": {}
	})
	_units.append(unit)
	return unit


# --- AC.1.1: Sort by AGI descending ---

func test_agi_descending_four_units() -> void:
	var u1 = _create_unit(40, &"slow")
	var u2 = _create_unit(100, &"fast")
	var u3 = _create_unit(80, &"medium")
	var u4 = _create_unit(60, &"medslow")
	_combat.set_units([u1, u2, u3, u4])
	_combat._calculate_turn_order()
	var order = _combat.get_turn_order()
	assert_eq(order[0].unit_id, &"fast", "AGI 100 first")
	assert_eq(order[1].unit_id, &"medium", "AGI 80 second")
	assert_eq(order[2].unit_id, &"medslow", "AGI 60 third")
	assert_eq(order[3].unit_id, &"slow", "AGI 40 last")

func test_agi_descending_two_units() -> void:
	var u1 = _create_unit(50, &"slower")
	var u2 = _create_unit(90, &"faster")
	_combat.set_units([u1, u2])
	_combat._calculate_turn_order()
	var order = _combat.get_turn_order()
	assert_eq(order[0].unit_id, &"faster")
	assert_eq(order[1].unit_id, &"slower")

func test_single_unit_order() -> void:
	var u = _create_unit(75, &"solo")
	_combat.set_units([u])
	_combat._calculate_turn_order()
	var order = _combat.get_turn_order()
	assert_eq(order.size(), 1)
	assert_eq(order[0].unit_id, &"solo")

func test_empty_units_no_crash() -> void:
	_combat.set_units([])
	_combat._calculate_turn_order()
	assert_eq(_combat.get_turn_order().size(), 0, "Empty order for no units")

func test_start_battle_generates_order() -> void:
	var u1 = _create_unit(60, &"a")
	var u2 = _create_unit(90, &"b")
	_combat.set_units([u1, u2])
	_combat.start_battle("test_battle", "test_map", 1)
	var order = _combat.get_turn_order()
	assert_eq(order.size(), 2)
	assert_eq(order[0].unit_id, &"b", "Higher AGI first after start_battle")
	assert_eq(_combat.get_current_turn(), 1, "Round starts at 1")


# --- AC.1.2: Same AGI random tie-break ---

func test_same_agi_two_units_random_order() -> void:
	var u1 = _create_unit(80, &"a")
	var u2 = _create_unit(80, &"b")
	_combat.set_units([u1, u2])
	var saw_ab := false
	var saw_ba := false
	for i in range(1000):
		_combat._calculate_turn_order()
		var order = _combat.get_turn_order()
		if order[0].unit_id == &"a":
			saw_ab = true
		else:
			saw_ba = true
		if saw_ab and saw_ba:
			break
	assert_true(saw_ab, "Order [a, b] should appear")
	assert_true(saw_ba, "Order [b, a] should appear")

func test_same_agi_three_units_varied_orders() -> void:
	var u1 = _create_unit(80, &"a")
	var u2 = _create_unit(80, &"b")
	var u3 = _create_unit(80, &"c")
	_combat.set_units([u1, u2, u3])
	var found_orders: Dictionary = {}
	for i in range(1000):
		_combat._calculate_turn_order()
		var order = _combat.get_turn_order()
		var key = str(order[0].unit_id) + "," + str(order[1].unit_id) + "," + str(order[2].unit_id)
		found_orders[key] = true
		if found_orders.size() >= 3:
			break
	assert_true(found_orders.size() >= 2, "Should see multiple orderings of same-AGI units")

func test_mixed_agi_same_agi_partial_random() -> void:
	var u1 = _create_unit(100, &"fast")
	var u2 = _create_unit(80, &"a")
	var u3 = _create_unit(80, &"b")
	var u4 = _create_unit(60, &"slow")
	_combat.set_units([u1, u2, u3, u4])
	_combat._calculate_turn_order()
	var order = _combat.get_turn_order()
	assert_eq(order[0].unit_id, &"fast", "AGI 100 always first")
	assert_eq(order[3].unit_id, &"slow", "AGI 60 always last")
	assert_true(order[1].unit_id in [&"a", &"b"])
	assert_true(order[2].unit_id in [&"a", &"b"])
	assert_ne(order[1].unit_id, order[2].unit_id, "Middle units are different")


# --- AC.1.3: Re-sort after all units act ---

func test_resort_after_round_complete() -> void:
	var u1 = _create_unit(80, &"a")
	var u2 = _create_unit(80, &"b")
	_combat.set_units([u1, u2])
	_combat.start_battle("test", "map", 1)
	_combat.end_turn()
	_combat.end_turn()
	assert_eq(_combat.get_current_turn(), 2, "Should be round 2 after all units act")
	assert_eq(_combat.get_turn_order().size(), 2, "Order still has 2 units")

func test_resort_maintains_agi_order_different_agi() -> void:
	var u1 = _create_unit(40, &"slow")
	var u2 = _create_unit(100, &"fast")
	var u3 = _create_unit(60, &"medium")
	_combat.set_units([u1, u2, u3])
	_combat.start_battle("test", "map", 1)
	_combat.end_turn()
	_combat.end_turn()
	_combat.end_turn()
	assert_eq(_combat.get_current_turn(), 2, "Should be round 2")
	var order = _combat.get_turn_order()
	assert_eq(order[0].unit_id, &"fast", "AGI order maintained after re-sort")
	assert_eq(order[1].unit_id, &"medium", "AGI order maintained after re-sort")
	assert_eq(order[2].unit_id, &"slow", "AGI order maintained after re-sort")

func test_resort_same_agi_re_randomizes() -> void:
	var u1 = _create_unit(80, &"a")
	var u2 = _create_unit(80, &"b")
	_combat.set_units([u1, u2])
	_combat.start_battle("test", "map", 1)
	var saw_variation := false
	var prev_key := ""
	for _round_i in range(100):
		var key = str(_combat.get_turn_order()[0].unit_id)
		if prev_key != "" and key != prev_key:
			saw_variation = true
			break
		prev_key = key
		_combat.end_turn()
		_combat.end_turn()
	assert_true(saw_variation, "Same-AGI units should re-randomize across rounds")
