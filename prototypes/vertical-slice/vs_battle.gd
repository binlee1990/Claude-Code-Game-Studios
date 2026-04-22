class_name VSBattle
extends Control
## Vertical Slice battle demo — demonstrates core combat loop.
## Uses existing src/ systems: CombatSystem, Unit, GameEvents, ActionSystem.

const GRID_SIZE := 8
const CELL_SIZE := 64
const MARGIN := 20

enum VSPhase { SELECT_UNIT, SELECT_MOVE, SELECT_TARGET, ANIMATING, ENEMY_TURN, BATTLE_END }

var _combat: CombatSystem
var _actions: ActionSystem
var _phase: VSPhase = VSPhase.SELECT_UNIT
var _selected_unit: Unit = null
var _grid_units: Dictionary = {}  # Vector2i -> Unit
var _unit_cells: Dictionary = {}  # Unit -> Vector2i
var _move_range: Array = []
var _attack_range: Array = []

# UI references
var _grid_container: Control
var _cells: Dictionary = {}  # Vector2i -> ColorRect
var _unit_panels: Dictionary = {}  # Unit -> Panel
var _unit_labels: Dictionary = {}  # Unit -> Label
var _hp_bars: Dictionary = {}  # Unit -> ProgressBar
var _turn_list: VBoxContainer
var _action_bar: HBoxContainer
var _info_label: Label
var _result_label: Label

func _ready() -> void:
	_build_ui()
	_init_battle()

func _build_ui() -> void:
	# Main layout: grid on left, info on right
	var hsplit := HSplitContainer.new()
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hsplit)

	# Left: Grid area
	var grid_area := Panel.new()
	grid_area.custom_minimum_size = Vector2(GRID_SIZE * CELL_SIZE + MARGIN * 2, GRID_SIZE * CELL_SIZE + MARGIN * 2)
	grid_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hsplit.add_child(grid_area)

	_grid_container = Control.new()
	_grid_container.position = Vector2(MARGIN, MARGIN)
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_area.add_child(_grid_container)

	# Draw grid cells
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var cell := ColorRect.new()
			cell.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			var is_dark := (x + y) % 2 == 0
			cell.color = Color(0.2, 0.25, 0.2) if is_dark else Color(0.25, 0.3, 0.25)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pos := Vector2i(x, y)
			_cells[pos] = cell
			_grid_container.add_child(cell)

	# Right: Info panel
	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(250, 0)
	hsplit.add_child(right_panel)

	# Turn order
	var turn_label := Label.new()
	turn_label.text = "Turn Order"
	right_panel.add_child(turn_label)

	_turn_list = VBoxContainer.new()
	right_panel.add_child(_turn_list)

	# Info
	_info_label = Label.new()
	_info_label.text = "Click a blue unit to start"
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_panel.add_child(_info_label)

	# Action buttons
	_action_bar = HBoxContainer.new()
	right_panel.add_child(_action_bar)

	var btn_move := Button.new()
	btn_move.text = "Move (1)"
	btn_move.pressed.connect(_on_action_move)
	_action_bar.add_child(btn_move)

	var btn_attack := Button.new()
	btn_attack.text = "Attack (2)"
	btn_attack.pressed.connect(_on_action_attack)
	_action_bar.add_child(btn_attack)

	var btn_standby := Button.new()
	btn_standby.text = "Standby (3)"
	btn_standby.pressed.connect(_on_action_standby)
	_action_bar.add_child(btn_standby)

	var btn_end := Button.new()
	btn_end.text = "End Turn (4)"
	btn_end.pressed.connect(_on_action_end_turn)
	_action_bar.add_child(btn_end)

	# Result label (hidden)
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_label.add_theme_font_size_override("font_size", 48)
	_result_label.visible = false
	add_child(_result_label)

