extends Gut

const FogBattleIntegration = preload("res://src/core/fog/fog_battle_integration.gd")


func test_fog_integration_disabled_by_default() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({})
	assert_false(fog.is_enabled())


func test_fog_integration_enabled_from_definition() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true, "base_vision": 5}})
	assert_true(fog.is_enabled())


func test_fog_integration_all_cells_targetable_when_disabled() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({})
	assert_true(fog.is_cell_targetable(Vector2i(50, 50)))


func test_fog_integration_unknown_cell_not_targetable_when_enabled() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true}})
	assert_false(fog.is_cell_targetable(Vector2i(5, 5)))


func test_fog_integration_revealed_cell_is_targetable() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true}})
	fog.reveal_area(Vector2i(3, 3), 2)
	assert_true(fog.is_cell_targetable(Vector2i(3, 3)))


func test_fog_integration_recalculate_vision_from_units() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true}})
	fog.recalculate_vision([Vector2i(2, 2)], [3])
	assert_true(fog.is_cell_targetable(Vector2i(2, 2)))


func test_fog_integration_explored_cells_round_trip() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true}})
	fog.reveal_area(Vector2i(0, 0), 2)
	var saved := fog.get_explored_cells()
	assert_true(saved.size() > 0)

	var fog2 := FogBattleIntegration.new()
	fog2.init_from_definition({"fog": {"enabled": true}})
	fog2.set_explored_cells(saved)
	for cell in saved:
		assert_true(fog2.is_cell_targetable(cell))


func test_fog_integration_config_accessible() -> void:
	var fog := FogBattleIntegration.new()
	fog.init_from_definition({"fog": {"enabled": true, "density": "night", "base_vision": 4}})
	var config := fog.get_config()
	assert_eq(config.get("density"), "night")
	assert_eq(config.get("base_vision"), 4)
