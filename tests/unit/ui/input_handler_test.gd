extends RefCounted

const InputHandler = preload("res://src/ui/input_handler.gd")
const TurnState = preload("res://src/core/turn_state.gd")
const UnitState = preload("res://src/core/unit_state.gd")

var _handler: InputHandler
var _gs: GridSpace
var _mp: Map
var _tm: TurnManager
var _mov_res: MovementResolver
var _atk_res: AttackResolver
var _atk_rng: AttackRangeResolver
var _units: Array

func before() -> void:
	_handler = InputHandler.new()
	_gs = GridSpace.new()
	_mp = Map.new()
	_mp.grid_space = _gs
	_setup_map_5by5()
	_tm = TurnManager.new()
	_tm.initialize([], TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	_mov_res = MovementResolver.new()
	_atk_res = AttackResolver.new()
	_atk_rng = AttackRangeResolver.new()
	_units = []
	_handler.initialize(_mp, _gs, _tm, _mov_res, _atk_res, _atk_rng, _units)

func _setup_map_5by5() -> void:
	_mp._rows = 5
	_mp._cols = 5
	for r in range(5):
		for c in range(5):
			_mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(hp: int, atk: int, def: int, mov: int, rng: int, faction: Faction.Type) -> Unit:
	var s := UnitStats.new()
	s.max_hp = hp; s.atk = atk; s.def = def; s.mov = mov; s.rng = rng
	var u := Unit.new()
	u.initialize(s, faction)
	u.hp = hp
	return u

func _make_click_event(x: float, y: float) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = Vector2(x, y)
	return e

func _make_escape_event() -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	return e

func _start_match() -> void:
	_tm.current_state = TurnState.FACTION_PHASE_ACTIVE
	_tm.active_faction = Faction.Type.PLAYER
	_tm.turn_number = 1

# === MUST HAVE TESTS (≥5) ===

func test_board_idle_click_player_unit_selects() -> void:
	var u := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	u.grid_position = Vector2i(2, 2)
	_mp.place_unit(u, Vector2i(2, 2))
	_units.append(u)
	_start_match()

	var ev := _make_click_event(_gs.tile_center(Vector2i(2, 2)).x, _gs.tile_center(Vector2i(2, 2)).y)
	_handler.handle_event(ev)

	assert(_handler.get_context() == InputHandler.InputContext.UNIT_SELECTED)
	assert(_handler.get_selected_unit() == u)
	assert(u.action_state == UnitState.SELECTED)

func test_board_idle_click_enemy_unit_ignored() -> void:
	var p := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	p.grid_position = Vector2i(1, 1)
	_mp.place_unit(p, Vector2i(1, 1))
	var e := _make_unit(10, 5, 2, 3, 2, Faction.Type.ENEMY)
	e.grid_position = Vector2i(2, 2)
	_mp.place_unit(e, Vector2i(2, 2))
	_units.append_array([p, e])
	_start_match()

	var ev := _make_click_event(_gs.tile_center(Vector2i(2, 2)).x, _gs.tile_center(Vector2i(2, 2)).y)
	_handler.handle_event(ev)

	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)
	assert(_handler.get_selected_unit() == null)

func test_board_idle_click_empty_tile_ignored() -> void:
	var u := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	u.grid_position = Vector2i(1, 1)
	_mp.place_unit(u, Vector2i(1, 1))
	_units.append(u)
	_start_match()

	var ev := _make_click_event(_gs.tile_center(Vector2i(3, 3)).x, _gs.tile_center(Vector2i(3, 3)).y)
	_handler.handle_event(ev)

	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)
	assert(_handler.get_selected_unit() == null)

func test_unit_selected_escape_deselects() -> void:
	var u := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	u.grid_position = Vector2i(2, 2)
	_mp.place_unit(u, Vector2i(2, 2))
	_units.append(u)
	_start_match()

	# Select first
	var click := _make_click_event(_gs.tile_center(Vector2i(2, 2)).x, _gs.tile_center(Vector2i(2, 2)).y)
	_handler.handle_event(click)
	assert(_handler.get_context() == InputHandler.InputContext.UNIT_SELECTED)

	# Escape → deselect
	_handler.handle_event(_make_escape_event())
	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)
	assert(_handler.get_selected_unit() == null)
	assert(u.action_state == UnitState.IDLE)

func test_click_out_of_bounds_ignored() -> void:
	_start_match()
	var top_right := _make_click_event(_gs.tile_center(Vector2i(4, 4)).x + 100.0, _gs.tile_center(Vector2i(4, 4)).y + 100.0)
	_handler.handle_event(top_right)
	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)

# === BONUS TESTS ===

func test_event_ignored_when_not_active_phase() -> void:
	var u := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	u.grid_position = Vector2i(2, 2)
	_mp.place_unit(u, Vector2i(2, 2))
	_units.append(u)
	_start_match()
	_tm.current_state = TurnState.FACTION_PHASE_ENDING

	var ev := _make_click_event(_gs.tile_center(Vector2i(2, 2)).x, _gs.tile_center(Vector2i(2, 2)).y)
	_handler.handle_event(ev)
	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)

func test_force_clear_resets_state() -> void:
	var u := _make_unit(10, 5, 2, 3, 2, Faction.Type.PLAYER)
	u.grid_position = Vector2i(2, 2)
	_mp.place_unit(u, Vector2i(2, 2))
	_units.append(u)
	_start_match()

	var ev := _make_click_event(_gs.tile_center(Vector2i(2, 2)).x, _gs.tile_center(Vector2i(2, 2)).y)
	_handler.handle_event(ev)
	assert(_handler.get_context() == InputHandler.InputContext.UNIT_SELECTED)

	_handler.force_clear()
	assert(_handler.get_context() == InputHandler.InputContext.BOARD_IDLE)
	assert(_handler.get_selected_unit() == null)
