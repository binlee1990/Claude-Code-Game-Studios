# Story map/004: Occupancy tracking — place/remove/move tests
# TR-map-003, TR-map-006, TR-map-009 | ADR-0005

var _map: Map
var _unit: Unit
var _stats: UnitStats

func before() -> void:
	_map = Map.new()
	_map.initialize(GridSpace.new(), "test_map")
	_stats = UnitStats.new()
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)

func after() -> void:
	if is_instance_valid(_unit):
		_unit.free()
	if is_instance_valid(_map):
		_map.free()

func test_place_unit_on_walkable_empty_tile_succeeds() -> void:
	assert(_map.place_unit(_unit, Vector2i(0, 0)))
	assert(_unit.grid_position == Vector2i(0, 0))

func test_place_unit_on_blocked_tile_fails() -> void:
	assert(not _map.place_unit(_unit, Vector2i(2, 4)))

func test_place_unit_on_out_of_bounds_tile_fails() -> void:
	assert(not _map.place_unit(_unit, Vector2i(-1, 0)))

func test_place_unit_on_occupied_tile_fails() -> void:
	var u2 := Unit.new()
	u2.initialize(_stats, Faction.Type.ENEMY)
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(not _map.place_unit(u2, Vector2i(0, 0)))
	assert(u2.grid_position != Vector2i(0, 0))

func test_is_walkable_after_place_unit_returns_false() -> void:
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(not _map.is_walkable(Vector2i(0, 0)))

func test_get_unit_at_occupied_tile_returns_unit() -> void:
	_map.place_unit(_unit, Vector2i(3, 3))
	assert(_map.get_unit_at(Vector2i(3, 3)) == _unit)

func test_get_unit_at_empty_tile_returns_null() -> void:
	assert(_map.get_unit_at(Vector2i(0, 0)) == null)

func test_remove_unit_on_occupied_tile_succeeds() -> void:
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(_map.remove_unit(Vector2i(0, 0)))
	assert(_map.get_unit_at(Vector2i(0, 0)) == null)

func test_remove_unit_on_empty_tile_returns_false() -> void:
	assert(not _map.remove_unit(Vector2i(5, 5)))

func test_move_unit_valid_from_to_succeeds() -> void:
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(_map.move_unit(_unit, Vector2i(0, 0), Vector2i(1, 0)))
	assert(_unit.grid_position == Vector2i(1, 0))
	assert(_map.get_unit_at(Vector2i(0, 0)) == null)
	assert(_map.get_unit_at(Vector2i(1, 0)) == _unit)

func test_move_unit_wrong_from_fails() -> void:
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(not _map.move_unit(_unit, Vector2i(5, 5), Vector2i(6, 5)))
	assert(_unit.grid_position == Vector2i(0, 0))

func test_move_unit_occupied_to_fails() -> void:
	var u2 := Unit.new()
	u2.initialize(_stats, Faction.Type.ENEMY)
	_map.place_unit(_unit, Vector2i(0, 0))
	_map.place_unit(u2, Vector2i(1, 0))
	assert(not _map.move_unit(_unit, Vector2i(0, 0), Vector2i(1, 0)))
	assert(_unit.grid_position == Vector2i(0, 0))

func test_move_unit_same_position_succeeds() -> void:
	_map.place_unit(_unit, Vector2i(0, 0))
	assert(_map.move_unit(_unit, Vector2i(0, 0), Vector2i(0, 0)))
	assert(_unit.grid_position == Vector2i(0, 0))
