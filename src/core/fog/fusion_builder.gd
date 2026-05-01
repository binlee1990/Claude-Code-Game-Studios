class_name FusionBuilder
extends RefCounted

func color(c: Color) -> TileData:
	var td := TileData.new()
	td.modulate = c
	return td
