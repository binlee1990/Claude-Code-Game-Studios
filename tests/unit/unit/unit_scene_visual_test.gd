extends RefCounted

const UnitScene = preload("res://src/unit/Unit.tscn")

var _scene_tree: SceneTree

func set_scene_tree(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree

func _make_unit(faction: Faction.Type) -> Unit:
	var unit: Unit = UnitScene.instantiate()
	var stats := UnitStats.new()
	unit.initialize(stats, faction)
	_scene_tree.root.add_child(unit)
	unit._ready()
	return unit

func test_unit_scene_has_expected_visual_nodes() -> void:
	var unit: Unit = UnitScene.instantiate()

	var color_rect: ColorRect = unit.get_node("ColorRect")
	var label: Label = unit.get_node("Label")

	assert(color_rect.size == Vector2(48, 48))
	assert(color_rect.position == Vector2(-24, -24))
	assert(label.text == "HP: 10/10")
	assert(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	unit.free()

func test_player_unit_uses_blue_faction_color() -> void:
	var unit := _make_unit(Faction.Type.PLAYER)
	var color_rect: ColorRect = unit.get_node("ColorRect")

	assert(color_rect.modulate == Color("#3B82F6"))
	unit.free()

func test_enemy_unit_uses_red_faction_color() -> void:
	var unit := _make_unit(Faction.Type.ENEMY)
	var color_rect: ColorRect = unit.get_node("ColorRect")

	assert(color_rect.modulate == Color("#EF4444"))
	unit.free()

func test_acted_unit_uses_gray_half_alpha_modulate() -> void:
	var unit := _make_unit(Faction.Type.PLAYER)
	unit.has_acted_this_turn = true
	unit._update_visual()
	var color_rect: ColorRect = unit.get_node("ColorRect")
	var expected := Color.GRAY
	expected.a = 0.5

	assert(color_rect.modulate == expected)
	unit.free()
