extends Gut

var _battle

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_finale_boots_ren_variant_and_three_phase_boss() -> void:
	_load_finale({"dominant_route": "ren", "margin": 25, "soft_lock_candidate": true})
	assert_eq(_battle.get_battle_id(), "chapter_03_finale")
	assert_eq(_battle.get_chapter3_finale_variant_state()["variant_id"], "civilian_evacuation")
	assert_ne(_find_unit("REN_PURSUER"), null)

	var boss := _find_unit("BOSS_YAN")
	var actor: Unit = _battle._combat.get_current_actor()
	assert_ne(boss, null)
	_battle._combat.apply_damage(boss, 80, actor)
	assert_eq(_battle.get_boss_state()["phase"], 2)
	_battle._combat.apply_damage(boss, 40, actor)
	assert_eq(_battle.get_boss_state()["phase"], 3)

func test_finale_without_gate_uses_zhi_variant() -> void:
	_load_finale({})
	assert_eq(_battle.get_chapter3_finale_variant_state()["variant_id"], "mechanist_pressure")
	assert_ne(_find_unit("ZHI_MECHANIST"), null)

func _load_finale(gate: Dictionary) -> void:
	var sd := SaveData.new()
	sd.battle_state = {"battle_definition_path": "res://src/ui/combat/battle_definitions/chapter_03_finale.json"}
	sd.story_progress = {
		"chapter": 3,
		"current_battle": "chapter_03_finale",
		"b3_gate": gate,
	}
	SaveManager._pending_loaded_data = sd
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func _find_unit(unit_id: String) -> Unit:
	for unit in _battle._unit_cells.keys():
		if String(unit.unit_id) == unit_id:
			return unit
	return null
