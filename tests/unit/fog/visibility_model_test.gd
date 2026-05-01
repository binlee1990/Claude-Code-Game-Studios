extends Gut

const FogStateManager = preload("res://src/core/fog/fog_state_manager.gd")

var _fog


func before_each() -> void:
	_fog = FogStateManager.new()
	_fog.set_enabled(true)


func test_fog_disabled_returns_all_visible() -> void:
	_fog.set_enabled(false)
	assert_eq(_fog.get_cell_state(Vector2i(5, 5)), FogStateManager.FogCellState.VISIBLE)
	assert_eq(_fog.get_cell_state(Vector2i(0, 0)), FogStateManager.FogCellState.VISIBLE)


func test_fog_initial_state_is_unknown() -> void:
	assert_eq(_fog.get_cell_state(Vector2i(3, 3)), FogStateManager.FogCellState.UNKNOWN)


func test_fog_reveal_sets_cells_visible() -> void:
	_fog.reveal_from_position(Vector2i(5, 5), 2)
	assert_eq(_fog.get_cell_state(Vector2i(5, 5)), FogStateManager.FogCellState.VISIBLE)
	assert_eq(_fog.get_cell_state(Vector2i(7, 5)), FogStateManager.FogCellState.VISIBLE)


func test_fog_cell_beyond_vision_is_unknown() -> void:
	_fog.reveal_from_position(Vector2i(5, 5), 1)
	assert_eq(_fog.get_cell_state(Vector2i(10, 10)), FogStateManager.FogCellState.UNKNOWN)


func test_fog_explored_cells_persist_after_recalculate() -> void:
	_fog.reveal_from_position(Vector2i(3, 3), 2)
	assert_true(_fog.is_cell_explored(Vector2i(3, 3)))
	assert_true(_fog.is_cell_explored(Vector2i(5, 3)))


func test_fog_base_vision_is_3() -> void:
	assert_eq(_fog.calculate_vision_range(30, "", false, false), 3)


func test_fog_agility_60_gives_plus_1_vision() -> void:
	assert_eq(_fog.calculate_vision_range(60, "", false, false), 4)


func test_fog_agility_80_gives_plus_2_vision() -> void:
	assert_eq(_fog.calculate_vision_range(80, "", false, false), 5)


func test_fog_scout_class_gives_plus_3_vision() -> void:
	assert_eq(_fog.calculate_vision_range(30, "scout", false, false), 6)


func test_fog_high_ground_gives_plus_1_vision() -> void:
	assert_eq(_fog.calculate_vision_range(30, "", true, false), 4)


func test_fog_near_light_gives_plus_2_vision() -> void:
	assert_eq(_fog.calculate_vision_range(30, "", false, true), 5)


func test_fog_full_bonus_stacking() -> void:
	var vr: int = _fog.calculate_vision_range(80, "scout", true, true)
	assert_eq(vr, 11)


func test_fog_get_explored_cells_returns_array() -> void:
	_fog.reveal_from_position(Vector2i(0, 0), 0)
	var cells: Array = _fog.get_explored_cells()
	assert_true(cells is Array)
	assert_eq(cells.size(), 1)


func test_fog_set_explored_cells_restores_state() -> void:
	var cells: Array = [Vector2i(1, 1), Vector2i(2, 2)]
	_fog.set_explored_cells(cells)
	assert_true(_fog.is_cell_explored(Vector2i(1, 1)))
	assert_true(_fog.is_cell_explored(Vector2i(2, 2)))
	assert_false(_fog.is_cell_explored(Vector2i(5, 5)))


func test_fog_clear_resets_all_state() -> void:
	_fog.reveal_from_position(Vector2i(3, 3), 2)
	_fog.clear()
	assert_eq(_fog.get_cell_state(Vector2i(3, 3)), FogStateManager.FogCellState.UNKNOWN)
	assert_eq(_fog.get_explored_cells().size(), 0)


func test_fog_is_cell_visible_returns_correctly() -> void:
	_fog.reveal_from_position(Vector2i(5, 5), 1)
	assert_true(_fog.is_cell_visible(Vector2i(5, 5)))
	assert_false(_fog.is_cell_visible(Vector2i(10, 10)))


func test_fog_is_enabled_defaults_false() -> void:
	var new_fog = FogStateManager.new()
	assert_false(new_fog.is_enabled())


func test_fog_recalculate_visible_from_multiple_units() -> void:
	_fog.recalculate_visible([Vector2i(2, 2), Vector2i(8, 8)], [2, 2])
	assert_true(_fog.is_cell_visible(Vector2i(2, 2)))
	assert_true(_fog.is_cell_visible(Vector2i(8, 8)))
