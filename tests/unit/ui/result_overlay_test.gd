extends RefCounted

const ResultOverlayScene = preload("res://src/ui/ResultOverlay.tscn")

var _scene_tree: SceneTree

func set_scene_tree(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree

func _make_overlay() -> ResultOverlay:
	var overlay: ResultOverlay = ResultOverlayScene.instantiate()
	_scene_tree.root.add_child(overlay)
	overlay._background = overlay.get_node("Background")
	overlay._title_label = overlay.get_node("TitleLabel")
	overlay._reason_label = overlay.get_node("ReasonLabel")
	overlay._play_again_button = overlay.get_node("PlayAgainButton")
	overlay._ready()
	return overlay

func test_result_overlay_starts_hidden_after_initialize() -> void:
	var overlay := _make_overlay()
	overlay.initialize(TurnManager.new())

	assert(not overlay._background.visible)
	assert(not overlay._title_label.visible)
	assert(not overlay._reason_label.visible)
	assert(not overlay._play_again_button.visible)
	overlay.free()

func test_result_overlay_uses_blocking_dim_background() -> void:
	var overlay := _make_overlay()

	assert(overlay._background.color == Color(0, 0, 0, 0.7))
	assert(overlay._background.mouse_filter == Control.MOUSE_FILTER_STOP)
	overlay.free()

func test_result_overlay_shows_victory_defeat_and_draw_styles() -> void:
	var overlay := _make_overlay()

	overlay._on_match_ended("elimination", Faction.Type.PLAYER)
	assert(overlay._title_label.text == "VICTORY")
	assert(overlay._title_label.modulate == Color("#10B981"))
	assert(overlay._reason_label.text == "elimination")
	assert(overlay._play_again_button.visible)

	overlay._on_match_ended("elimination", Faction.Type.ENEMY)
	assert(overlay._title_label.text == "DEFEAT")
	assert(overlay._title_label.modulate == Color("#EF4444"))

	overlay._on_match_ended("turn_cap", Faction.Type.NONE)
	assert(overlay._title_label.text == "DRAW")
	assert(overlay._title_label.modulate == Color("#9CA3AF"))
	assert(overlay._reason_label.text == "turn_cap")
	overlay.free()

func test_result_overlay_listens_to_turn_manager_match_ended_signal() -> void:
	var overlay := _make_overlay()
	var manager := TurnManager.new()
	overlay.initialize(manager)

	manager.match_ended.emit("turn_cap", Faction.Type.NONE)

	assert(overlay._background.visible)
	assert(overlay._title_label.text == "DRAW")
	assert(overlay._reason_label.text == "turn_cap")
	overlay.free()

func test_play_again_button_is_connected_to_reload_handler() -> void:
	var overlay := _make_overlay()
	var callback := Callable(overlay, "_on_play_again_pressed")

	assert(overlay._play_again_button.pressed.is_connected(callback))
	overlay.free()
