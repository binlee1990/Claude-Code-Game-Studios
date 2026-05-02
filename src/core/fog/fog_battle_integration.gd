class_name FogBattleIntegration
extends RefCounted

## Handles fog-of-war lifecycle during a battle:
##   - Reads fog config from battle_definition
##   - Initializes / clears FogStateManager
##   - Provides vision recalculation hooks for battle_arena
##   - Exposes targeting filter for combat actions
##
## Usage from battle_arena:
##   var fog := FogBattleIntegration.new()
##   fog.init_from_definition(battle_definition)
##
##   # Each turn start / after movement:
##   fog.recalculate_vision(visible_unit_positions, vision_ranges)
##
##   # Before targeting:
##   if not fog.is_cell_targetable(cell):
##       return  # can't target fog-hidden cells

var _fog_state: FogStateManager = null
var _target_filter: FogTargetFilter = null
var _fog_config: Dictionary = {}
var _fog_enabled: bool = false


func init_from_definition(battle_definition: Dictionary) -> void:
	_fog_config = battle_definition.get("fog", {})
	_fog_enabled = bool(_fog_config.get("enabled", false))
	_fog_state = FogStateManager.new()
	_fog_state.set_enabled(_fog_enabled)
	_target_filter = FogTargetFilter.new()
	_target_filter.setup(_fog_state)

	if _fog_enabled:
		var base_vision: int = int(_fog_config.get("base_vision", 3))
		_fog_state.BASE_VISION = base_vision


func is_enabled() -> bool:
	return _fog_enabled


func is_cell_targetable(cell: Vector2i) -> bool:
	if _target_filter == null:
		return true
	return _target_filter.is_targetable(cell)


func recalculate_vision(unit_positions: Array, vision_ranges: Array) -> void:
	if _fog_state == null:
		return
	_fog_state.recalculate_visible(unit_positions, vision_ranges)


func reveal_area(pos: Vector2i, radius: int) -> void:
	if _fog_state == null:
		return
	_fog_state.reveal_from_position(pos, radius)


func get_explored_cells() -> Array:
	if _fog_state == null:
		return []
	return _fog_state.get_explored_cells()


func set_explored_cells(cells: Array) -> void:
	if _fog_state == null:
		return
	_fog_state.set_explored_cells(cells)


func get_fog_state() -> FogStateManager:
	return _fog_state


func get_target_filter() -> FogTargetFilter:
	return _target_filter


func get_config() -> Dictionary:
	return _fog_config.duplicate(true)
