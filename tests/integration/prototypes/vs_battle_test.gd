# tests/integration/prototypes/vs_battle_test.gd
# Vertical-slice prototype regression coverage

extends Gut

var _battle

func before_each() -> void:
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load("res://prototypes/vertical-slice/vs_battle.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_initial_battle_state_is_immediately_playable() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	assert_eq(_battle._phase, _battle.VSPhase.SELECT_UNIT, "Prototype should wait on a player turn")
	assert_eq(_battle._combat.get_unit_team(actor), CombatSystem.Team.PLAYER, "Initial controllable actor should belong to the player")
	assert_true(_battle._info_label.text.begins_with("Your turn:"), "Prompt should identify the active player unit")

func test_click_input_selects_active_unit_and_moves_it() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var origin: Vector2i = _battle._unit_cells[actor]

	_click_cell(origin)

	assert_eq(_battle._selected_unit, actor, "Clicking the active unit should select it")
	assert_eq(_battle._phase, _battle.VSPhase.SELECT_MOVE, "Selection should enter move mode")

	var move_target: Vector2i = _first_distinct_position(_battle._move_range, origin)
	_click_cell(move_target)

	assert_eq(_battle._unit_cells[actor], move_target, "Move click should relocate the actor")
	assert_eq(_battle._phase, _battle.VSPhase.SELECT_TARGET, "Move should transition into attack selection")

func test_attack_flow_reduces_enemy_hp() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var enemy: Unit = _first_enemy_unit()
	var actor_pos := Vector2i(3, 3)
	var enemy_pos := Vector2i(4, 3)

	_relocate_unit(actor, actor_pos)
	_relocate_unit(enemy, enemy_pos)
	var hp_before: int = _battle._combat.get_unit_hp(enemy)

	_click_cell(actor_pos)
	_battle._on_action_attack()
	_click_cell(enemy_pos)

	assert_true(_battle._combat.get_unit_hp(enemy) < hp_before, "Attack click should apply damage")
	assert_eq(_battle._selected_unit, null, "Attack should clear the current selection")

func test_enemy_turn_acquires_nearest_player_target() -> void:
	var enemy: Unit = _first_enemy_unit()
	var player: Unit = _battle._combat.get_current_actor()
	var player_pos := Vector2i(1, 1)
	var enemy_pos := Vector2i(6, 1)

	_relocate_unit(player, player_pos)
	_relocate_unit(enemy, enemy_pos)
	var before_distance: int = _manhattan(enemy_pos, player_pos)

	while _battle._combat.get_current_actor() != enemy:
		_battle._combat.end_turn()

	_battle._phase = _battle.VSPhase.ENEMY_TURN
	_battle._do_enemy_turn(enemy)

	var after_pos: Vector2i = _battle._unit_cells[enemy]
	var after_distance: int = _manhattan(after_pos, player_pos)
	assert_true(after_distance < before_distance, "Enemy turn should identify a player target and move closer")

func test_auto_toggle_immediately_starts_controlled_turn() -> void:
	var actor: Unit = _battle._combat.get_current_actor()

	_battle._toggle_auto_battle()

	assert_true(_battle._auto_battle_controller.is_enabled(), "Auto toggle should enable auto-battle")
	assert_true(_battle._turn_sequence_running, "Auto toggle should immediately start the current player turn")
	assert_eq(_battle._phase, _battle.VSPhase.ANIMATING, "Auto turn should enter controlled presentation")
	assert_eq(_battle._selected_unit, actor, "Auto turn should select the current actor without a manual Move click")
	assert_true(_battle._info_label.text.contains("chooses a move"), "Prompt should show that auto is acting now")

func test_auto_controlled_turn_moves_and_attacks_without_manual_input() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	var enemy: Unit = _first_enemy_unit()
	var actor_pos := Vector2i(3, 3)
	var enemy_pos := Vector2i(6, 3)

	_relocate_unit(actor, actor_pos)
	_relocate_unit(enemy, enemy_pos)
	var hp_before: int = _battle._combat.get_unit_hp(enemy)

	_battle._toggle_auto_battle()
	_battle._advance_controlled_turn_step()

	assert_ne(_battle._unit_cells[actor], actor_pos, "Auto step should move the actor without player tile input")
	assert_eq(_battle._combat.get_unit_hp(enemy), hp_before, "Move step should not apply attack damage yet")

	_battle._advance_controlled_turn_step()

	assert_true(_battle._combat.get_unit_hp(enemy) < hp_before, "Attack step should damage the target without player input")

	_battle._advance_controlled_turn_step()

	var next_actor: Unit = _battle._combat.get_current_actor()
	assert_ne(next_actor, actor, "Final step should advance to the next actor")
	assert_true(_battle._turn_sequence_running, "Auto battle should hand off directly to the next controlled turn")
	assert_eq(_battle._selected_unit, next_actor, "Selection should follow the next controlled actor")

func _click_cell(grid_pos: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = _battle.get_cell_click_point(grid_pos)
	_battle._input(event)

func _first_distinct_position(positions: Array, origin: Vector2i) -> Vector2i:
	for pos in positions:
		if pos != origin:
			return pos
	return origin

func _first_enemy_unit() -> Unit:
	for unit in _battle._unit_cells:
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY and _battle._combat.is_unit_alive(unit):
			return unit
	return null

func _relocate_unit(unit: Unit, target_pos: Vector2i) -> void:
	var old_pos: Vector2i = _battle._unit_cells[unit]
	_battle._grid_units.erase(old_pos)
	_battle._grid_units[target_pos] = unit
	_battle._unit_cells[unit] = target_pos
	_battle._update_unit_position(unit, target_pos)

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