func _init_battle() -> void:
	_combat = CombatSystem.new()
	add_child(_combat)
	_actions = ActionSystem.new()
	add_child(_actions)

	# Create units
	var player_units := _create_unit("P1", "Swordsman", true, 80, Vector2i(1, 3))
	_create_unit("P2", "Archer", true, 60, Vector2i(1, 5))
	_create_unit("E1", "Dark Knight", false, 70, Vector2i(6, 2))
	_create_unit("E2", "Dark Mage", false, 55, Vector2i(6, 6))

	# Connect signals
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.health_changed.connect(_on_health_changed)
	GameEvents.unit_died.connect(_on_unit_died)

	# Initialize systems
	var all_units := _unit_cells.keys()
	_combat.start_battle("vs_demo", "demo_map", 1)
	_actions.initialize(all_units, {})
	_process_next_turn()

func _create_unit(id: String, name: String, is_player: bool, hp: int, pos: Vector2i) -> Unit:
	var unit := Unit.new()
	unit.unit_id = id
	unit.display_name = name
	add_child(unit)

	var team := CombatSystem.Team.PLAYER if is_player else CombatSystem.Team.ENEMY
	_combat.register_unit(unit, team, hp)
	_grid_units[pos] = unit
	_unit_cells[unit] = pos

	# Create visual panel on grid
	var panel := Panel.new()
	panel.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + 4)
	panel.custom_minimum_size = Vector2(CELL_SIZE - 8, CELL_SIZE - 24)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(panel)
	_unit_panels[unit] = panel

	# HP bar
	var hp_bar := ProgressBar.new()
	hp_bar.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + CELL_SIZE - 18)
	hp_bar.size = Vector2(CELL_SIZE - 8, 12)
	hp_bar.max_value = hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(hp_bar)
	_hp_bars[unit] = hp_bar

	# Name label
	var lbl := Label.new()
	lbl.text = name
	lbl.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + 4)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(lbl)
	_unit_labels[unit] = lbl

	return unit

func _refresh_all_units() -> void:
	for unit in _unit_panels:
		_refresh_unit_visual(unit)

func _refresh_unit_visual(unit: Unit) -> void:
	var panel: Panel = _unit_panels.get(unit)
	if panel == null:
		return
	var is_player := _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER
	var is_alive := _combat.is_unit_alive(unit)
	if is_player:
		panel.self_modulate = Color(0.3, 0.5, 0.9) if is_alive else Color(0.3, 0.3, 0.3, 0.5)
	else:
		panel.self_modulate = Color(0.9, 0.3, 0.3) if is_alive else Color(0.3, 0.3, 0.3, 0.5)
	if _selected_unit == unit:
		panel.self_modulate = Color(1.0, 0.85, 0.2)  # Gold highlight

func _refresh_turn_display() -> void:
	for child in _turn_list.get_children():
		child.queue_free()
	var order := _combat.get_turn_order()
	var current := _combat.get_current_actor()
	for unit in order:
		if not _combat.is_unit_alive(unit):
			continue
		var lbl := Label.new()
		var prefix := ">" if unit == current else " "
		var team_tag := "[P]" if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER else "[E]"
		lbl.text = "%s %s %s HP:%d" % [prefix, team_tag, unit.display_name, _combat.get_unit_hp(unit)]
		_turn_list.add_child(lbl)

func _clear_highlights() -> void:
	for pos in _cells:
		var cell: ColorRect = _cells[pos]
		var is_dark: bool = (pos.x + pos.y) % 2 == 0
		cell.color = Color(0.2, 0.25, 0.2) if is_dark else Color(0.25, 0.3, 0.25)

func _highlight_cells(positions: Array, color: Color) -> void:
	for pos in positions:
		if _cells.has(pos):
			_cells[pos].color = color

func _get_move_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result := []
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if abs(dx) + abs(dy) > 3:
				continue
			var target := pos + Vector2i(dx, dy)
			if target.x < 0 or target.x >= GRID_SIZE or target.y < 0 or target.y >= GRID_SIZE:
				continue
			if _grid_units.has(target) and _grid_units[target] != unit:
				continue
			result.append(target)
	return result

