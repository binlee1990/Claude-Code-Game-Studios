extends RefCounted

const HUDScene = preload("res://src/ui/HUD.tscn")
const NullAI = preload("res://src/ai/null_ai.gd")

var _scene_tree: SceneTree

func set_scene_tree(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree

func _make_unit(faction: Faction.Type) -> Unit:
	var stats := UnitStats.new()
	var unit := Unit.new()
	unit.initialize(stats, faction)
	return unit

func _make_turn_manager() -> TurnManager:
	var manager := TurnManager.new()
	var config := TurnConfig.new()
	manager.initialize(
		[
			_make_unit(Faction.Type.PLAYER),
			_make_unit(Faction.Type.ENEMY),
		],
		config,
		VictoryChecker.new(),
		NullAI.new()
	)
	return manager

func _make_hud() -> HUD:
	var hud: HUD = HUDScene.instantiate()
	_scene_tree.root.add_child(hud)
	hud._turn_label = hud.get_node("TurnLabel")
	hud._faction_label = hud.get_node("FactionLabel")
	hud._end_turn_button = hud.get_node("EndTurnButton")
	hud._ready()
	return hud

func test_hud_starts_hidden_after_initialize() -> void:
	var hud := _make_hud()
	hud.initialize(_make_turn_manager())

	assert(not hud._turn_label.visible)
	assert(not hud._faction_label.visible)
	assert(not hud._end_turn_button.visible)
	hud.free()

func test_hud_updates_turn_and_player_faction_on_match_start() -> void:
	var hud := _make_hud()
	var manager := _make_turn_manager()
	hud.initialize(manager)

	manager.start_match()

	assert(hud._turn_label.visible)
	assert(hud._turn_label.text == "Turn 1/30")
	assert(hud._faction_label.visible)
	assert(hud._faction_label.text == "Player Turn")
	assert(hud._faction_label.modulate == Color("#3B82F6"))
	assert(hud._end_turn_button.visible)
	hud.free()

func test_hud_end_turn_button_delegates_to_turn_manager() -> void:
	var hud := _make_hud()
	var manager := _make_turn_manager()
	hud.initialize(manager)
	manager.start_match()

	hud._end_turn_button.pressed.emit()

	assert(manager.active_faction == Faction.Type.ENEMY)
	assert(hud._faction_label.text == "Enemy Turn")
	assert(hud._faction_label.modulate == Color("#EF4444"))
	hud.free()

func test_hud_hides_end_turn_button_when_match_ends() -> void:
	var hud := _make_hud()
	var manager := _make_turn_manager()
	hud.initialize(manager)
	manager.start_match()

	manager.match_ended.emit("elimination", Faction.Type.PLAYER)

	assert(not hud._end_turn_button.visible)
	hud.free()

func test_hud_controls_are_outside_board_area() -> void:
	var hud := _make_hud()
	var panel: ColorRect = hud.get_node("HudPanel")
	var board_width := GridSpace.TILE_SIZE * 16

	assert(panel.position.x == board_width)
	assert(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(hud._turn_label.position.x > board_width)
	assert(hud._faction_label.position.x > board_width)
	assert(hud._end_turn_button.position.x > board_width)
	hud.free()
