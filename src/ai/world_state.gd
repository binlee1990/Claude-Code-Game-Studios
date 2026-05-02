class_name WorldState extends RefCounted

var all_units: Array = []
var map: Map
var _occupancy_snapshot: Dictionary = {}

func clone() -> WorldState:
	var ws := WorldState.new()
	ws.all_units = all_units.duplicate()
	ws.map = map
	ws._occupancy_snapshot = _occupancy_snapshot.duplicate()
	return ws
