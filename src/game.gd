class_name Game extends Node2D

const ENEMY_AI_MODE_SETTING := "srpg_mini/enemy_ai_mode"
const ENEMY_AI_MODE_HOTSEAT := "hotseat"
const ENEMY_AI_MODE_BASIC := "basic"

var grid_space: GridSpace
var map: Map
var turn_manager: TurnManager

var _input_handler: InputHandler
var _move_highlight: HighlightLayer
var _path_highlight: HighlightLayer
var _attack_highlight: HighlightLayer
var _damage_preview_label: Label
var _debug_overlay: DebugOverlay

func _ready() -> void:
	# 1. GridSpace
	grid_space = GridSpace.new()

	# 2. Map
	map = load("res://src/map/Map.tscn").instantiate()
	add_child(map)
	map.initialize(grid_space, "test_map")

	# 3. Units
	var units := _create_units()
	for u in units:
		u.unit_died.connect(_on_unit_died)

	# 4. Resolvers
	var movement_resolver := MovementResolver.new()
	var attack_resolver := AttackResolver.new()
	var attack_range_resolver := AttackRangeResolver.new()

	# 5. TurnManager (create + inject, start later after all UI wired)
	turn_manager = TurnManager.new()
	turn_manager.initialize(units, TurnConfig.new(), VictoryChecker.new(),
		_create_enemy_ai_controller(), map, attack_resolver)

	# 6. InputHandler
	_input_handler = InputHandler.new()
	_input_handler.initialize(map, grid_space, turn_manager,
		movement_resolver, attack_resolver, attack_range_resolver, units)

	# 7. HighlightLayers (z_index: move=1, path=2, attack=3)
	_move_highlight = _create_highlight_layer(Color("#0891B2"), 1)
	_path_highlight = _create_highlight_layer(Color("#06B6D4"), 2)
	_attack_highlight = _create_highlight_layer(Color("#EA580C"), 3)

	# 8. Debug Overlay (z=10)
	_debug_overlay = DebugOverlay.new()
	_debug_overlay.initialize(grid_space, map)
	_debug_overlay.z_index = 10
	add_child(_debug_overlay)

	# 9. Damage preview label
	_damage_preview_label = Label.new()
	_damage_preview_label.visible = false
	_damage_preview_label.size = Vector2(128, 48)
	_damage_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_preview_label.add_theme_font_size_override("font_size", 14)
	_damage_preview_label.add_theme_constant_override("outline_size", 3)
	_damage_preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_damage_preview_label.z_index = 20
	add_child(_damage_preview_label)

	# 10. HUD
	var hud: HUD = load("res://src/ui/HUD.tscn").instantiate()
	add_child(hud)
	hud.initialize(turn_manager)

	# 11. ResultOverlay
	var result_overlay: ResultOverlay = load("res://src/ui/ResultOverlay.tscn").instantiate()
	add_child(result_overlay)
	result_overlay.initialize(turn_manager)

	# 12. Wire InputHandler -> HighlightLayers
	_input_handler.move_highlights_changed.connect(_move_highlight.set_highlight)
	_input_handler.path_highlights_changed.connect(_path_highlight.set_highlight)
	_input_handler.attack_highlights_changed.connect(_attack_highlight.set_highlight)
	_input_handler.damage_preview_requested.connect(_on_damage_preview)
	_input_handler.preview_cleared.connect(_hide_preview)

	# 13. Wire post-attack damage display
	attack_resolver.damage_dealt.connect(_on_damage_dealt)

	# 14. Wire faction_phase_ended -> clear all UI state
	turn_manager.faction_phase_ended.connect(_on_phase_ended)

	# 15. Start match (all signal listeners connected)
	turn_manager.start_match()

func _create_highlight_layer(color: Color, z: int) -> HighlightLayer:
	var layer := HighlightLayer.new()
	layer.initialize(grid_space, color)
	layer.z_index = z
	add_child(layer)
	return layer

func _create_enemy_ai_controller(user_args: Array = []) -> AIController:
	var mode := _resolve_enemy_ai_mode(user_args)
	if mode == ENEMY_AI_MODE_BASIC:
		return BasicAI.new()
	return NullAI.new()

func _resolve_enemy_ai_mode(user_args: Array = []) -> String:
	var configured_mode := str(ProjectSettings.get_setting(
		ENEMY_AI_MODE_SETTING,
		ENEMY_AI_MODE_HOTSEAT,
	))
	var mode := _normalize_enemy_ai_mode(configured_mode)
	var args := user_args
	if args.is_empty():
		args = OS.get_cmdline_user_args()

	for i in range(args.size()):
		var arg := str(args[i])
		if arg.begins_with("--enemy-ai="):
			mode = _normalize_enemy_ai_mode(arg.get_slice("=", 1))
		elif arg == "--enemy-ai" and i + 1 < args.size():
			mode = _normalize_enemy_ai_mode(str(args[i + 1]))
	return mode

func _normalize_enemy_ai_mode(raw_mode: String) -> String:
	var normalized := raw_mode.strip_edges().to_lower()
	if normalized in [ENEMY_AI_MODE_BASIC, "basic_ai", "ai"]:
		return ENEMY_AI_MODE_BASIC
	if normalized in [ENEMY_AI_MODE_HOTSEAT, "null", "null_ai", "manual", ""]:
		return ENEMY_AI_MODE_HOTSEAT

	push_warning("Unknown enemy AI mode '%s'; falling back to hotseat" % raw_mode)
	return ENEMY_AI_MODE_HOTSEAT

func _on_damage_preview(attacker: Unit, target: Unit, damage: int) -> void:
	_damage_preview_label.text = "-%d\nATK %d - DEF %d" % [damage, attacker.atk, target.def]
	_damage_preview_label.position = target.position + Vector2(-64, -84)
	if damage >= target.hp:
		_set_damage_preview_color(Color("#EF4444"))
	else:
		_set_damage_preview_color(Color("#F59E0B"))
	_damage_preview_label.visible = true

func _hide_preview() -> void:
	_damage_preview_label.visible = false

func _on_damage_dealt(_attacker: Unit, target: Unit, damage: int) -> void:
	_damage_preview_label.text = "-%d" % damage
	_damage_preview_label.position = target.position + Vector2(-64, -76)
	_set_damage_preview_color(Color("#EF4444"))
	_damage_preview_label.visible = true
	get_tree().create_timer(0.6).timeout.connect(_hide_preview)

func _set_damage_preview_color(color: Color) -> void:
	_damage_preview_label.add_theme_color_override("font_color", color)

func _on_phase_ended(_faction: Faction.Type) -> void:
	_input_handler.force_clear()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_QUOTELEFT and event.pressed:
		_debug_overlay.toggle()
		return
	_input_handler.handle_event(event)

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
	map.place_unit(unit, coord)

func _on_unit_died(unit: Unit) -> void:
	map.remove_unit(unit.grid_position)
	unit.queue_free()
