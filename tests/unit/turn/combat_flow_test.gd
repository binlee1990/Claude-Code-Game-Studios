# tests/unit/turn/combat_flow_test.gd
# Story 004: Combat Flow State Machine
# Validates AC-F1, AC-F2, AC-F3, AC-F4

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

func _create_unit(uid: StringName, team: int, hp: int, agi: int = 50) -> Unit:
	var unit := Unit.new()
	unit.name = "CombatUnit_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	var comp: AttributeComponent = unit.attributes.get_component(AttributeNames.Attribute.AGI)
	comp.load_data({
		"value": agi, "potential": 3, "barrier_stage": 1,
		"barriers_broken": {1: false, 2: false, 3: false}, "thresholds_reached": {}
	})
	_units.append(unit)
	_combat.register_unit(unit, team, hp)
	return unit


# --- AC-F1: Combat flow: init → order → loop → check end ---

func test_flow_init_generates_order() -> void:
	_create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	_create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	assert_eq(_combat.get_state(), CombatSystem.BattleState.UNIT_TURN)
	assert_eq(_combat.get_turn_order().size(), 2)
	assert_eq(_combat.get_current_actor().unit_id, &"p1", "Higher AGI acts first")

func test_flow_advances_through_units() -> void:
	_create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	_create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	assert_eq(_combat.get_current_actor().unit_id, &"p1")
	_combat.end_turn()
	assert_eq(_combat.get_current_actor().unit_id, &"e1")
	_combat.end_turn()
	assert_eq(_combat.get_current_turn(), 2, "Round 2 after all units act")

func test_flow_three_units_order() -> void:
	_create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	_create_unit(&"p2", CombatSystem.Team.PLAYER, 100, 60)
	_create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 40)
	_combat.start_battle("test", "map", 1)
	assert_eq(_combat.get_turn_order().size(), 3)
	assert_eq(_combat.get_current_actor().unit_id, &"p1")
	_combat.end_turn()
	assert_eq(_combat.get_current_actor().unit_id, &"p2")
	_combat.end_turn()
	assert_eq(_combat.get_current_actor().unit_id, &"e1")

func test_flow_result_none_at_start() -> void:
	_create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	_create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	assert_eq(_combat.get_result(), CombatSystem.CombatResult.NONE)


# --- AC-F2: Victory when all enemy HP=0 ---

func test_victory_all_enemies_dead() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 50, 60)
	var e2 = _create_unit(&"e2", CombatSystem.Team.ENEMY, 50, 40)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(e1, 50, p1)
	_combat.apply_damage(e2, 50, p1)
	var result = _combat.check_end_conditions()
	assert_eq(result, CombatSystem.CombatResult.VICTORY)
	assert_eq(_combat.get_state(), CombatSystem.BattleState.BATTLE_END)

func test_victory_single_enemy() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 30, 60)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(e1, 30, p1)
	assert_eq(_combat.check_end_conditions(), CombatSystem.CombatResult.VICTORY)

func test_no_victory_if_enemies_alive() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	_create_unit(&"e1", CombatSystem.Team.ENEMY, 50, 60)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(p1, 0)  # no damage to anyone
	assert_eq(_combat.check_end_conditions(), CombatSystem.CombatResult.NONE)


# --- AC-F3: Defeat when all player HP=0 ---

func test_defeat_all_players_dead() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 50, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(p1, 50, e1)
	assert_eq(_combat.check_end_conditions(), CombatSystem.CombatResult.DEFEAT)
	assert_eq(_combat.get_state(), CombatSystem.BattleState.BATTLE_END)

func test_defeat_multiple_players() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 30, 80)
	var p2 = _create_unit(&"p2", CombatSystem.Team.PLAYER, 30, 60)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 40)
	_combat.apply_damage(p1, 30, e1)
	_combat.apply_damage(p2, 30, e1)
	assert_eq(_combat.check_end_conditions(), CombatSystem.CombatResult.DEFEAT)


# --- AC-F4: Mid-action kill interrupts ---

func test_kill_current_actor_interrupts() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	assert_eq(_combat.get_current_actor().unit_id, &"p1")
	_combat.apply_damage(p1, 100, e1)
	assert_true(_combat.is_interrupted(), "Action interrupted when actor killed")
	assert_false(_combat.is_unit_alive(p1))

func test_kill_non_actor_no_interrupt() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 50, 60)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(e1, 50, p1)
	assert_false(_combat.is_interrupted(), "No interrupt when non-actor killed")

func test_clear_interrupt() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(p1, 100, e1)
	assert_true(_combat.is_interrupted())
	_combat.clear_interrupt()
	assert_false(_combat.is_interrupted())

func test_dead_units_skipped_in_advance() -> void:
	_create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	var e2 = _create_unit(&"e2", CombatSystem.Team.ENEMY, 100, 40)
	_combat.start_battle("test", "map", 1)
	_combat.apply_damage(e2, 100, _units[0])
	_combat.end_turn()
	_combat.end_turn()
	_combat.end_turn()
	assert_eq(_combat.get_current_turn(), 2, "Skips dead unit in turn order")


# --- Damage and HP ---

func test_damage_reduces_hp() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	_combat.start_battle("test", "map", 1)
	var dmg = _combat.apply_damage(e1, 30, p1)
	assert_eq(dmg, 30)
	assert_eq(_combat.get_unit_hp(e1), 70)

func test_overkill_capped_at_remaining_hp() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 20, 60)
	_combat.start_battle("test", "map", 1)
	var dmg = _combat.apply_damage(e1, 50, p1)
	assert_eq(dmg, 20, "Overkill capped")
	assert_eq(_combat.get_unit_hp(e1), 0)

func test_no_damage_to_dead_unit() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 20, 60)
	_combat.apply_damage(e1, 20, p1)
	assert_false(_combat.is_unit_alive(e1))
	var dmg = _combat.apply_damage(e1, 10, p1)
	assert_eq(dmg, 0, "No damage to dead unit")

func test_get_unit_team() -> void:
	var p1 = _create_unit(&"p1", CombatSystem.Team.PLAYER, 100, 80)
	var e1 = _create_unit(&"e1", CombatSystem.Team.ENEMY, 100, 60)
	assert_eq(_combat.get_unit_team(p1), CombatSystem.Team.PLAYER)
	assert_eq(_combat.get_unit_team(e1), CombatSystem.Team.ENEMY)
