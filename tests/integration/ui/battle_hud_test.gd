# tests/integration/ui/battle_hud_test.gd
# Battle HUD and menu-system regression coverage.

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

func test_battle_hud_builds_turn_order_actions_and_status() -> void:
	assert_true(_battle._turn_list.get_child_count() >= 4, "Turn order list should show the battle roster")
	assert_eq(_battle._action_bar.get_child_count(), 4, "Action bar should expose four battle actions")
	assert_true(_battle._status_name_label.text.begins_with("Unit:"), "Status panel should show the focused unit")

func test_health_change_reactively_updates_hp_bar() -> void:
	var enemy: Unit = _first_enemy()
	var hp_before: int = _battle._combat.get_unit_hp(enemy)
	var bar_before: float = (_battle._hp_bars[enemy] as ProgressBar).value
	_battle._combat.apply_damage(enemy, 10, _battle._combat.get_current_actor())
	assert_true(_battle._combat.get_unit_hp(enemy) < hp_before)
	assert_true((_battle._hp_bars[enemy] as ProgressBar).value < bar_before, "HP bar should update from the health_changed event")

func test_resource_hud_updates_from_inventory_events() -> void:
	var before_text: String = (_battle._resource_labels["gold"] as Label).text
	_battle._inventory.add_resource(ResourceTypes.ResourceId.GOLD, 25)
	var after_text: String = (_battle._resource_labels["gold"] as Label).text
	assert_ne(before_text, after_text)
	assert_true(after_text.contains("525"), "Gold HUD should reflect inventory updates")

func test_menu_tabs_and_visibility_toggle() -> void:
	_battle._toggle_menu()
	assert_true(_battle._menu_layer.visible, "Menu overlay should open")
	_battle.set_active_menu_tab("inventory")
	assert_true(_battle._menu_content_label.text.begins_with("Inventory"))
	_battle._toggle_menu()
	assert_false(_battle._menu_layer.visible, "Menu overlay should close")

func _first_enemy() -> Unit:
	for unit in _battle._unit_cells:
		if _battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			return unit
	return null
