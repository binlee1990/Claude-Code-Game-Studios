# tests/integration/prototypes/battle_arena_entry_test.gd
# Regression coverage for the formal battle entry scene.

extends Gut

var _battle

func before_each() -> void:
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load("res://src/ui/combat/battle_arena.tscn")
	_battle = scene.instantiate()
	add_child(_battle)

func after_each() -> void:
	SaveManager.clear_pending_loaded_data()
	if is_instance_valid(_battle):
		_battle.queue_free()

func test_formal_battle_scene_uses_playable_vertical_slice_controller() -> void:
	assert_ne(_battle, null, "Formal battle scene should instantiate")
	assert_eq(_battle._phase, _battle.VSPhase.SELECT_UNIT, "Formal battle scene should start on a player turn")
	var actor: Unit = _battle._combat.get_current_actor()
	assert_ne(actor, null, "Formal battle scene should create a current actor")
	assert_eq(_battle._combat.get_unit_team(actor), CombatSystem.Team.PLAYER, "Formal battle entry should be immediately controllable")
	assert_true(_battle._info_label.text.begins_with("Your turn:"), "Formal battle scene should expose the same playable prompt as the prototype")
