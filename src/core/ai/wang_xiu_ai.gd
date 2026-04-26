class_name WangXiuAI
extends RefCounted

## NPC escort AI for Wang Xiu (Ch.2-2B).
## Moves toward safe zone 1 cell/turn, hesitates when enemies within range.
## Story: CH2-c-002 / GDD: chapter-02.md §3.3, §3.4

signal npc_departed(unit_id: String)
signal safe_zone_reached(unit_id: String, belief_reward: Dictionary)

const DEFAULT_HESITATION_RANGE: int = 2

var _grid: Array
var _position: Vector2i
var _hp: int
var _max_hp: int
var _safe_zone_origin: Vector2i
var _safe_zone_size: Vector2i
var _hesitation_range: int = DEFAULT_HESITATION_RANGE
var _unit_id: String = "wang_xiu"

var _departed: bool = false
var _reached_safe_zone: bool = false

var _dirs: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
]


func init(grid: Array, start_pos: Vector2i, hp: int = 30,
		safe_zone_origin: Vector2i = Vector2i(0, 0),
		safe_zone_size: Vector2i = Vector2i(3, 3)) -> void:
	_grid = grid
	_position = start_pos
	_hp = hp
	_max_hp = hp
	_safe_zone_origin = safe_zone_origin
	_safe_zone_size = safe_zone_size
	_hesitation_range = DEFAULT_HESITATION_RANGE
	_departed = false
	_reached_safe_zone = false


func decide_action(enemy_positions: Array) -> Dictionary:
	if _departed:
		return {"action": "none", "reason": "departed"}

	if _reached_safe_zone:
		return {"action": "none", "reason": "already_safe"}

	if _is_in_safe_zone(_position):
		_reached_safe_zone = true
		safe_zone_reached.emit(_unit_id, {"ren": 12})
		return {"action": "safe_zone_reached", "position": _position}

	if _is_enemy_nearby(enemy_positions):
		return {"action": "hesitate", "position": _position}

	var next_step := _find_next_step()
	_position = next_step

	if _is_in_safe_zone(_position):
		_reached_safe_zone = true
		safe_zone_reached.emit(_unit_id, {"ren": 12})
		return {"action": "safe_zone_reached", "position": _position}

	return {"action": "move", "position": _position}


func take_damage(amount: int) -> void:
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0 and not _departed:
		_departed = true
		npc_departed.emit(_unit_id)


func get_position() -> Vector2i:
	return _position


func get_hp() -> int:
	return _hp


func is_departed() -> bool:
	return _departed


func has_reached_safe_zone() -> bool:
	return _reached_safe_zone


func set_position(pos: Vector2i) -> void:
	_position = pos


func _is_in_safe_zone(pos: Vector2i) -> bool:
	return pos.x >= _safe_zone_origin.x and \
		pos.x < _safe_zone_origin.x + _safe_zone_size.x and \
		pos.y >= _safe_zone_origin.y and \
		pos.y < _safe_zone_origin.y + _safe_zone_size.y


func _is_enemy_nearby(enemy_positions: Array) -> bool:
	for ep in enemy_positions:
		if _manhattan_distance(_position, ep) <= _hesitation_range:
			return true
	return false


func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _is_walkable(pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= _grid.size() or _grid.is_empty():
		return false
	if pos.x < 0 or pos.x >= _grid[0].size():
		return false
	return not TerrainTypes.blocks_movement(_grid[pos.y][pos.x])


func _find_next_step() -> Vector2i:
	var target := _find_nearest_safe_zone_cell()
	if target == _position:
		return _position

	var best_next := _position
	var best_dist := _manhattan_distance(_position, target)

	for d in _dirs:
		var neighbor := _position + d
		if _is_walkable(neighbor):
			var dist := _manhattan_distance(neighbor, target)
			if dist < best_dist:
				best_dist = dist
				best_next = neighbor

	return best_next


func _find_nearest_safe_zone_cell() -> Vector2i:
	var best := _position
	var best_dist := 999999
	for y in range(_safe_zone_origin.y, _safe_zone_origin.y + _safe_zone_size.y):
		for x in range(_safe_zone_origin.x, _safe_zone_origin.x + _safe_zone_size.x):
			var cell := Vector2i(x, y)
			var dist := _manhattan_distance(_position, cell)
			if dist < best_dist:
				best_dist = dist
				best = cell
	return best
