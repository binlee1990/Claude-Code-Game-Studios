# tests/integration/turn/save_load_integration_test.gd
# Story 007: Turn-Based Save/Load Integration
# Validates AC-S1, AC-S2, AC-S3, AC-S4

extends Gut

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

var _units: Array = []
var _combat: CombatSystem
var _action: ActionSystem

func before_each() -> void:
	_combat = CombatSystem.new()
	_combat.name = "CombatSystem"
	add_child(_combat)
	_action = ActionSystem.new()
	_action.name = "ActionSystem"
	add_child(_action)

func after_each() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	if is_instance_valid(_combat):
		_combat.queue_free()
	if is_instance_valid(_action):
		_action.queue_free()

## Factory: create a Unit with a given unit_id, added to the scene tree.
func _create_unit(uid: StringName) -> Unit:
	var unit := Unit.new()
	unit.name = "TurnSaveUnit_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	_units.append(unit)
	return unit

## Build a String(unit_id) -> Unit map from an Array of Units.
func _id_map(units: Array) -> Dictionary:
	var m: Dictionary = {}
	for u in units:
		m[String(u.unit_id)] = u
	return m


# ---------------------------------------------------------------------------
# AC-S1: Turn order and current turn index saved and restored
# ---------------------------------------------------------------------------

func test_ac_s1_turn_order_round_trip() -> void:
	# Arrange — 3 units registered; turn order set manually to avoid RNG sort
	var u1: Unit = _create_unit(&"s1_a")
	var u2: Unit = _create_unit(&"s1_b")
	var u3: Unit = _create_unit(&"s1_c")
	_combat.register_unit(u1, CombatSystem.Team.PLAYER, 100)
	_combat.register_unit(u2, CombatSystem.Team.PLAYER, 100)
	_combat.register_unit(u3, CombatSystem.Team.ENEMY, 100)
	_combat.set_units([u1, u2, u3])
	# Simulate mid-battle state
	_combat._current_actor_index = 1
	_combat._current_turn = 2
	_combat._state = CombatSystem.BattleState.UNIT_TURN

	# Act
	var saved: Dictionary = _combat.serialize()
	var combat2: CombatSystem = CombatSystem.new()
	combat2.name = "CombatSystem2"
	add_child(combat2)
	combat2.deserialize(saved, _id_map([u1, u2, u3]))

	# Assert
	var order: Array = combat2.get_turn_order()
	assert_eq(order.size(), 3, "Turn order has 3 units")
	assert_eq(String(order[0].unit_id), "s1_a", "First unit matches")
	assert_eq(String(order[1].unit_id), "s1_b", "Second unit matches")
	assert_eq(String(order[2].unit_id), "s1_c", "Third unit matches")
	assert_eq(combat2._current_actor_index, 1, "current_actor_index restored")
	assert_eq(combat2.get_current_turn(), 2, "current_turn restored")

	combat2.queue_free()


# ---------------------------------------------------------------------------
# AC-S2: All unit states (HP, MP, acted status) persisted mid-battle
# ---------------------------------------------------------------------------

func test_ac_s2_unit_states_persist_mid_battle() -> void:
	# Arrange — 2 units: one alive+moved (not yet acted), one dead
	var alive: Unit = _create_unit(&"s2_alive")
	var dead: Unit = _create_unit(&"s2_dead")
	_combat.register_unit(alive, CombatSystem.Team.PLAYER, 100)
	_combat.register_unit(dead, CombatSystem.Team.ENEMY, 80)
	# Set mid-battle HP directly
	_combat._combat_units[alive]["hp"] = 75
	_combat._combat_units[dead]["hp"] = 0
	_combat._combat_units[dead]["is_alive"] = false

	_action.initialize([alive, dead], {
		alive: {"max_mp": 100, "skill_costs": [20]},
		dead:  {"max_mp": 60,  "skill_costs": []},
	})
	_action.execute_action(alive, ActionSystem.ActionType.MOVE)
	_action._unit_data[alive]["current_mp"] = 55

	# Act — serialize both systems, restore into fresh nodes
	var combat_data: Dictionary = _combat.serialize()
	var action_data: Dictionary = _action.serialize()

	var combat2: CombatSystem = CombatSystem.new()
	combat2.name = "CombatSystem2"
	add_child(combat2)
	var action2: ActionSystem = ActionSystem.new()
	action2.name = "ActionSystem2"
	add_child(action2)

	var all_units: Array = [alive, dead]
	combat2.deserialize(combat_data, _id_map(all_units))
	action2.initialize(all_units)
	action2.deserialize(action_data)

	# Assert — CombatSystem unit states
	assert_eq(combat2.get_unit_hp(alive), 75, "alive HP restored")
	assert_true(combat2.is_unit_alive(alive), "alive unit is alive")
	assert_eq(combat2.get_unit_hp(dead), 0, "dead HP = 0")
	assert_false(combat2.is_unit_alive(dead), "dead unit is not alive")

	# Assert — ActionSystem unit states
	assert_true(action2._unit_data[alive]["has_moved"], "has_moved restored")
	assert_false(action2._unit_data[alive]["has_acted"], "has_acted = false (only moved)")
	assert_eq(action2.get_current_mp(alive), 55, "current_mp restored")
	assert_eq(action2.get_max_mp(alive), 100, "max_mp restored")

	combat2.queue_free()
	action2.queue_free()


