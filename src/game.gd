class_name Game extends Node2D

var grid_space: GridSpace
var map: Map
var turn_manager: TurnManager

func _ready() -> void:
	grid_space = GridSpace.new()

	map = load("res://src/map/Map.tscn").instantiate()
	add_child(map)
	map.initialize(grid_space, "test_map")

	var units := _create_units()
	for u in units:
		u.unit_died.connect(_on_unit_died)

	turn_manager = TurnManager.new()
	turn_manager.initialize(units, TurnConfig.new(), VictoryChecker.new(), NullAI.new())
	turn_manager.start_match()

func _create_units() -> Array:
	var unit_scene := load("res://src/unit/Unit.tscn")
	var player_stats := UnitStats.new()
	var enemy_stats := UnitStats.new()
	enemy_stats.max_hp = 8
	enemy_stats.atk = 4
	enemy_stats.def = 1
	enemy_stats.mov = 3

	var result: Array = []

	var u1 := unit_scene.instantiate() as Unit
	u1.initialize(player_stats, Faction.Type.PLAYER)
	_place_unit(u1, Vector2i(5, 2))
	result.append(u1)

	var u2 := unit_scene.instantiate() as Unit
	u2.initialize(player_stats, Faction.Type.PLAYER)
	_place_unit(u2, Vector2i(5, 4))
	result.append(u2)

	var e1 := unit_scene.instantiate() as Unit
	e1.initialize(enemy_stats, Faction.Type.ENEMY)
	_place_unit(e1, Vector2i(5, 10))
	result.append(e1)

	var e2 := unit_scene.instantiate() as Unit
	e2.initialize(enemy_stats, Faction.Type.ENEMY)
	_place_unit(e2, Vector2i(5, 12))
	result.append(e2)

	return result

func _place_unit(unit: Unit, coord: Vector2i) -> void:
	add_child(unit)
	unit.position = grid_space.tile_center(coord)
	map.place_unit(unit, coord)

func _on_unit_died(unit: Unit) -> void:
	map.remove_unit(unit.grid_position)
	unit.queue_free()
