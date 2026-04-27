extends Gut

var _battle

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_chapter_three_battle_two_loads_pressure_objective() -> void:
	_load_battle_definition_path("res://src/ui/combat/battle_definitions/chapter_03_act_b.json", {
		"chapter": 3,
		"current_battle": "chapter_03_act_b",
		"chapter_03_battle_1_civilians_rescued": 1,
		"chapter_03_act_a_e1_defeated_in_6_turns": true,
	})

	assert_eq(_battle.get_battle_id(), "chapter_03_act_b")
	assert_true(_battle.get_objective_text().contains("beacon") or _battle.get_objective_text().contains("信标"))
	assert_eq(_battle.get_chapter3_pressure_state()["enemy_morale_bonus"], 1)
	assert_true(_battle.get_chapter3_pressure_state()["advance_hint"])
	assert_ne(_find_unit("PASS_BEACON"), null)
	assert_ne(_find_unit("E25"), null)

func test_chapter_three_battle_two_victory_persists_b3_gate_and_routes_finale() -> void:
	_load_battle_definition_path("res://src/ui/combat/battle_definitions/chapter_03_act_b.json", {
		"chapter": 3,
		"current_battle": "chapter_03_act_b",
		"belief_values": {"ren": 50, "yi": 25, "zhi": 10},
	})
	_defeat_current_enemies()

	var progress: Dictionary = _battle.get_story_progress()
	assert_true(progress.has("b3_gate"))
	assert_eq(progress["b3_gate"]["dominant_route"], "ren")
	assert_true(_battle.advance_to_next_battle())
	assert_eq(_battle.get_battle_id(), "chapter_03_finale")
	assert_eq(_battle.get_chapter3_finale_variant_state()["variant_id"], "civilian_evacuation")

func _load_battle_definition_path(path: String, story_progress: Dictionary) -> void:
	var sd := SaveData.new()
	sd.battle_state = {"battle_definition_path": path}
	sd.story_progress = story_progress.duplicate(true)
	SaveManager._pending_loaded_data = sd
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func _defeat_current_enemies() -> void:
	var actor: Unit = _battle._combat.get_current_actor()
	for unit in _battle._unit_cells.keys():
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			_battle._combat.apply_damage(unit, 999, actor)
	_battle._check_battle_end()

func _find_unit(unit_id: String) -> Unit:
	for unit in _battle._unit_cells.keys():
		if String(unit.unit_id) == unit_id:
			return unit
	return null
