class_name Map extends Node2D

enum TileState { WALKABLE, BLOCKED, OBSTACLE, ROUGH }

const WALKABLE_MOVEMENT_COST := 1
const ROUGH_MOVEMENT_COST := 2
const BLOCKED_MOVEMENT_COST := -1

var grid_space: GridSpace
var _tile_states: Dictionary = {}
var _occupancy: Dictionary = {}
var _cols: int = 0
var _rows: int = 0
var emit_warnings: bool = true

var columns: int:
	get: return _cols
var rows: int:
	get: return _rows

const NEIGHBOR_OFFSETS: Array = [
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(0, -1), Vector2i(0, 1),
]

static var _test_instances: Array = []

func _init() -> void:
	_test_instances.append(weakref(self))

static func free_test_instances() -> void:
	for ref in _test_instances:
		var map = ref.get_ref()
		if is_instance_valid(map):
			map.free()
	_test_instances.clear()

func initialize(p_grid_space: GridSpace, map_name: String) -> void:
	grid_space = p_grid_space
	_load_csv("res://assets/data/maps/%s.csv" % map_name)
	_render_tiles()

func is_coord_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < _rows and coord.y >= 0 and coord.y < _cols

func get_tile_state(coord: Vector2i) -> TileState:
	return _tile_states.get(coord, TileState.BLOCKED)

func get_movement_cost(coord: Vector2i) -> int:
	if not is_coord_in_bounds(coord):
		return BLOCKED_MOVEMENT_COST
	var state: TileState = _tile_states.get(coord, TileState.BLOCKED)
	if state == TileState.WALKABLE:
		return WALKABLE_MOVEMENT_COST
	if state == TileState.ROUGH:
		return ROUGH_MOVEMENT_COST
	return BLOCKED_MOVEMENT_COST

func is_walkable(coord: Vector2i) -> bool:
	if not is_coord_in_bounds(coord):
		return false
	if get_movement_cost(coord) <= 0:
		return false
	if _occupancy.has(coord):
		return false
	return true

func get_neighbors(coord: Vector2i) -> Array:
	var result: Array = []
	for offset in NEIGHBOR_OFFSETS:
		var neighbor = coord + offset
		if is_coord_in_bounds(neighbor):
			result.append(neighbor)
	return result

func get_unit_at(coord: Vector2i) -> Unit:
	return _occupancy.get(coord, null)

func get_dimensions() -> Dictionary:
	return {"cols": _cols, "rows": _rows}

func place_unit(unit: Unit, coord: Vector2i) -> bool:
	if not is_coord_in_bounds(coord):
		return false
	if get_movement_cost(coord) <= 0:
		return false
	if _occupancy.has(coord):
		return false
	_occupancy[coord] = unit
	unit.grid_position = coord
	_sync_unit_world_position(unit, coord)
	return true

func remove_unit(coord: Vector2i) -> bool:
	if not _occupancy.has(coord):
		if emit_warnings:
			push_warning("remove_unit: no unit at %s" % coord)
		return false
	_occupancy.erase(coord)
	return true

func move_unit(unit: Unit, from: Vector2i, to: Vector2i) -> bool:
	if _occupancy.get(from) != unit:
		if emit_warnings:
			push_warning("move_unit: unit not at expected position %s" % from)
		return false
	if not is_coord_in_bounds(to):
		return false
	if get_movement_cost(to) <= 0:
		return false
	if from != to and _occupancy.has(to):
		return false
	_occupancy.erase(from)
	_occupancy[to] = unit
	unit.grid_position = to
	_sync_unit_world_position(unit, to)
	return true

func _sync_unit_world_position(unit: Unit, coord: Vector2i) -> void:
	if grid_space == null:
		return
	unit.position = grid_space.tile_center(coord)

func _load_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Map CSV not found: %s" % path)
		return

	var header = file.get_line().strip_edges()
	var parts = header.split(",")
	assert(parts.size() == 2, "CSV header must be 'cols,rows', got: %s" % header)
	_cols = parts[0].to_int()
	_rows = parts[1].to_int()
	assert(_cols >= 8 and _cols <= 32, "cols=%d out of range [8,32]" % _cols)
	assert(_rows >= 8 and _rows <= 32, "rows=%d out of range [8,32]" % _rows)

	var r: int = 0
	while r < _rows:
		if file.eof_reached():
			assert(false, "CSV ended at row %d, expected %d rows" % [r, _rows])
		var line = file.get_line().strip_edges()
		assert(line.length() == _cols, "Row %d: expected %d chars, got %d" % [r, _cols, line.length()])
		for c in range(_cols):
			var ch = line[c]
			var coord = Vector2i(r, c)
			match ch:
				".":
					_tile_states[coord] = TileState.WALKABLE
				"#":
					_tile_states[coord] = TileState.BLOCKED
				"O":
					_tile_states[coord] = TileState.OBSTACLE
				"R":
					_tile_states[coord] = TileState.ROUGH
				_:
					assert(false, "Invalid char '%s' at (%d,%d)" % [ch, r, c])
		r += 1

func _render_tiles() -> void:
	var tilemap = get_node_or_null("TileMapLayer") as TileMapLayer
	if tilemap == null:
		return
	tilemap.tile_set = load("res://assets/data/tileset.tres")
	tilemap.clear()
	for coord in _tile_states:
		var atlas_coords = _tile_state_to_atlas(_tile_states[coord])
		tilemap.set_cell(coord, 0, atlas_coords)

func _tile_state_to_atlas(state: TileState) -> Vector2i:
	match state:
		TileState.WALKABLE:
			return Vector2i(0, 0)
		TileState.BLOCKED:
			return Vector2i(1, 0)
		TileState.OBSTACLE:
			return Vector2i(2, 0)
		TileState.ROUGH:
			return Vector2i(0, 0)
	return Vector2i(0, 0)