func _get_attack_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result := []
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if abs(dx) + abs(dy) > 2 or (dx == 0 and dy == 0):
				continue
			var target := pos + Vector2i(dx, dy)
			if target.x < 0 or target.x >= GRID_SIZE or target.y < 0 or target.y >= GRID_SIZE:
				continue
			if _grid_units.has(target):
				var target_unit: Unit = _grid_units[target]
				if _combat.get_unit_team(target_unit) != _combat.get_unit_team(unit):
					result.append(target)
	return result

# --- Input ---

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_grid_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _on_action_move()
			KEY_2: _on_action_attack()
			KEY_3: _on_action_standby()
			KEY_4: _on_action_end_turn()

func _handle_grid_click(click_pos: Vector2) -> void:
	var grid_pos := Vector2i(
		int((click_pos.x - MARGIN) / CELL_SIZE),
		int((click_pos.y - MARGIN) / CELL_SIZE)
	)
	if grid_pos.x < 0 or grid_pos.x >= GRID_SIZE or grid_pos.y < 0 or grid_pos.y >= GRID_SIZE:
		return

	match _phase:
		VSPhase.SELECT_UNIT:
			if _grid_units.has(grid_pos):
				var unit: Unit = _grid_units[grid_pos]
				if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER and _combat.is_unit_alive(unit) and unit == _combat.get_current_actor():
					_select_unit(unit)
		VSPhase.SELECT_MOVE:
			if grid_pos in _move_range:
				_do_move(grid_pos)
		VSPhase.SELECT_TARGET:
			if grid_pos in _attack_range:
				_do_attack(grid_pos)

func _select_unit(unit: Unit) -> void:
	_selected_unit = unit
	_clear_highlights()
	_move_range = _get_move_range(unit)
	_highlight_cells(_move_range, Color(0.2, 0.4, 0.5, 0.7))
	_phase = VSPhase.SELECT_MOVE
	_info_label.text = "%s selected. Click blue cell to move, or press 2 to attack, 3 to standby." % unit.display_name
	_refresh_all_units()

func _do_move(target_pos: Vector2i) -> void:
	var old_pos: Vector2i = _unit_cells[_selected_unit]
	_grid_units.erase(old_pos)
	_grid_units[target_pos] = _selected_unit
	_unit_cells[_selected_unit] = target_pos
	_update_unit_position(_selected_unit, target_pos)
	_clear_highlights()
	_move_range.clear()
	_info_label.text = "%s moved. Press 2 to attack or 3 to standby." % _selected_unit.display_name
	_phase = VSPhase.SELECT_TARGET
	_attack_range = _get_attack_range(_selected_unit)
	_highlight_cells(_attack_range, Color(0.7, 0.3, 0.2, 0.7))

func _do_attack(target_pos: Vector2i) -> void:
	var target: Unit = _grid_units[target_pos]
	var damage := DamageCalculation.calculate_damage(
		{"attack": 20.0, "strength": _selected_unit.get_attribute(AttributeNames.Attribute.STR)},
		{"defense": 10.0},
		{"damage_multiplier": 1.0}
	)
	_combat.apply_damage(target, damage, _selected_unit)
	_clear_highlights()
	_attack_range.clear()
	_end_player_turn()

func _update_unit_position(unit: Unit, pos: Vector2i) -> void:
	var panel: Panel = _unit_panels.get(unit)
	if panel:
		panel.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + 4)
	var label: Label = _unit_labels.get(unit)
	if label:
		label.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + 4)
	var hp_bar: ProgressBar = _hp_bars.get(unit)
	if hp_bar:
		hp_bar.position = Vector2(pos.x * CELL_SIZE + 4, pos.y * CELL_SIZE + CELL_SIZE - 18)

# --- Actions ---

func _on_action_move() -> void:
	if _phase == VSPhase.SELECT_UNIT and _combat.get_current_actor() != null:
		_select_unit(_combat.get_current_actor())

func _on_action_attack() -> void:
	if _phase == VSPhase.SELECT_MOVE:
		_clear_highlights()
		_move_range.clear()
		_phase = VSPhase.SELECT_TARGET
		_attack_range = _get_attack_range(_selected_unit)
		_highlight_cells(_attack_range, Color(0.7, 0.3, 0.2, 0.7))
		_info_label.text = "%s: Click red cell to attack." % _selected_unit.display_name
	elif _phase == VSPhase.SELECT_TARGET:
		pass

