extends SceneTree

func _init():
	print("Generating tile atlas texture...")
	var img := Image.create(192, 64, false, Image.FORMAT_RGB8)

	img.fill_rect(Rect2i(0, 0, 64, 64), Color("#374151"))
	img.fill_rect(Rect2i(64, 0, 64, 64), Color("#111827"))
	img.fill_rect(Rect2i(128, 0, 64, 64), Color("#1F2937"))

	var png_path := "res://assets/data/tile_atlas.png"
	img.save_png(png_path)
	print("Saved: ", png_path)

	print("Generating TileSet...")
	var tileset := TileSet.new()
	var atlas := TileSetAtlasSource.new()
	atlas.texture_region_size = Vector2i(64, 64)
	atlas.texture = load(png_path)
	tileset.add_source(atlas, 0)
	print("TileSet source added, tiles at atlas coords: (0,0) walkable, (1,0) blocked, (2,0) obstacle")

	var tres_path := "res://assets/data/tileset.tres"
	ResourceSaver.save(tileset, tres_path)
	print("Saved: ", tres_path)

	quit(0)
