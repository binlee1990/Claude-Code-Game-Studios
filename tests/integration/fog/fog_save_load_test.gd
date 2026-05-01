extends Gut

const FogStateManager = preload("res://src/core/fog/fog_state_manager.gd")

var _fog


func before_each() -> void:
	_fog = FogStateManager.new()
	_fog.set_enabled(true)


func test_fog_save_load_explored_cells_round_trip() -> void:
	_fog.reveal_from_position(Vector2i(3, 3), 2)
	var saved: Array = _fog.get_explored_cells()
	assert_true(saved.size() > 0)

	var restored := FogStateManager.new()
	restored.set_enabled(true)
	restored.set_explored_cells(saved)

	for cell in saved:
		assert_true(restored.is_cell_explored(cell))


func test_fog_save_load_empty_explored_cells() -> void:
	var saved: Array = _fog.get_explored_cells()
	assert_eq(saved.size(), 0)

	var restored := FogStateManager.new()
	restored.set_explored_cells(saved)
	assert_eq(restored.get_explored_cells().size(), 0)


func test_fog_save_load_disabled_state_persists() -> void:
	_fog.set_enabled(false)
	assert_false(_fog.is_enabled())

	var restored := FogStateManager.new()
	restored.set_enabled(false)
	assert_false(restored.is_enabled())


func test_fog_save_load_enabled_after_restore_works() -> void:
	_fog.reveal_from_position(Vector2i(2, 2), 1)
	var saved: Array = _fog.get_explored_cells()

	var restored := FogStateManager.new()
	restored.set_enabled(true)
	restored.set_explored_cells(saved)
	assert_true(restored.is_cell_explored(Vector2i(2, 2)))
	assert_false(restored.is_cell_explored(Vector2i(10, 10)))
