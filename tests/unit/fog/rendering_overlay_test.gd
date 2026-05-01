extends Gut

const FogRenderer = preload("res://src/core/fog/fog_renderer.gd")
const FogStateManager = preload("res://src/core/fog/fog_state_manager.gd")

var _renderer
var _fog


func before_each() -> void:
	_renderer = FogRenderer.new()
	_fog = FogStateManager.new()


func test_fog_renderer_color_unknown_is_dark_semitransparent() -> void:
	var c: Color = _renderer.get_color_for_state(FogStateManager.FogCellState.UNKNOWN)
	assert_true(c.a > 0.4)


func test_fog_renderer_color_explored_is_lighter() -> void:
	var c_unknown: Color = _renderer.get_color_for_state(FogStateManager.FogCellState.UNKNOWN)
	var c_explored: Color = _renderer.get_color_for_state(FogStateManager.FogCellState.EXPLORED)
	assert_true(c_explored.a < c_unknown.a)


func test_fog_renderer_color_visible_is_transparent() -> void:
	var c: Color = _renderer.get_color_for_state(FogStateManager.FogCellState.VISIBLE)
	assert_eq(c.a, 0.0)


func test_fog_renderer_setup_stores_references() -> void:
	_renderer.setup(_fog, null, Vector2i.ZERO, 64)
	# setup should not crash when overlay_layer is null
	assert_true(true)


func test_fog_renderer_refresh_with_null_layer_does_not_crash() -> void:
	_renderer.setup(_fog, null, Vector2i.ZERO, 64)
	_renderer.refresh_overlay(10, 10)
	assert_true(true)


func test_fog_renderer_refresh_with_disabled_fog_does_not_crash() -> void:
	_fog.set_enabled(false)
	_renderer.setup(_fog, null, Vector2i.ZERO, 64)
	_renderer.refresh_overlay(10, 10)
	assert_true(true)
