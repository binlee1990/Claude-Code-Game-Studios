extends RefCounted

const MovementResolver = preload("res://src/movement/movement_resolver.gd")

var resolver: MovementResolver
var gs: GridSpace
var mp: Map

func before() -> void:
	resolver = MovementResolver.new()
	gs = GridSpace.new()
	mp = Map.new()
	mp.grid_space = gs
	mp.emit_warnings = false

func _make_open_map(rows: int, cols: int) -> void:
	mp._rows = rows
	mp._cols = cols
	for r in range(rows):
		for c in range(cols):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(faction: Faction.Type, pos: Vector2i, mov: int = 4) -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	stats.mov = mov
	u.initialize(stats, faction)
	u.grid_position = pos
	return u

func test_move_unit_atomic_success() -> void:
	_make_open_map(5, 5)
	var u := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	mp.place_unit(u, Vector2i(0, 0))
	var ok := mp.move_unit(u, Vector2i(0, 0), Vector2i(0, 1))
	assert(ok, "move_unit should succeed")
	assert(u.grid_position == Vector2i(0, 1))
	assert(mp.get_unit_at(Vector2i(0, 0)) == null)
	assert(mp.get_unit_at(Vector2i(0, 1)) == u)

func test_move_unit_occupancy_consistent() -> void:
	_make_open_map(5, 5)
	var a := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	var b := _make_unit(Faction.Type.PLAYER, Vector2i(1, 0))
	mp.place_unit(a, Vector2i(0, 0))
	mp.place_unit(b, Vector2i(1, 0))
	mp.move_unit(a, Vector2i(0, 0), Vector2i(0, 2))
	assert(mp.get_unit_at(Vector2i(0, 0)) == null)
	assert(mp.get_unit_at(Vector2i(0, 2)) == a)
	assert(mp.get_unit_at(Vector2i(1, 0)) == b)

func test_move_to_blocked_tile_rejected() -> void:
	_make_open_map(5, 5)
	mp._tile_states[Vector2i(0, 1)] = Map.TileState.BLOCKED
	var u := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	mp.place_unit(u, Vector2i(0, 0))
	var ok := mp.move_unit(u, Vector2i(0, 0), Vector2i(0, 1))
	assert(not ok, "move to blocked tile must be rejected")
	assert(u.grid_position == Vector2i(0, 0))

func test_move_to_occupied_tile_rejected() -> void:
	_make_open_map(5, 5)
	var a := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	var b := _make_unit(Faction.Type.ENEMY, Vector2i(0, 1))
	mp.place_unit(a, Vector2i(0, 0))
	mp.place_unit(b, Vector2i(0, 1))
	var ok := mp.move_unit(a, Vector2i(0, 0), Vector2i(0, 1))
	assert(not ok, "cannot move onto occupied tile")
	assert(a.grid_position == Vector2i(0, 0))

func test_move_unit_state_transition() -> void:
	_make_open_map(5, 5)
	var u := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	mp.place_unit(u, Vector2i(0, 0))
	u.action_state = Unit.UnitState.SELECTED
	mp.move_unit(u, Vector2i(0, 0), Vector2i(0, 2))
	u.action_state = Unit.UnitState.MOVED
	assert(u.action_state == Unit.UnitState.MOVED)

func test_move_from_wrong_position_rejected() -> void:
	_make_open_map(5, 5)
	var u := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	mp.place_unit(u, Vector2i(0, 0))
	var ok := mp.move_unit(u, Vector2i(1, 0), Vector2i(0, 1))
	assert(not ok, "unit not at claimed from-position")

func test_move_unit_out_of_bounds_rejected() -> void:
	_make_open_map(3, 3)
	var u := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0))
	mp.place_unit(u, Vector2i(0, 0))
	var ok := mp.move_unit(u, Vector2i(0, 0), Vector2i(-1, 0))
	assert(not ok)
