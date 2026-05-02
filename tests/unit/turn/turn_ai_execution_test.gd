extends RefCounted

const ActionType = preload("res://src/ai/action_type.gd")

class ScriptedAI:
	extends AIController

	var actions: ActionList
	var received_units: Array = []
	var received_world_state: WorldState

	func _init(p_actions: ActionList) -> void:
		actions = p_actions

	func take_turn(units: Array, world_state: WorldState) -> ActionList:
		received_units = units.duplicate()
		received_world_state = world_state
		return actions

var _map: Map
var _attack_resolver: AttackResolver

func before() -> void:
	_map = Map.new()
	_map.grid_space = GridSpace.new()
	_map.emit_warnings = false
	_attack_resolver = AttackResolver.new()
	_make_open_map(6, 6)

func _make_open_map(rows: int, cols: int) -> void:
	_map._rows = rows
	_map._cols = cols
	for r in range(rows):
		for c in range(cols):
			_map._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(
	faction: Faction.Type,
	pos: Vector2i,
	mov: int = 3,
	rng: int = 1,
	hp: int = 10,
	atk: int = 5,
	def: int = 2,
) -> Unit:
	var stats := UnitStats.new()
	stats.mov = mov
	stats.rng = rng
	stats.max_hp = hp
	stats.atk = atk
	stats.def = def
	var unit := Unit.new()
	unit.initialize(stats, faction)
	_map.place_unit(unit, pos)
	return unit

func _make_turn_manager(units: Array, ai: AIController) -> TurnManager:
	var turn_manager := TurnManager.new()
	turn_manager.emit_warnings = false
	turn_manager.initialize(units, TurnConfig.new(), VictoryChecker.new(), ai, _map, _attack_resolver)
	return turn_manager

func test_null_ai_preserves_enemy_hotseat_phase() -> void:
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2))
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 4))
	var turn_manager := _make_turn_manager([player, enemy], NullAI.new())

	turn_manager.start_match()
	turn_manager.end_current_faction_turn()

	assert(turn_manager.active_faction == Faction.Type.ENEMY)
	assert(not enemy.has_acted_this_turn)
	assert(enemy.grid_position == Vector2i(2, 4))

func test_basic_ai_executes_move_and_attack_then_advances() -> void:
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 4), 3, 1, 10, 5, 1)
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 0), 3, 1, 10, 5, 1)
	var turn_manager := _make_turn_manager([player, enemy], BasicAI.new())

	turn_manager.start_match()
	turn_manager.end_current_faction_turn()

	assert(enemy.grid_position == Vector2i(2, 3))
	assert(player.hp == 6)
	assert(enemy.has_acted_this_turn)
	assert(turn_manager.active_faction == Faction.Type.PLAYER)
	assert(turn_manager.turn_number == 2)

func test_ai_receives_only_active_alive_units_and_world_state() -> void:
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(1, 1))
	var enemy_ready := _make_unit(Faction.Type.ENEMY, Vector2i(2, 2))
	var enemy_dead := _make_unit(Faction.Type.ENEMY, Vector2i(3, 3))
	enemy_dead.take_damage(enemy_dead.hp)
	var ai := ScriptedAI.new(ActionList.new())
	var turn_manager := _make_turn_manager([player, enemy_ready, enemy_dead], ai)

	turn_manager.start_match()
	turn_manager.end_current_faction_turn()

	assert(ai.received_units.size() == 1)
	assert(ai.received_units[0] == enemy_ready)
	assert(ai.received_world_state.map == _map)
	assert(player in ai.received_world_state.all_units)
	assert(enemy_ready in ai.received_world_state.all_units)
	assert(not (enemy_dead in ai.received_world_state.all_units))

func test_ai_plan_for_wrong_faction_is_rejected_without_mutating_player() -> void:
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2))
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 4))
	var actions := ActionList.new()
	actions.add(ActionPlan.new(player, ActionType.MOVE_ONLY, Vector2i(2, 3), null))
	var turn_manager := _make_turn_manager([player, enemy], ScriptedAI.new(actions))

	turn_manager.start_match()
	turn_manager.end_current_faction_turn()

	assert(turn_manager.active_faction == Faction.Type.ENEMY)
	assert(player.grid_position == Vector2i(2, 2))
	assert(not player.has_acted_this_turn)
	assert(not enemy.has_acted_this_turn)
