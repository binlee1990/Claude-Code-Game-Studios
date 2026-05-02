class_name InputHandler extends RefCounted

const TurnState = preload("res://src/core/turn_state.gd")
const UnitState = preload("res://src/core/unit_state.gd")
const AttackResult = preload("res://src/attack/attack_result.gd")

enum InputContext { BOARD_IDLE, UNIT_SELECTED, ATTACK_TARGETING }

var _map: Map
var _grid_space: GridSpace
var _turn_manager: TurnManager
var _movement_resolver: MovementResolver
var _attack_resolver: AttackResolver
var _attack_range_resolver: AttackRangeResolver
var _all_units: Array

var _context: InputContext = InputContext.BOARD_IDLE
var _selected_unit: Unit = null
var _current_movement_result: MovementResult = null

signal move_highlights_changed(tiles: Array)
signal path_highlights_changed(tiles: Array)
signal attack_highlights_changed(tiles: Array)
signal damage_preview_requested(target: Unit, damage: int)
signal preview_cleared()
signal selection_changed(unit: Unit)
signal selection_cleared()
signal context_changed(context: int)

func initialize(
	p_map: Map,
	p_grid_space: GridSpace,
	p_turn_manager: TurnManager,
	p_movement_resolver: MovementResolver,
	p_attack_resolver: AttackResolver,
	p_attack_range_resolver: AttackRangeResolver,
	p_all_units: Array,
) -> void:
	_map = p_map
	_grid_space = p_grid_space
	_turn_manager = p_turn_manager
	_movement_resolver = p_movement_resolver
	_attack_resolver = p_attack_resolver
	_attack_range_resolver = p_attack_range_resolver
	_all_units = p_all_units

func handle_event(event: InputEvent) -> void:
	if _turn_manager.current_state != TurnState.FACTION_PHASE_ACTIVE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click(event.position)
	elif event is InputEventMouse:
		_handle_hover(event.position)
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_handle_cancel()

func get_context() -> int:
	return _context

func get_selected_unit() -> Unit:
	return _selected_unit

func _handle_click(screen_pos: Vector2) -> void:
	var grid_pos: Vector2i = _grid_space.world_to_grid(screen_pos)
	if not _map.is_coord_in_bounds(grid_pos):
		return

	match _context:
		InputContext.BOARD_IDLE:
			var unit: Unit = _map.get_unit_at(grid_pos)
			if unit != null and unit.can_be_selected() and unit.faction == _turn_manager.active_faction:
				_select_unit(unit)

		InputContext.UNIT_SELECTED:
			var targets: Array = _attack_range_resolver.get_valid_targets(_selected_unit, _all_units, _map)
			var clicked_enemy: Unit = _map.get_unit_at(grid_pos)
			if clicked_enemy != null and clicked_enemy in targets:
				_execute_direct_attack(clicked_enemy)
				return

			if _current_movement_result != null and _current_movement_result.get_distance_to(grid_pos) >= 0:
				_execute_move(grid_pos)
				return

			var other_unit: Unit = _map.get_unit_at(grid_pos)
			if other_unit != null and other_unit.can_be_selected() and other_unit != _selected_unit and other_unit.faction == _turn_manager.active_faction:
				_deselect_unit()
				_select_unit(other_unit)

		InputContext.ATTACK_TARGETING:
			var target: Unit = _map.get_unit_at(grid_pos)
			var valid_targets: Array = _attack_range_resolver.get_valid_targets(_selected_unit, _all_units, _map)
			if target != null and target in valid_targets:
				_execute_attack(target)

