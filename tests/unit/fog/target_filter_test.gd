extends Gut

const FogTargetFilter = preload("res://src/core/fog/fog_target_filter.gd")
const FogStateManager = preload("res://src/core/fog/fog_state_manager.gd")

var _filter
var _fog


func before_each() -> void:
	_filter = FogTargetFilter.new()
	_fog = FogStateManager.new()
	_fog.set_enabled(true)
	_filter.setup(_fog)


func test_fog_filter_no_fog_state_allows_all() -> void:
	var f := FogTargetFilter.new()
	# without setup, should default to allow all
	assert_true(f.is_targetable(Vector2i(99, 99)))


func test_fog_filter_disabled_fog_allows_all() -> void:
	_fog.set_enabled(false)
	_filter.setup(_fog)
	assert_true(_filter.is_targetable(Vector2i(50, 50)))


func test_fog_filter_unknown_cell_not_targetable() -> void:
	assert_false(_filter.is_targetable(Vector2i(5, 5)))


func test_fog_filter_visible_cell_is_targetable() -> void:
	_fog.reveal_from_position(Vector2i(3, 3), 2)
	assert_true(_filter.is_targetable(Vector2i(3, 3)))


func test_fog_filter_explored_cell_not_targetable() -> void:
	_fog.reveal_from_position(Vector2i(3, 3), 2)
	_fog.recalculate_visible([Vector2i(10, 10)], [2])
	assert_false(_filter.is_targetable(Vector2i(3, 3)))


func test_fog_filter_filter_positions_removes_unknown() -> void:
	_fog.reveal_from_position(Vector2i(0, 0), 1)
	var positions: Array = [Vector2i(0, 0), Vector2i(10, 10)]
	var filtered: Array = _filter.filter_positions(positions)
	assert_eq(filtered.size(), 1)
	assert_eq(filtered[0], Vector2i(0, 0))


func test_fog_filter_filter_positions_no_fog_passes_all() -> void:
	var f := FogTargetFilter.new()
	var positions: Array = [Vector2i(0, 0), Vector2i(10, 10)]
	var filtered: Array = f.filter_positions(positions)
	assert_eq(filtered.size(), 2)