# ---------------------------------------------------------------------------
# AC-S3: Auto-battle and speed settings survive round-trip
# ---------------------------------------------------------------------------

func test_ac_s3_auto_battle_setting_round_trip() -> void:
	# Arrange
	var brain: AIBrain = AIBrain.new(AI.AIType.BALANCED)
	var abc: AutoBattleController = AutoBattleController.new(brain)
	abc.set_enabled(true)

	# Act
	var saved: Dictionary = abc.serialize()
	var abc2: AutoBattleController = AutoBattleController.new(brain)
	abc2.deserialize(saved)

	# Assert
	assert_true(abc2.is_enabled(), "auto-battle enabled=true restored")

func test_ac_s3_speed_tier_round_trip() -> void:
	# Arrange
	var sc: SpeedController = SpeedController.new()
	sc.set_tier(SpeedController.SpeedTier.FAST)

	# Act
	var saved: Dictionary = sc.serialize()
	var sc2: SpeedController = SpeedController.new()
	sc2.deserialize(saved)

	# Assert
	assert_eq(sc2.get_tier(), SpeedController.SpeedTier.FAST, "FAST tier restored")

func test_ac_s3_speed_tier_max_round_trip() -> void:
	# Arrange
	var sc: SpeedController = SpeedController.new()
	sc.set_tier(SpeedController.SpeedTier.MAX)

	# Act
	var saved: Dictionary = sc.serialize()
	var sc2: SpeedController = SpeedController.new()
	sc2.deserialize(saved)

	# Assert
	assert_eq(sc2.get_tier(), SpeedController.SpeedTier.MAX, "MAX tier restored")


# ---------------------------------------------------------------------------
# AC-S4: Multiple save/load cycles produce identical battle state
# ---------------------------------------------------------------------------

func test_ac_s4_double_round_trip_identical() -> void:
	# Arrange — 4 units mid-battle
	var ua: Unit = _create_unit(&"s4_a")
	var ub: Unit = _create_unit(&"s4_b")
	var uc: Unit = _create_unit(&"s4_c")
	var ud: Unit = _create_unit(&"s4_d")
	for u in [ua, ub, uc, ud]:
		_combat.register_unit(u, CombatSystem.Team.PLAYER, 100)
	_combat.set_units([ua, ub, uc, ud])
	_combat._current_actor_index = 2
	_combat._current_turn = 3
	_combat._combat_units[uc]["hp"] = 40
	_combat._combat_units[ud]["hp"] = 0
	_combat._combat_units[ud]["is_alive"] = false

	var all_units: Array = [ua, ub, uc, ud]
	var imap: Dictionary = _id_map(all_units)

	# First save -> load
	var saved1: Dictionary = _combat.serialize()
	var combat_load1: CombatSystem = CombatSystem.new()
	combat_load1.name = "CombatLoad1"
	add_child(combat_load1)
	combat_load1.deserialize(saved1, imap)

	# Second save (from first load) -> load
	var saved2: Dictionary = combat_load1.serialize()
	var combat_load2: CombatSystem = CombatSystem.new()
	combat_load2.name = "CombatLoad2"
	add_child(combat_load2)
	combat_load2.deserialize(saved2, imap)

	# Assert — load2 state matches load1 state
	assert_eq(combat_load2.get_current_turn(), combat_load1.get_current_turn(),
		"current_turn identical after double round-trip")
	assert_eq(combat_load2._current_actor_index, combat_load1._current_actor_index,
		"current_actor_index identical")
	assert_eq(combat_load2.get_unit_hp(uc), combat_load1.get_unit_hp(uc),
		"unit HP identical")
	assert_eq(combat_load2.is_unit_alive(ud), combat_load1.is_unit_alive(ud),
		"dead unit status identical")
	var order1: Array = combat_load1.get_turn_order()
	var order2: Array = combat_load2.get_turn_order()
	assert_eq(order2.size(), order1.size(), "turn order size identical")
	for i in order1.size():
		assert_eq(String(order2[i].unit_id), String(order1[i].unit_id),
			"turn order[%d] unit_id identical" % i)

	combat_load1.queue_free()
	combat_load2.queue_free()