func _on_action_standby() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_end_player_turn()

func _on_action_end_turn() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_end_player_turn()

func _end_player_turn() -> void:
	_selected_unit = null
	_refresh_all_units()
	_combat.end_turn()
	_check_battle_end()
	if _phase != VSPhase.BATTLE_END:
		_process_next_turn()

func _process_next_turn() -> void:
	var actor: Unit = _combat.get_current_actor()
	if actor == null:
		_combat.end_turn()
		_refresh_turn_display()
		_process_next_turn()
		return
	if _combat.get_unit_team(actor) == CombatSystem.Team.ENEMY:
		_phase = VSPhase.ENEMY_TURN
		_info_label.text = "Enemy turn: %s" % actor.display_name
		_refresh_turn_display()
		_refresh_all_units()
		_do_enemy_turn(actor)
	else:
		_phase = VSPhase.SELECT_UNIT
		_info_label.text = "Your turn: Click %s (blue) or press 1" % actor.display_name
		_refresh_turn_display()
		_refresh_all_units()

func _do_enemy_turn(enemy: Unit) -> void:
	# Simple AI: move toward nearest player, attack if in range
	var enemy_pos: Vector2i = _unit_cells[enemy]
	var nearest_player: Unit = null
	var nearest_dist := 999
	for unit in _unit_cells:
		if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER and _combat.is_unit_alive(unit):
			var dist: int = abs(_unit_cells[unit].x - enemy_pos.x) + abs(_unit_cells[unit].y - enemy_pos.y)
			if dist < nearest_dist:
				nearest_player = unit
				nearest_dist = dist

	if nearest_player != null:
		var target_pos: Vector2i = _unit_cells[nearest_player]
		# Move toward target
		var move_range := _get_move_range(enemy)
		var best_pos := enemy_pos
		var best_dist := nearest_dist
		for pos in move_range:
			var dist: int = abs(pos.x - target_pos.x) + abs(pos.y - target_pos.y)
			if dist < best_dist:
				best_dist = dist
				best_pos = pos
		if best_pos != enemy_pos:
			_grid_units.erase(enemy_pos)
			_grid_units[best_pos] = enemy
			_unit_cells[enemy] = best_pos
			_update_unit_position(enemy, best_pos)

		# Attack if in range
		var attack_range := _get_attack_range(enemy)
		if attack_range.size() > 0:
			var damage := DamageCalculation.calculate_damage(
				{"attack": 15.0, "strength": enemy.get_attribute(AttributeNames.Attribute.STR)},
				{"defense": 8.0},
				{"damage_multiplier": 1.0}
			)
			_combat.apply_damage(nearest_player, damage, enemy)

	_combat.end_turn()
	_check_battle_end()
	if _phase != VSPhase.BATTLE_END:
		_process_next_turn()

func _check_battle_end() -> void:
	var result := _combat.check_end_conditions()
	if result == CombatSystem.CombatResult.VICTORY:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "VICTORY!"
		_result_label.modulate = Color(0.2, 0.8, 0.3)
		_result_label.visible = true
		_info_label.text = "Battle won! All enemies defeated."
	elif result == CombatSystem.CombatResult.DEFEAT:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "DEFEAT..."
		_result_label.modulate = Color(0.9, 0.2, 0.2)
		_result_label.visible = true
		_info_label.text = "All allies defeated."

# --- Signal handlers ---

func _on_turn_started(actor: Node) -> void:
	_refresh_turn_display()

func _on_health_changed(unit: Node, old_value: int, new_value: int) -> void:
	if _hp_bars.has(unit):
		_hp_bars[unit].value = new_value
	_refresh_turn_display()

func _on_unit_died(unit: Node, killer: Node) -> void:
	var pos: Vector2i = _unit_cells.get(unit, Vector2i(-1, -1))
	if pos.x >= 0:
		_grid_units.erase(pos)
	_unit_cells.erase(unit)
	_refresh_all_units()
	_refresh_turn_display()