func _handle_hover(screen_pos: Vector2) -> void:
	var grid_pos: Vector2i = _grid_space.world_to_grid(screen_pos)
	if not _map.is_coord_in_bounds(grid_pos):
		preview_cleared.emit()
		return

	match _context:
		InputContext.UNIT_SELECTED:
			if _current_movement_result != null:
				var path: Array = _current_movement_result.get_path_to(grid_pos)
				if path.is_empty():
					path_highlights_changed.emit([])
				else:
					path_highlights_changed.emit(path)

		InputContext.ATTACK_TARGETING:
			var target: Unit = _map.get_unit_at(grid_pos)
			if target != null:
				var valid_targets: Array = _attack_range_resolver.get_valid_targets(_selected_unit, _all_units, _map)
				if target in valid_targets:
					var damage := AttackResult.resolve_damage(_selected_unit.atk, target.def)
					damage_preview_requested.emit(target, damage)
					return
			preview_cleared.emit()

func _handle_cancel() -> void:
	match _context:
		InputContext.UNIT_SELECTED:
			_deselect_unit()
		InputContext.ATTACK_TARGETING:
			_skip_attack()

func _select_unit(unit: Unit) -> void:
	_selected_unit = unit
	_selected_unit.action_state = UnitState.SELECTED
	_current_movement_result = _movement_resolver.compute_reachable(unit, _map)
	_context = InputContext.UNIT_SELECTED

	move_highlights_changed.emit(_current_movement_result.get_reachable_tiles())
	var initial_targets: Array = _attack_range_resolver.get_valid_targets(unit, _all_units, _map)
	var target_coords: Array = []
	for t in initial_targets:
		target_coords.append(t.grid_position)
	attack_highlights_changed.emit(target_coords)
	selection_changed.emit(unit)
	context_changed.emit(_context)

func _deselect_unit() -> void:
	if _selected_unit != null:
		_selected_unit.action_state = UnitState.IDLE
	_selected_unit = null
	_current_movement_result = null
	_context = InputContext.BOARD_IDLE
	move_highlights_changed.emit([])
	path_highlights_changed.emit([])
	attack_highlights_changed.emit([])
	preview_cleared.emit()
	selection_cleared.emit()
	context_changed.emit(_context)

func _execute_move(to: Vector2i) -> void:
	var from := _selected_unit.grid_position
	if _map.move_unit(_selected_unit, from, to):
		_selected_unit.action_state = UnitState.MOVED
		_current_movement_result = null
		move_highlights_changed.emit([])
		path_highlights_changed.emit([])

		var targets: Array = _attack_range_resolver.get_valid_targets(_selected_unit, _all_units, _map)
		if targets.is_empty():
			_skip_attack()
		else:
			_context = InputContext.ATTACK_TARGETING
			context_changed.emit(_context)
			var target_coords: Array = []
			for t in targets:
				target_coords.append(t.grid_position)
			attack_highlights_changed.emit(target_coords)

func _execute_direct_attack(target: Unit) -> void:
	var attacker := _selected_unit
	_pre_attack_cleanup()
	_attack_resolver.execute_attack(attacker, target)

func _execute_attack(target: Unit) -> void:
	var attacker := _selected_unit
	_pre_attack_cleanup()
	_attack_resolver.execute_attack(attacker, target)

func _skip_attack() -> void:
	_selected_unit.has_acted_this_turn = true
	_selected_unit.action_state = UnitState.ACTED
	_selected_unit = null
	_context = InputContext.BOARD_IDLE
	move_highlights_changed.emit([])
	path_highlights_changed.emit([])
	attack_highlights_changed.emit([])
	preview_cleared.emit()
	selection_cleared.emit()
	context_changed.emit(_context)

func _pre_attack_cleanup() -> void:
	_selected_unit = null
	_current_movement_result = null
	_context = InputContext.BOARD_IDLE
	move_highlights_changed.emit([])
	path_highlights_changed.emit([])
	attack_highlights_changed.emit([])

func force_clear() -> void:
	_selected_unit = null
	_current_movement_result = null
	_context = InputContext.BOARD_IDLE
	move_highlights_changed.emit([])
	path_highlights_changed.emit([])
	attack_highlights_changed.emit([])
	preview_cleared.emit()
	selection_cleared.emit()
