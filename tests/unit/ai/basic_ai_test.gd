extends RefCounted

const ActionType = preload("res://src/ai/action_type.gd")
const BasicAI = preload("res://src/ai/basic_ai.gd")

var _ai: BasicAI
var _map: Map
var _grid_space: GridSpace

func before() -> void:
	_ai = BasicAI.new()
	_grid_space = GridSpace.new()
	_map = Map.new()
	_map.grid_space = _grid_space
	_make_open_map(6, 6)

func _make_open_map(rows: int, cols: int) -> void:
	_map._rows = rows
	_map._cols = cols
	for r in range(rows):
		for c in range(cols):
			_map._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(faction: Faction.Type, pos: Vector2i, mov: int = 3, rng: int = 1, hp: int = 10) -> Unit:
	var stats := UnitStats.new()
	stats.mov = mov
	stats.rng = rng
	stats.max_hp = hp
	var unit := Unit.new()
	unit.initialize(stats, faction)
	_map.place_unit(unit, pos)
	return unit

func _make_world_state(units: Array) -> WorldState:
	var world_state := WorldState.new()
	world_state.all_units = units
	world_state.map = _map
	for unit in units:
		if is_instance_valid(unit) and unit.is_alive():
			world_state._occupancy_snapshot[unit.grid_position] = unit
	return world_state

func test_basic_ai_extends_ai_controller() -> void:
	assert(_ai is AIController)

func test_basic_ai_attacks_direct_target_without_moving() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 2))
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 3))
	var result := _ai.take_turn([enemy], _make_world_state([enemy, player]))

	assert(result.size() == 1)
	var plan: ActionPlan = result.get_actions()[0]
	assert(plan.unit == enemy)
	assert(plan.type == ActionType.ATTACK_ONLY)
	assert(plan.move_target == enemy.grid_position)
	assert(plan.attack_target == player)

func test_basic_ai_moves_into_range_and_attacks_nearest_target() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 0), 3, 1)
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 4))
	var result := _ai.take_turn([enemy], _make_world_state([enemy, player]))

	assert(result.size() == 1)
	var plan: ActionPlan = result.get_actions()[0]
	assert(plan.type == ActionType.MOVE_AND_ATTACK)
	assert(plan.move_target == Vector2i(2, 3))
	assert(plan.attack_target == player)

func test_basic_ai_moves_toward_nearest_target_when_attack_unreachable() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(0, 0), 2, 1)
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(5, 5))
	var result := _ai.take_turn([enemy], _make_world_state([enemy, player]))

	assert(result.size() == 1)
	var plan: ActionPlan = result.get_actions()[0]
	assert(plan.type == ActionType.MOVE_ONLY)
	assert(plan.move_target == Vector2i(0, 2) or plan.move_target == Vector2i(2, 0))
	assert(plan.attack_target == null)

func test_basic_ai_waits_when_no_enemy_targets_exist() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 2))
	var ally := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3))
	var result := _ai.take_turn([enemy], _make_world_state([enemy, ally]))

	assert(result.size() == 1)
	var plan: ActionPlan = result.get_actions()[0]
	assert(plan.type == ActionType.WAIT)
	assert(plan.move_target == enemy.grid_position)
	assert(plan.attack_target == null)

func test_basic_ai_waits_when_world_state_missing_map() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 2))
	var result := _ai.take_turn([enemy], null)

	assert(result.size() == 1)
	var plan: ActionPlan = result.get_actions()[0]
	assert(plan.type == ActionType.WAIT)

func test_basic_ai_does_not_import_turn_manager() -> void:
	var file := FileAccess.open("res://src/ai/basic_ai.gd", FileAccess.READ)
	assert(file != null)
	var source := file.get_as_text()

	assert(source.find("TurnManager") == -1)
	assert(source.find("turn_manager") == -1)

func test_basic_ai_does_not_mutate_world_state() -> void:
	var enemy := _make_unit(Faction.Type.ENEMY, Vector2i(2, 0), 3, 1)
	var player := _make_unit(Faction.Type.PLAYER, Vector2i(2, 4))
	var world_state := _make_world_state([enemy, player])
	var before_units := world_state.all_units.duplicate()
	var before_snapshot := world_state._occupancy_snapshot.duplicate()

	_ai.take_turn([enemy], world_state)

	assert(world_state.all_units == before_units)
	assert(world_state._occupancy_snapshot == before_snapshot)