func test_ac_s4_double_round_trip_auto_battle() -> void:
	# Arrange — auto-battle ON + speed MAX
	var brain: AIBrain = AIBrain.new(AI.AIType.BALANCED)
	var abc: AutoBattleController = AutoBattleController.new(brain)
	abc.set_enabled(true)
	var sc: SpeedController = SpeedController.new()
	sc.set_tier(SpeedController.SpeedTier.MAX)

	# First save -> load
	var abc_data1: Dictionary = abc.serialize()
	var sc_data1: Dictionary = sc.serialize()
	var abc2: AutoBattleController = AutoBattleController.new(brain)
	var sc2: SpeedController = SpeedController.new()
	abc2.deserialize(abc_data1)
	sc2.deserialize(sc_data1)

	# Second save -> load
	var abc_data2: Dictionary = abc2.serialize()
	var sc_data2: Dictionary = sc2.serialize()
	var abc3: AutoBattleController = AutoBattleController.new(brain)
	var sc3: SpeedController = SpeedController.new()
	abc3.deserialize(abc_data2)
	sc3.deserialize(sc_data2)

	# Assert — final state matches after both round-trips
	assert_true(abc3.is_enabled(), "auto-battle still enabled after double round-trip")
	assert_eq(sc3.get_tier(), SpeedController.SpeedTier.MAX,
		"speed MAX preserved after double round-trip")


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_deserialize_invalid_speed_tier_falls_back_to_normal() -> void:
	# Arrange
	var sc: SpeedController = SpeedController.new()
	sc.set_tier(SpeedController.SpeedTier.FAST)

	# Act — inject an out-of-range tier value
	sc.deserialize({"tier": 99})

	# Assert
	assert_eq(sc.get_tier(), SpeedController.SpeedTier.NORMAL,
		"Invalid tier 99 falls back to NORMAL")

func test_deserialize_unknown_unit_ids_skipped() -> void:
	# Arrange — serialize a combat with 2 units, then deserialize with only 1 in the map
	var u1: Unit = _create_unit(&"known")
	var u2: Unit = _create_unit(&"unknown")
	_combat.register_unit(u1, CombatSystem.Team.PLAYER, 100)
	_combat.register_unit(u2, CombatSystem.Team.ENEMY, 80)
	_combat.set_units([u1, u2])

	var saved: Dictionary = _combat.serialize()

	# id_to_unit map intentionally omits u2
	var partial_map: Dictionary = {String(u1.unit_id): u1}
	var combat2: CombatSystem = CombatSystem.new()
	combat2.name = "CombatPartial"
	add_child(combat2)
	combat2.deserialize(saved, partial_map)

	# Assert — only known unit present
	assert_eq(combat2._combat_units.size(), 1, "Only 1 unit in combat_units (unknown skipped)")
	assert_true(combat2._combat_units.has(u1), "Known unit u1 is present")
	assert_false(combat2._combat_units.has(u2), "Unknown unit u2 is absent")

	combat2.queue_free()

func test_auto_battle_deserialize_clears_manual_overrides() -> void:
	# Arrange — set an override, then serialize+deserialize
	var brain: AIBrain = AIBrain.new(AI.AIType.BALANCED)
	var abc: AutoBattleController = AutoBattleController.new(brain)
	abc.set_enabled(true)
	var unit: Unit = _create_unit(&"override_unit")
	abc.request_manual_override(unit)
	assert_false(abc.should_auto_control(unit), "Override active before deserialize")

	# Act — round-trip
	var saved: Dictionary = abc.serialize()
	var abc2: AutoBattleController = AutoBattleController.new(brain)
	abc2.deserialize(saved)

	# Assert — overrides not present on fresh instance (they were never persisted)
	assert_eq(abc2._manual_overrides.size(), 0, "Manual overrides cleared after deserialize")
	# Also confirm enabled flag came through
	assert_true(abc2.is_enabled(), "enabled=true still restored")
