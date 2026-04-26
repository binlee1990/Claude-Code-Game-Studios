class_name VSBattle
extends Control
## Canonical vertical-slice battle scene.
## Combines the playable combat loop with the current Camera / UI / Save
## productization layer used by the formal `battle_arena.tscn` entry path.

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")
const BattleDefinitionLoader := preload("res://src/ui/combat/battle_definition_loader.gd")
const BattleDifficultyProfile := preload("res://src/ui/combat/battle_difficulty_profile.gd")
const SRPGAudioBusScript := preload("res://src/ui/audio/srpg_audio_bus.gd")
const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")
const HintBarScript := preload("res://src/ui/common/hint_bar.gd")

const GRID_SIZE := 15
const CELL_SIZE := 64
const MARGIN := 20
const DEFAULT_MAP_SIZE := 15
const DEFAULT_BATTLE_DEFINITION_PATH := "res://src/ui/combat/battle_definitions/chapter_01_tutorial.json"
const MAP_SIZE_OPTIONS := [15, 20, 25]
const _RENDER_CELL_SIZES := {15: 42.0, 20: 32.0, 25: 26.0}
const _MIN_CONTROLLED_TURN_DELAY := 0.18
const _MAX_CONTROLLED_TURN_DELAY := 0.65
const _MOVE_TWEEN_DURATION := 0.18
const _ATTACK_LUNGE_DURATION := 0.08
const _ATTACK_RECOVER_DURATION := 0.10
const _HIT_FLASH_DURATION := 0.22
const _DEATH_FADE_DURATION := 0.36
const _CAMERA_ROTATION_DEGREES := [0]
const _SCENE_KEY := "battle"
const _CHAPTER_01_TO_CHAPTER_02_PATH := "res://src/ui/combat/battle_definitions/chapter_02_act_a.json"
const _DEFAULT_UI_PREFERENCES := {
	"master_volume": 70,
	"sfx_volume": 70,
	"bgm_volume": 70,
	"screen_mode": "windowed",
	"last_menu_tab": "character",
}
const _DEFAULT_CAMERA_PREFERENCES := {
	"rotation_index": 0,
	"grid_overlay_enabled": true,
	"map_size": DEFAULT_MAP_SIZE,
}

enum VSPhase { SELECT_UNIT, SELECT_MOVE, SELECT_TARGET, ANIMATING, ENEMY_TURN, BATTLE_END }

var _combat: CombatSystem
var _actions: ActionSystem
var _inventory: Inventory
var _roster: CharacterRoster
var _speed_controller: SpeedController
var _auto_battle_controller: AutoBattleController
var _battle_history_log: BattleHistoryLog

var _phase: int = VSPhase.SELECT_UNIT
var _selected_unit: Unit = null
var _targeting_skill_id: StringName = &""
var _grid_units: Dictionary = {}  # Vector2i -> Unit
var _unit_cells: Dictionary = {}  # Unit -> Vector2i
var _move_range: Array = []
var _attack_range: Array = []

var _map_size: int = DEFAULT_MAP_SIZE
var _camera_rotation: int = 0
var _grid_overlay_enabled: bool = true
var _map_heights: Dictionary = {}  # Vector2i -> int
var _map_terrain: Dictionary = {}  # Vector2i -> TerrainTypes.Terrain
var _render_cell_size: float = 52.0
var _menu_open: bool = false
var _active_menu_tab: String = "character"
var _ui_preferences: Dictionary = _DEFAULT_UI_PREFERENCES.duplicate(true)
var _camera_preferences: Dictionary = _DEFAULT_CAMERA_PREFERENCES.duplicate(true)
var _battle_end_emitted: bool = false
var _turn_sequence_running: bool = false
var _controlled_turn_plan: Dictionary = {}
var _controlled_turn_timer: float = 0.0
var _unit_move_tweens: Dictionary = {}
var _unit_flash_tweens: Dictionary = {}
var _unit_death_tweens: Dictionary = {}
var _battle_definition: Dictionary = {}
var _difficulty_profile: Dictionary = {}
var _boss_profiles: Dictionary = {}
var _boss_states: Dictionary = {}
var _story_progress: Dictionary = {}
var _settlement_reward_summary: Dictionary = {}
var _player_damage_taken: int = 0
var _player_deaths: int = 0
var _unit_tactical_profiles: Dictionary = {}
var _last_camp_report: String = "No camp actions yet."
var _active_management_tab: String = "rewards"
var _audio_bus: SRPGAudioBus = null

# UI references
var _root_layout: VBoxContainer
var _top_bar: HBoxContainer
var _grid_area: Panel
var _grid_container: Control
var _cells: Dictionary = {}  # Vector2i -> ColorRect
var _cell_centers: Dictionary = {}  # Vector2i -> Vector2
var _cell_height_labels: Dictionary = {}  # Vector2i -> Label
var _unit_panels: Dictionary = {}  # Unit -> Panel
var _unit_labels: Dictionary = {}  # Unit -> Label
var _hp_bars: Dictionary = {}  # Unit -> ProgressBar
var _turn_list: VBoxContainer
var _action_bar: HBoxContainer
var _action_buttons: Dictionary = {}
var _resource_labels: Dictionary = {}
var _status_name_label: Label
var _status_hp_label: Label
var _status_mp_label: Label
var _status_misc_label: Label
var _info_label: Label
var _objective_label: Label
var _boss_label: Label
var _result_label: Label
var _camera_state_label: Label
var _auto_button: Button
var _auto_badge_label: Label
var _speed_badge_label: Label
var _hint_bar: Control
var _menu_layer: CanvasLayer
var _menu_blocker: ColorRect
var _menu_panel: Panel
var _menu_content_label: Label
var _menu_buttons: Dictionary = {}
var _settlement_layer: CanvasLayer
var _settlement_blocker: ColorRect
var _settlement_panel: Panel
var _settlement_title_label: Label
var _settlement_summary_label: Label
var _settlement_next_label: Label
var _settlement_continue_btn: Button
var _settlement_main_menu_btn: Button
var _management_layer: CanvasLayer
var _management_blocker: ColorRect
var _management_panel: Panel
var _management_title_label: Label
var _management_content_label: Label
var _management_buttons: Dictionary = {}
var _is_chapter_transitioning: bool = false

func _ready() -> void:
	add_to_group("save_state_provider")
	_build_ui()
	_bind_global_events()
	_reset_runtime_systems()

	if SaveManager.has_pending_loaded_data():
		var save_data: SaveData = SaveManager.consume_pending_loaded_data()
		_apply_loaded_save_data(save_data)
	else:
		_load_default_battle()

	_refresh_all()
	# AUDIO-P0-08: 战斗 BGM
	_setup_battle_bgm()

func _setup_battle_bgm() -> void:
	var stream: AudioStream = load("res://assets/audio/bgm/battle_bgm.ogg")
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var player := AudioStreamPlayer.new()
	player.name = "BattleBGM"
	player.stream = stream
	player.volume_db = -12.0
	player.autoplay = true
	add_child(player)

func _process(delta: float) -> void:
	if not _turn_sequence_running:
		return
	_controlled_turn_timer -= delta
	if _controlled_turn_timer <= 0.0:
		_advance_controlled_turn_step()

func _build_ui() -> void:
	var backdrop := InkBackdrop.new()
	backdrop.name = "BattleInkBackdrop"
	backdrop.intensity = 0.72
	backdrop.show_moon = false
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_root_layout = VBoxContainer.new()
	_root_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_layout.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root_layout.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root_layout.add_theme_constant_override("separation", 8)
	add_child(_root_layout)

	var top_plate := PanelContainer.new()
	top_plate.custom_minimum_size = Vector2(0, 54)
	top_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(top_plate, Color(0.075, 0.064, 0.060, 0.94), SRPGTheme.GOLD)
	_root_layout.add_child(top_plate)

	_top_bar = HBoxContainer.new()
	_top_bar.add_theme_constant_override("separation", 8)
	top_plate.add_child(_top_bar)

	_build_top_bar()

	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_layout.add_child(hsplit)

	_grid_area = Panel.new()
	_grid_area.custom_minimum_size = _calculate_grid_area_size(DEFAULT_MAP_SIZE)
	_grid_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_area.mouse_filter = Control.MOUSE_FILTER_PASS
	_grid_area.resized.connect(_on_grid_area_resized)
	SRPGTheme.apply_panel(_grid_area, Color(0.060, 0.060, 0.058, 0.92), SRPGTheme.GOLD)
	hsplit.add_child(_grid_area)

	_grid_container = Control.new()
	_grid_container.position = Vector2.ZERO
	_grid_container.size = _grid_area.custom_minimum_size
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_area.add_child(_grid_container)

	var right_plate := PanelContainer.new()
	right_plate.custom_minimum_size = Vector2(330, 0)
	right_plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(right_plate, Color(0.070, 0.062, 0.058, 0.94), SRPGTheme.GOLD)
	hsplit.add_child(right_plate)

	var right_panel := VBoxContainer.new()
	right_panel.add_theme_constant_override("separation", 8)
	right_plate.add_child(right_panel)

	var turn_label := Label.new()
	turn_label.text = "Turn Order / 出手序"
	SRPGTheme.apply_label(turn_label, SRPGTheme.GOLD, 16)
	right_panel.add_child(turn_label)

	_turn_list = VBoxContainer.new()
	_turn_list.add_theme_constant_override("separation", 4)
	right_panel.add_child(_turn_list)

	var status_title := Label.new()
	status_title.text = "Status / 身法"
	SRPGTheme.apply_label(status_title, SRPGTheme.GOLD, 16)
	right_panel.add_child(status_title)

	var status_panel := VBoxContainer.new()
	status_panel.add_theme_constant_override("separation", 4)
	right_panel.add_child(status_panel)

	_status_name_label = Label.new()
	SRPGTheme.apply_label(_status_name_label, SRPGTheme.WHITE, 16)
	status_panel.add_child(_status_name_label)
	_status_hp_label = Label.new()
	SRPGTheme.apply_label(_status_hp_label, SRPGTheme.PAPER, 15)
	status_panel.add_child(_status_hp_label)
	_status_mp_label = Label.new()
	SRPGTheme.apply_label(_status_mp_label, SRPGTheme.PAPER, 15)
	status_panel.add_child(_status_mp_label)
	_status_misc_label = Label.new()
	_status_misc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_status_misc_label, SRPGTheme.PAPER_MUTED, 14)
	status_panel.add_child(_status_misc_label)

	_info_label = Label.new()
	_info_label.text = "Loading battle..."
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_info_label, SRPGTheme.WHITE, 15)
	right_panel.add_child(_info_label)

	_objective_label = Label.new()
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_objective_label, SRPGTheme.PAPER_MUTED, 14)
	right_panel.add_child(_objective_label)

	_boss_label = Label.new()
	_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_boss_label, SRPGTheme.GOLD, 14)
	right_panel.add_child(_boss_label)

	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", 8)
	right_panel.add_child(_action_bar)
	_build_action_bar()

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_label.add_theme_font_size_override("font_size", 48)
	_result_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_result_label.add_theme_constant_override("shadow_offset_x", 2)
	_result_label.add_theme_constant_override("shadow_offset_y", 3)
	_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_label.visible = false
	add_child(_result_label)

	_build_menu_overlay()
	_build_management_overlay()
	_build_settlement_overlay()
	_build_audio_bus()

func _build_top_bar() -> void:
	var title := Label.new()
	title.text = SRPGLocalizationScript.translate("game.title")
	SRPGTheme.apply_label(title, SRPGTheme.WHITE, 20)
	_top_bar.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar.add_child(spacer)

	for resource_name in ["Gold", "Materials", "Fruit", "Protect"]:
		var label := Label.new()
		label.text = "%s: 0" % resource_name
		SRPGTheme.apply_label(label, SRPGTheme.PAPER, 14)
		_top_bar.add_child(label)
		_resource_labels[resource_name.to_lower()] = label

	var button_specs := [
		{"text": "Grid (G)", "cb": func() -> void: set_grid_overlay_enabled(not _grid_overlay_enabled)},
		{"text": "Map", "cb": _cycle_map_size},
		{"text": "Speed", "cb": _cycle_speed_tier},
		{"text": "Auto OFF (B)", "cb": _toggle_auto_battle},
		{"text": "Manage", "cb": func() -> void: open_management_screen("rewards")},
		{"text": "Menu (Esc)", "cb": _toggle_menu},
	]
	for spec in button_specs:
		var button := Button.new()
		button.text = spec["text"]
		button.focus_mode = Control.FOCUS_ALL
		SRPGTheme.apply_button(button, button.text.begins_with("Auto"), false, true)
		button.pressed.connect(spec["cb"])
		_top_bar.add_child(button)
		if button.text.begins_with("Auto"):
			_auto_button = button

	# UI-P0-02: Auto 状态徽章（[Auto] 红 / [手动] 绿），字号 14pt
	# _auto_button 已在上方 button_specs 循环中正确赋值，此处仅新增徽章 label
	_auto_badge_label = Label.new()
	_auto_badge_label.name = "AutoBadgeLabel"
	_auto_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auto_badge_label.custom_minimum_size = Vector2(68, 0)
	SRPGTheme.apply_label(_auto_badge_label, SRPGTheme.PAPER, 14)
	_top_bar.add_child(_auto_badge_label)
	# 速度档位标签（1x/2x/3x）
	_speed_badge_label = Label.new()
	_speed_badge_label.name = "SpeedBadgeLabel"
	SRPGTheme.apply_label(_speed_badge_label, SRPGTheme.PAPER_MUTED, 14)
	_top_bar.add_child(_speed_badge_label)

	_camera_state_label = Label.new()
	SRPGTheme.apply_label(_camera_state_label, SRPGTheme.PAPER_MUTED, 13)
	_top_bar.add_child(_camera_state_label)

func _build_action_bar() -> void:
	var action_specs := [
		{"id": "move", "text": "Move (1)", "cb": _on_action_move},
		{"id": "attack", "text": "Attack (2)", "cb": _on_action_attack},
		{"id": "skill", "text": "Skill (5)", "cb": _on_action_skill},
		{"id": "standby", "text": "Standby (3)", "cb": _on_action_standby},
		{"id": "end_turn", "text": "End Turn (4)", "cb": _on_action_end_turn},
	]
	var buttons: Array = []
	for spec in action_specs:
		var btn := Button.new()
		btn.text = spec["text"]
		btn.focus_mode = Control.FOCUS_ALL
		SRPGTheme.apply_button(btn, spec["id"] == "move", false, true)
		btn.pressed.connect(spec["cb"])
		_action_bar.add_child(btn)
		_action_buttons[spec["id"]] = btn
		buttons.append(btn)

	for i in range(buttons.size()):
		var current: Button = buttons[i]
		var next_btn: Button = buttons[(i + 1) % buttons.size()]
		var prev_btn: Button = buttons[(i - 1 + buttons.size()) % buttons.size()]
		current.focus_neighbor_right = current.get_path_to(next_btn)
		current.focus_neighbor_left = current.get_path_to(prev_btn)

func _build_menu_overlay() -> void:
	_menu_layer = CanvasLayer.new()
	add_child(_menu_layer)

	_menu_blocker = ColorRect.new()
	_menu_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_blocker.color = Color(0.0, 0.0, 0.0, 0.62)
	_menu_layer.add_child(_menu_blocker)

	_menu_panel = Panel.new()
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.custom_minimum_size = Vector2(520, 360)
	_menu_panel.position = Vector2(-260, -180)
	SRPGTheme.apply_panel(_menu_panel, Color(0.078, 0.068, 0.063, 0.98), SRPGTheme.GOLD)
	_menu_layer.add_child(_menu_panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_top = 16
	content.offset_right = -16
	content.offset_bottom = -16
	_menu_panel.add_child(content)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)

	var tab_specs := [
		{"id": "character", "text": "Character"},
		{"id": "campaign", "text": "Campaign"},
		{"id": "camp", "text": "Camp"},
		{"id": "equipment", "text": "Equipment"},
		{"id": "roster", "text": "Roster"},
		{"id": "tactics", "text": "Tactics"},
		{"id": "boss", "text": "Boss"},
		{"id": "settlement", "text": "Settlement"},
		{"id": "inventory", "text": "Inventory"},
		{"id": "save", "text": "Save/Load"},
		{"id": "settings", "text": "Settings"},
	]
	var buttons: Array = []
	for spec in tab_specs:
		var btn := Button.new()
		btn.text = spec["text"]
		btn.focus_mode = Control.FOCUS_ALL
		SRPGTheme.apply_button(btn, false, false, true)
		var tab_id: String = String(spec["id"])
		btn.pressed.connect(func() -> void:
			set_active_menu_tab(tab_id)
		)
		tabs.add_child(btn)
		_menu_buttons[tab_id] = btn
		buttons.append(btn)

	for i in range(buttons.size()):
		var current: Button = buttons[i]
		var next_btn: Button = buttons[(i + 1) % buttons.size()]
		var prev_btn: Button = buttons[(i - 1 + buttons.size()) % buttons.size()]
		current.focus_neighbor_right = current.get_path_to(next_btn)
		current.focus_neighbor_left = current.get_path_to(prev_btn)

	var menu_actions := HBoxContainer.new()
	menu_actions.add_theme_constant_override("separation", 8)
	content.add_child(menu_actions)
	var save_btn := Button.new()
	save_btn.text = "Save Slot 1 (F5)"
	save_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(save_btn, true, false, true)
	save_btn.pressed.connect(func() -> void:
		_save_to_slot(1)
	)
	menu_actions.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Load Slot 1 (F9)"
	load_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(load_btn, false, false, true)
	load_btn.pressed.connect(func() -> void:
		_load_from_slot(1)
	)
	menu_actions.add_child(load_btn)

	var camp_btn := Button.new()
	camp_btn.text = "Auto Camp"
	camp_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(camp_btn, false, false, true)
	camp_btn.pressed.connect(func() -> void:
		run_default_camp_plan()
	)
	menu_actions.add_child(camp_btn)

	var manage_btn := Button.new()
	manage_btn.text = SRPGLocalizationScript.translate("menu.manage")
	manage_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(manage_btn, true, false, true)
	manage_btn.pressed.connect(func() -> void:
		open_management_screen("rewards")
	)
	menu_actions.add_child(manage_btn)

	var next_btn := Button.new()
	next_btn.text = "Next Battle"
	next_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(next_btn, false, false, true)
	next_btn.pressed.connect(func() -> void:
		advance_to_next_battle()
	)
	menu_actions.add_child(next_btn)

	var main_menu_btn := Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(main_menu_btn, false, true, true)
	main_menu_btn.pressed.connect(_return_to_main_menu)
	menu_actions.add_child(main_menu_btn)

	_menu_content_label = Label.new()
	_menu_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(_menu_content_label, SRPGTheme.PAPER, 15)
	content.add_child(_menu_content_label)

	_set_menu_overlay_visible(false)

func _build_management_overlay() -> void:
	_management_layer = CanvasLayer.new()
	_management_layer.layer = 12
	add_child(_management_layer)

	_management_blocker = ColorRect.new()
	_management_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_management_blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	_management_layer.add_child(_management_blocker)

	_management_panel = Panel.new()
	_management_panel.set_anchors_preset(Control.PRESET_CENTER)
	_management_panel.custom_minimum_size = Vector2(720, 470)
	_management_panel.position = Vector2(-360, -235)
	SRPGTheme.apply_panel(_management_panel, Color(0.060, 0.056, 0.052, 0.99), SRPGTheme.JADE)
	_management_layer.add_child(_management_panel)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 18
	layout.offset_top = 18
	layout.offset_right = -18
	layout.offset_bottom = -18
	layout.add_theme_constant_override("separation", 12)
	_management_panel.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)

	_management_title_label = Label.new()
	_management_title_label.text = SRPGLocalizationScript.translate("management.title")
	_management_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(_management_title_label, SRPGTheme.WHITE, 24)
	header.add_child(_management_title_label)

	var close_btn := Button.new()
	close_btn.text = SRPGLocalizationScript.translate("management.close")
	close_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(close_btn, false, true, true)
	close_btn.pressed.connect(close_management_screen)
	header.add_child(close_btn)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)

	var tab_specs := [
		{"id": "rewards", "text": SRPGLocalizationScript.translate("management.rewards")},
		{"id": "camp", "text": SRPGLocalizationScript.translate("management.camp")},
		{"id": "party", "text": SRPGLocalizationScript.translate("management.party")},
		{"id": "equipment", "text": SRPGLocalizationScript.translate("management.equipment")},
	]
	for spec in tab_specs:
		var btn := Button.new()
		btn.text = spec["text"]
		btn.focus_mode = Control.FOCUS_ALL
		SRPGTheme.apply_button(btn, false, false, true)
		var tab_id := String(spec["id"])
		btn.pressed.connect(func() -> void:
			set_active_management_tab(tab_id)
		)
		tabs.add_child(btn)
		_management_buttons[tab_id] = btn

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	var run_camp_btn := Button.new()
	run_camp_btn.text = "Run Recommended Camp"
	run_camp_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(run_camp_btn, true, false, true)
	run_camp_btn.pressed.connect(func() -> void:
		run_default_camp_plan()
		set_active_management_tab("camp")
	)
	actions.add_child(run_camp_btn)

	var advance_btn := Button.new()
	advance_btn.text = "Advance Battle"
	advance_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(advance_btn, false, false, true)
	advance_btn.pressed.connect(func() -> void:
		advance_to_next_battle()
		set_active_management_tab("party")
	)
	actions.add_child(advance_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Slot 1"
	save_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(save_btn, false, false, true)
	save_btn.pressed.connect(func() -> void:
		_save_to_slot(1)
		set_active_management_tab(_active_management_tab)
	)
	actions.add_child(save_btn)

	_management_content_label = Label.new()
	_management_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_management_content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(_management_content_label, SRPGTheme.PAPER, 16)
	layout.add_child(_management_content_label)

	_set_management_overlay_visible(false)

func _build_settlement_overlay() -> void:
	_settlement_layer = CanvasLayer.new()
	_settlement_layer.layer = 25
	add_child(_settlement_layer)

	_settlement_blocker = ColorRect.new()
	_settlement_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settlement_blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	_settlement_layer.add_child(_settlement_blocker)

	_settlement_panel = Panel.new()
	_settlement_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settlement_panel.custom_minimum_size = Vector2(680, 380)
	_settlement_panel.position = Vector2(-340, -190)
	SRPGTheme.apply_panel(_settlement_panel, Color(0.034, 0.028, 0.024, 0.98), SRPGTheme.GOLD)
	_settlement_layer.add_child(_settlement_panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_top = 16
	content.offset_right = -16
	content.offset_bottom = -16
	content.add_theme_constant_override("separation", 12)
	_settlement_panel.add_child(content)

	_settlement_title_label = Label.new()
	_settlement_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label(_settlement_title_label, SRPGTheme.WHITE, 26)
	content.add_child(_settlement_title_label)

	_settlement_summary_label = Label.new()
	_settlement_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settlement_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(_settlement_summary_label, SRPGTheme.PAPER, 15)
	content.add_child(_settlement_summary_label)

	_settlement_next_label = Label.new()
	_settlement_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_settlement_next_label, SRPGTheme.PAPER_MUTED, 14)
	content.add_child(_settlement_next_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)

	_settlement_continue_btn = Button.new()
	_settlement_continue_btn.text = "Continue"
	_settlement_continue_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(_settlement_continue_btn, true, false, true)
	_settlement_continue_btn.pressed.connect(_on_settlement_continue_pressed)
	actions.add_child(_settlement_continue_btn)

	_settlement_main_menu_btn = Button.new()
	_settlement_main_menu_btn.text = "Return to Main Menu"
	_settlement_main_menu_btn.focus_mode = Control.FOCUS_ALL
	SRPGTheme.apply_button(_settlement_main_menu_btn, false, true, true)
	_settlement_main_menu_btn.pressed.connect(_return_to_main_menu)
	actions.add_child(_settlement_main_menu_btn)

	_set_settlement_overlay_visible(false)

func _build_audio_bus() -> void:
	_audio_bus = SRPGAudioBusScript.new()
	_audio_bus.name = "SRPGAudioBus"
	add_child(_audio_bus)

func _bind_global_events() -> void:
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.health_changed.connect(_on_health_changed)
	GameEvents.unit_died.connect(_on_unit_died)
	GameEvents.resource_changed.connect(_on_resource_changed)

func _reset_runtime_systems() -> void:
	_clear_unit_nodes()
	_destroy_runtime_nodes()

	_combat = CombatSystem.new()
	add_child(_combat)
	_actions = ActionSystem.new()
	add_child(_actions)
	_inventory = Inventory.new()
	add_child(_inventory)
	_roster = CharacterRoster.new()
	add_child(_roster)
	_speed_controller = SpeedController.new()
	_auto_battle_controller = AutoBattleController.new(AIBrain.new(AI.AIType.BALANCED))
	_battle_history_log = BattleHistoryLog.new()
	_combat.set_auto_battle_controller(_auto_battle_controller)

	_inventory.resource_changed.connect(func(resource_type: int, old_amount: int, new_amount: int) -> void:
		GameEvents.resource_changed.emit(resource_type, old_amount, new_amount)
		_refresh_resource_hud()
	)
	_inventory.resource_overflow.connect(func(resource_type: int, discarded: int) -> void:
		GameEvents.resource_overflow.emit(resource_type, discarded)
	)

	_phase = VSPhase.SELECT_UNIT
	_selected_unit = null
	_targeting_skill_id = &""
	_move_range.clear()
	_attack_range.clear()
	_boss_profiles.clear()
	_boss_states.clear()
	_settlement_reward_summary.clear()
	_unit_tactical_profiles.clear()
	_last_camp_report = "No camp actions yet."
	_player_damage_taken = 0
	_player_deaths = 0
	_battle_end_emitted = false
	_turn_sequence_running = false
	_controlled_turn_plan.clear()
	_controlled_turn_timer = 0.0

func _destroy_runtime_nodes() -> void:
	for node in [_combat, _actions, _inventory, _roster]:
		if is_instance_valid(node):
			node.free()

func _apply_default_preferences() -> void:
	_ui_preferences = _DEFAULT_UI_PREFERENCES.duplicate(true)
	_camera_preferences = _DEFAULT_CAMERA_PREFERENCES.duplicate(true)
	_camera_rotation = _camera_preferences["rotation_index"]
	_grid_overlay_enabled = _camera_preferences["grid_overlay_enabled"]
	_map_size = _camera_preferences["map_size"]
	_menu_open = false
	_active_menu_tab = _ui_preferences["last_menu_tab"]

func _seed_units_from_definition() -> void:
	var deployed_units: Array = []
	for entry in _battle_definition.get("units", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var unit := _create_unit_from_definition(entry)
		if unit != null and _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
			deployed_units.append(unit)
	_seed_roster_from_definition(deployed_units)
	var all_units: Array = _unit_cells.keys()
	_actions.initialize(all_units, _build_default_mp_config(all_units))
	_speed_controller.deserialize({"tier": SpeedController.SpeedTier.NORMAL})
	_auto_battle_controller.deserialize({"enabled": false})

func _load_default_battle() -> void:
	_apply_default_preferences()
	_hide_settlement_and_transient_overlays()
	if _result_label != null:
		_result_label.visible = false
		_result_label.text = ""
	_load_battle_definition(DEFAULT_BATTLE_DEFINITION_PATH)
	set_map_size(int(_battle_definition.get("map_size", DEFAULT_MAP_SIZE)))
	_story_progress = _battle_definition.get("progress_on_start", {}).duplicate(true)
	_seed_inventory_from_definition()
	_seed_units_from_definition()
	_combat.start_battle(get_battle_id(), _get_map_id(), int(_battle_definition.get("difficulty", 1)))
	_sync_phase_prompt()

func _load_battle_definition(path: String) -> void:
	_battle_definition = BattleDefinitionLoader.load_definition(path)
	if _battle_definition.is_empty():
		push_error("Falling back to empty battle definition for: " + path)
		_battle_definition = {
			"definition_path": path,
			"battle_id": "chapter_01_tutorial",
			"map_id": "training_pass",
			"chapter_title": "Chapter 1",
			"objective": "Defeat all enemies.",
			"map_size": DEFAULT_MAP_SIZE,
			"difficulty": 1,
			"progress_on_start": {"chapter": 1, "current_battle": "chapter_01_tutorial"},
			"progress_on_victory": {"chapter": 1, "chapter_01_complete": true},
			"difficulty_profile": {},
			"units": [],
		}
	_difficulty_profile = BattleDifficultyProfile.from_definition(_battle_definition)

## Return the active battle id used by settlement history and story progress.
func get_battle_id() -> String:
	return String(_battle_definition.get("battle_id", "chapter_01_tutorial"))

## Return the active story progress payload.
func get_story_progress() -> Dictionary:
	return _story_progress.duplicate(true)

## Return the active battle objective shown to players.
func get_objective_text() -> String:
	return String(_battle_definition.get("objective", "Defeat all enemies."))

## Return the active runtime difficulty profile.
func get_difficulty_profile() -> Dictionary:
	return _difficulty_profile.duplicate(true)

## Return the first active boss state exposed by the battle definition.
func get_boss_state() -> Dictionary:
	var boss := _get_primary_boss_unit()
	if boss == null:
		return {}
	var state: Dictionary = _boss_states.get(boss, {}).duplicate(true)
	state["boss_id"] = String(boss.unit_id)
	state["title"] = String(_boss_profiles.get(boss, {}).get("title", boss.display_name))
	return state

func _get_map_id() -> String:
	return String(_battle_definition.get("map_id", "training_pass"))

func _get_battle_definition_path() -> String:
	return String(_battle_definition.get("definition_path", DEFAULT_BATTLE_DEFINITION_PATH))

func _get_chapter_title() -> String:
	return String(_battle_definition.get("chapter_title", "Chapter 1"))

func _get_difficulty_summary() -> String:
	return BattleDifficultyProfile.format_summary(_difficulty_profile)

## Return the active campaign state used by menus and tests.
func get_campaign_state() -> Dictionary:
	return {
		"battle_id": get_battle_id(),
		"battle_definition_path": _get_battle_definition_path(),
		"next_battle_definition_path": _get_next_battle_definition_path(),
		"story_progress": _story_progress.duplicate(true),
		"camp_report": _last_camp_report,
		"briefing": get_briefing_text(),
		"chapter_complete": bool(_story_progress.get("chapter_01_complete", false)),
	}

## Return the active narrative briefing for campaign pacing screens.
func get_briefing_text() -> String:
	return String(_battle_definition.get("briefing", "No briefing available."))

func _set_menu_overlay_visible(is_visible: bool) -> void:
	if _menu_layer != null:
		_menu_layer.visible = is_visible
	if _menu_blocker != null:
		_menu_blocker.visible = is_visible
		_menu_blocker.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE
	if _menu_panel != null:
		_menu_panel.visible = is_visible
		_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

func _set_management_overlay_visible(is_visible: bool) -> void:
	if _management_layer != null:
		_management_layer.visible = is_visible
	if _management_blocker != null:
		_management_blocker.visible = is_visible
		_management_blocker.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE
	if _management_panel != null:
		_management_panel.visible = is_visible
		_management_panel.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

func _set_settlement_overlay_visible(is_visible: bool) -> void:
	if _settlement_layer != null:
		_settlement_layer.visible = is_visible
	if _settlement_blocker != null:
		_settlement_blocker.visible = is_visible
		_settlement_blocker.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE
	if _settlement_panel != null:
		_settlement_panel.visible = is_visible
		_settlement_panel.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

func _is_management_overlay_visible() -> bool:
	return _management_panel != null and _management_panel.visible

func _is_settlement_overlay_visible() -> bool:
	return _settlement_panel != null and _settlement_panel.visible

## Open the dedicated campaign readiness screen.
func open_management_screen(tab_name: String = "rewards") -> void:
	if _management_layer == null:
		return
	_menu_open = false
	_set_menu_overlay_visible(false)
	_set_management_overlay_visible(true)
	_play_ui_cue("menu")
	set_active_management_tab(tab_name)

func close_management_screen() -> void:
	if _management_layer == null:
		return
	_set_management_overlay_visible(false)
	_refresh_action_bar()

func set_active_management_tab(tab_name: String) -> void:
	if not ["rewards", "camp", "party", "equipment"].has(tab_name):
		tab_name = "rewards"
	_active_management_tab = tab_name
	for key in _management_buttons.keys():
		SRPGTheme.apply_button(_management_buttons[key] as Button, key == tab_name, false, true)
	_refresh_management_content()
	if _management_buttons.has(tab_name):
		(_management_buttons[tab_name] as Button).grab_focus()

func get_management_screen_state() -> Dictionary:
	return {
		"visible": _is_management_overlay_visible(),
		"tab": _active_management_tab,
		"title": _management_title_label.text if _management_title_label != null else "",
		"content": _management_content_label.text if _management_content_label != null else "",
	}

func get_audio_cue_history() -> Array[String]:
	if _audio_bus == null:
		return []
	return _audio_bus.get_played_cues()

func _play_ui_cue(cue_id: String) -> void:
	if _audio_bus != null:
		_audio_bus.play_cue(cue_id)

## Apply the default recommended camp plan.
func run_default_camp_plan() -> Dictionary:
	var result := _apply_default_camp_plan()
	_play_ui_cue("camp")
	_refresh_resource_hud()
	_refresh_status_panel()
	_refresh_menu_content()
	_refresh_management_content()
	return result

## Advance to the next campaign battle when the current battle has been cleared.
func advance_to_next_battle() -> bool:
	var next_path := _get_next_battle_definition_path()
	if next_path == "":
		_info_label.text = "No next battle is configured."
		_play_ui_cue("error")
		_refresh_menu_content()
		return false
	if _phase != VSPhase.BATTLE_END or not bool(_settlement_reward_summary.get("rewards_enabled", false)):
		_info_label.text = "Clear the current battle before advancing."
		_play_ui_cue("error")
		_refresh_menu_content()
		return false
	var carry := _capture_campaign_carry_state()
	if String(_story_progress.get("last_camp_battle", "")) != get_battle_id():
		_apply_default_camp_plan()
		carry = _capture_campaign_carry_state()
	_start_campaign_battle(next_path, carry)
	_info_label.text = "Campaign advanced to %s." % get_battle_id()
	_play_ui_cue("camp")
	_refresh_all()
	return true

func _get_settlement_next_battle_path() -> String:
	if _get_next_battle_definition_path() != "":
		return _get_next_battle_definition_path()
	if get_battle_id() == "chapter_01_finale":
		return _CHAPTER_01_TO_CHAPTER_02_PATH
	return ""

func _get_settlement_next_battle_title(path: String) -> String:
	var file_stem := path.get_file().trim_suffix(".json")
	if file_stem == "":
		return ""
	var chunks := file_stem.split("_")
	var title_chunks: Array[String] = []
	for chunk in chunks:
		var piece := String(chunk).to_lower()
		if piece == "":
			continue
		title_chunks.append(piece.substr(0, 1).to_upper() + piece.substr(1))
	return " ".join(title_chunks)

func _show_settlement_overlay() -> void:
	if _settlement_layer == null:
		return
	_set_settlement_overlay_visible(true)
	if _auto_battle_controller != null:
		_auto_battle_controller.set_enabled(false)
	var next_path := _get_settlement_next_battle_path()
	var can_continue := next_path != ""
	var title := "Victory Settlement" if bool(_settlement_reward_summary.get("rewards_enabled", false)) else "Defeat Settlement"
	_settlement_title_label.text = "%s - %s" % [title, get_battle_id()]
	_settlement_summary_label.text = _format_settlement_menu()
	if can_continue:
		_settlement_next_label.text = "Next chapter available: %s" % _get_settlement_next_battle_title(next_path)
	else:
		_settlement_next_label.text = "No next battle is linked for this encounter."
	_settlement_continue_btn.text = "Continue Chapter"
	_settlement_continue_btn.disabled = not can_continue
	if _settlement_continue_btn != null:
		SRPGTheme.apply_button(_settlement_continue_btn, can_continue, false, true)
	_settlement_main_menu_btn.grab_focus()
	_play_ui_cue("camp")
	_refresh_action_bar()

func _hide_settlement_and_transient_overlays() -> void:
	_set_menu_overlay_visible(false)
	_set_management_overlay_visible(false)
	_set_settlement_overlay_visible(false)
	_menu_open = false
	if _result_label != null:
		_result_label.visible = false
		_result_label.text = ""

func _on_settlement_continue_pressed() -> void:
	if _is_chapter_transitioning:
		return
	var next_path: String = _get_settlement_next_battle_path()
	if next_path == "":
		if _battle_definition.has("chapter_completion_key"):
			_settlement_next_label.text = "Chapter Complete! Returning to main menu..."
			_info_label.text = "Chapter complete. Save recorded."
			_play_ui_cue("victory")
			SaveManager.save_game(1)
			_is_chapter_transitioning = true
			call_deferred("_return_to_main_menu")
			return
		_info_label.text = "No next battle is linked."
		_play_ui_cue("error")
		_settlement_next_label.text = "No next chapter is linked for this encounter."
		return
	if _phase != VSPhase.BATTLE_END or not bool(_settlement_reward_summary.get("rewards_enabled", false)):
		_info_label.text = "Clear the current battle before advancing."
		_play_ui_cue("error")
		return
	_is_chapter_transitioning = true
	_hide_settlement_and_transient_overlays()
	if _result_label != null:
		_result_label.visible = false
		_result_label.text = ""
	var carry: Dictionary = _capture_campaign_carry_state()
	if String(_story_progress.get("last_camp_battle", "")) != get_battle_id():
		_apply_default_camp_plan()
		carry = _capture_campaign_carry_state()
	_start_campaign_battle(next_path, carry)
	_info_label.text = "Campaign advanced to %s." % get_battle_id()
	_play_ui_cue("camp")
	_refresh_all()
	call_deferred("_hide_settlement_and_transient_overlays")

func _get_next_battle_definition_path() -> String:
	var next_path: Variant = _battle_definition.get("next_battle_definition_path", "")
	if typeof(next_path) != TYPE_STRING:
		return ""
	var next_path_str: String = next_path
	return next_path_str.strip_edges()

func _apply_loaded_save_data(save_data: SaveData) -> void:
	if save_data == null or save_data.battle_state.is_empty():
		_load_default_battle()
		return

	_apply_default_preferences()
	_load_battle_definition(String(save_data.battle_state.get("battle_definition_path", DEFAULT_BATTLE_DEFINITION_PATH)))
	_story_progress = save_data.story_progress.duplicate(true)
	if _story_progress.is_empty():
		_story_progress = _battle_definition.get("progress_on_start", {}).duplicate(true)
	apply_ui_preferences(save_data.ui_preferences)
	apply_camera_preferences(save_data.camera_preferences)

	if not save_data.inventory_state.is_empty():
		_inventory.deserialize(save_data.inventory_state)
	elif not save_data.inventory_items.is_empty():
		_restore_inventory_from_items(save_data.inventory_items)
	else:
		_seed_inventory_from_definition()

	if not save_data.battle_history.is_empty():
		_battle_history_log.deserialize(save_data.battle_history)

	if save_data.battle_state.has("units") and not save_data.battle_state["units"].is_empty():
		_load_battle_from_state(save_data.battle_state)
		_restore_roster_from_save(save_data)
	else:
		set_map_size(int(_battle_definition.get("map_size", DEFAULT_MAP_SIZE)))
		_seed_units_from_definition()
		_combat.start_battle(get_battle_id(), _get_map_id(), int(_battle_definition.get("difficulty", 1)))

func _load_battle_from_state(state: Dictionary) -> void:
	var restored_map_size: int = state.get("map_size", DEFAULT_MAP_SIZE)
	set_map_size(restored_map_size)
	_camera_rotation = 0
	_grid_overlay_enabled = state.get("grid_overlay_enabled", _grid_overlay_enabled)
	_camera_preferences["rotation_index"] = _camera_rotation
	_camera_preferences["grid_overlay_enabled"] = _grid_overlay_enabled
	_camera_preferences["map_size"] = restored_map_size

	var units_data: Array = state.get("units", [])
	for entry in units_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_restore_unit(entry)

	var all_units: Array = _unit_cells.keys()
	_actions.initialize(all_units)
	_combat.deserialize(state.get("combat", {}), _build_unit_id_map())
	_actions.deserialize(state.get("action", {}))
	_speed_controller.deserialize(state.get("speed_state", {}))
	_auto_battle_controller.deserialize(state.get("auto_battle", {}))
	_phase = state.get("phase", VSPhase.SELECT_UNIT)
	_battle_end_emitted = state.get("battle_end_emitted", false)
	_player_damage_taken = int(state.get("player_damage_taken", 0))
	_player_deaths = int(state.get("player_deaths", 0))
	_settlement_reward_summary = state.get("settlement_reward_summary", {}).duplicate(true)
	_last_camp_report = String(state.get("last_camp_report", _last_camp_report))
	if state.has("map_terrain"):
		_map_terrain = _deserialize_position_map(state.get("map_terrain", {}))

	var selected_unit_id: String = state.get("selected_unit_id", "")
	_selected_unit = _find_unit_by_id(selected_unit_id)
	_reflow_map_visuals()
	_restore_result_ui()
	_sync_phase_prompt()

func _seed_inventory_from_definition() -> void:
	for entry in _battle_definition.get("inventory", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var resource_id := BattleDefinitionLoader.resolve_resource_id(String(entry.get("resource", "")))
		_inventory.add_resource(resource_id, int(entry.get("amount", 0)))

func _create_unit_from_definition(entry: Dictionary) -> Unit:
	var position: Dictionary = entry.get("position", {})
	var team := BattleDefinitionLoader.resolve_team(String(entry.get("team", "enemy")))
	var is_player := team == CombatSystem.Team.PLAYER
	var max_hp := int(entry.get("hp", 1))
	var stats: Dictionary = entry.get("stats", {})
	if not is_player:
		max_hp = BattleDifficultyProfile.scale_enemy_hp(max_hp, _difficulty_profile)
		stats = BattleDifficultyProfile.scale_enemy_stats(stats, _difficulty_profile)
	var unit := _create_unit(
		String(entry.get("id", "")),
		String(entry.get("name", "Unit")),
		is_player,
		max_hp,
		Vector2i(int(position.get("x", 0)), int(position.get("y", 0))),
		stats
	)
	unit.configure_starting_class(BattleDefinitionLoader.resolve_class_id(String(entry.get("class", "basic_warrior"))))
	_seed_equipment_from_definition(unit, entry.get("equipment", []))
	_register_tactical_profile_from_definition(unit, entry)
	_register_boss_from_definition(unit, entry)
	return unit

func _register_tactical_profile_from_definition(unit: Unit, entry: Dictionary) -> void:
	var tactics: Dictionary = entry.get("tactics", {})
	_unit_tactical_profiles[unit] = {
		"weapon_type": BattleDefinitionLoader.resolve_weapon_type(String(tactics.get("weapon", "sword"))),
		"element": BattleDefinitionLoader.resolve_element(String(tactics.get("element", "none"))),
		"ai_type": BattleDefinitionLoader.resolve_ai_type(String(tactics.get("ai", "balanced"))),
		"move": int(tactics.get("move", 3)),
		"attack_range": int(tactics.get("range", 2)),
	}

func _register_boss_from_definition(unit: Unit, entry: Dictionary) -> void:
	if not bool(entry.get("boss", false)):
		return
	var profile := _normalize_boss_profile(entry.get("boss_profile", {}), unit.display_name)
	_boss_profiles[unit] = profile
	_boss_states[unit] = {
		"phase": 1,
		"checkpoint_phase": 1,
		"checkpoint_hp": _combat._combat_units[unit]["max_hp"],
	}
	_story_progress["active_boss"] = String(unit.unit_id)
	_story_progress["boss_phase"] = 1

func _normalize_boss_profile(raw_profile, fallback_title: String) -> Dictionary:
	var raw: Dictionary = raw_profile if typeof(raw_profile) == TYPE_DICTIONARY else {}
	var thresholds: Array = []
	for value in raw.get("phase_thresholds", [0.5]):
		if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			thresholds.append(clampf(float(value), 0.01, 0.99))
	thresholds.sort()
	thresholds.reverse()
	if thresholds.is_empty():
		thresholds.append(0.5)
	return {
		"title": String(raw.get("title", fallback_title)),
		"phase_names": raw.get("phase_names", ["Opening", "Enraged"]),
		"phase_thresholds": thresholds,
		"phase_damage_multiplier": maxf(1.0, float(raw.get("phase_damage_multiplier", 1.3))),
		"checkpoint_retained_hp_ratio": clampf(float(raw.get("checkpoint_retained_hp_ratio", 0.15)), 0.0, 1.0),
		"hint": String(raw.get("hint", "")),
	}

func _seed_roster_from_definition(deployed_units: Array) -> void:
	var party: Array = []
	for unit in deployed_units:
		_roster.add_character(unit, CharacterRoster.Status.DEPLOYED)
		party.append(unit.unit_id)
	_roster.set_party(party)
	for spec in _battle_definition.get("reserves", []):
		if typeof(spec) != TYPE_DICTIONARY:
			continue
		var reserve_unit := Unit.new()
		reserve_unit.unit_id = StringName(spec["id"])
		reserve_unit.display_name = String(spec["name"])
		add_child(reserve_unit)
		_apply_unit_stats(reserve_unit, spec["stats"])
		reserve_unit.configure_starting_class(BattleDefinitionLoader.resolve_class_id(String(spec.get("class", "basic_warrior"))))
		_seed_equipment_from_definition(reserve_unit, spec.get("equipment", []))
		var status := _resolve_roster_status(String(spec.get("status", "available")))
		_roster.add_character(reserve_unit, status)
		if status == CharacterRoster.Status.DEPARTED:
			_roster.mark_story_departed(reserve_unit.unit_id, String(spec.get("reason", "")))

func _resolve_roster_status(value: String) -> int:
	match value:
		"deployed":
			return CharacterRoster.Status.DEPLOYED
		"departed":
			return CharacterRoster.Status.DEPARTED
		_:
			return CharacterRoster.Status.AVAILABLE

func _seed_equipment_from_definition(unit: Unit, item_defs: Array) -> void:
	for item_def in item_defs:
		if typeof(item_def) != TYPE_DICTIONARY:
			continue
		var item := EquipmentItem.new(_normalize_equipment_definition(item_def))
		unit.equipment_component.add_item(item)
		unit.equipment_component.equip_item(item.item_id)

func _normalize_equipment_definition(item_def: Dictionary) -> Dictionary:
	var affixes: Array = []
	for affix in item_def.get("affixes", []):
		if typeof(affix) != TYPE_DICTIONARY:
			continue
		affixes.append({
			"type": BattleDefinitionLoader.resolve_affix_type(String(affix.get("type", ""))),
			"value": int(affix.get("value", 0)),
			"attribute_type": BattleDefinitionLoader.resolve_attribute(String(affix.get("attribute", ""))),
			"stat_key": "",
			"category": EquipmentDefinitions.AffixCategory.ATTACK,
		})
	return {
		"item_id": String(item_def.get("item_id", "")),
		"name": String(item_def.get("name", "Equipment")),
		"slot": BattleDefinitionLoader.resolve_equipment_slot(String(item_def.get("slot", "weapon"))),
		"quality": BattleDefinitionLoader.resolve_equipment_quality(String(item_def.get("quality", "white"))),
		"affixes": affixes,
	}

func _build_default_mp_config(units: Array) -> Dictionary:
	var config: Dictionary = {}
	for unit in units:
		var skill_costs: Array[int] = []
		for skill_data in unit.skill_component.get_all_skills():
			var skill: SkillData = skill_data
			if skill.usage_type == SkillDefinitions.UsageType.ACTIVE and skill.mp_cost > 0:
				skill_costs.append(skill.mp_cost)
		if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
			config[unit] = {"max_mp": 100, "skill_costs": skill_costs}
		else:
			config[unit] = {"max_mp": 60, "skill_costs": skill_costs}
	return config

func _clear_unit_nodes() -> void:
	_kill_all_unit_tweens()
	for unit in _unit_cells.keys():
		if is_instance_valid(unit):
			unit.free()
	_grid_units.clear()
	_unit_cells.clear()
	_boss_profiles.clear()
	_boss_states.clear()
	_unit_tactical_profiles.clear()
	for child in get_children():
		if child is Unit and is_instance_valid(child):
			child.free()

	for dict_ref in [_unit_panels, _unit_labels, _hp_bars]:
		for value in dict_ref.values():
			if is_instance_valid(value):
				value.queue_free()
		dict_ref.clear()

func _kill_all_unit_tweens() -> void:
	for tween_map in [_unit_move_tweens, _unit_flash_tweens, _unit_death_tweens]:
		for tween in tween_map.values():
			if tween != null and tween.is_valid():
				tween.kill()
		tween_map.clear()

func _kill_unit_tween(tween_map: Dictionary, unit: Unit) -> void:
	var tween: Tween = tween_map.get(unit)
	if tween != null and tween.is_valid():
		tween.kill()
	tween_map.erase(unit)

func _create_unit(
	id: String,
	name: String,
	is_player: bool,
	hp: int,
	pos: Vector2i,
	stats: Dictionary = {}
) -> Unit:
	var unit := Unit.new()
	unit.unit_id = id
	unit.display_name = name
	add_child(unit)
	_apply_unit_stats(unit, stats)

	var team := CombatSystem.Team.PLAYER if is_player else CombatSystem.Team.ENEMY
	_register_unit(unit, team, hp, pos)
	return unit

func _restore_unit(entry: Dictionary) -> void:
	var unit := Unit.new()
	add_child(unit)
	var unit_payload: Dictionary = entry.get("unit", {})
	if not unit_payload.is_empty():
		unit.deserialize(unit_payload)
	else:
		unit.unit_id = StringName(entry.get("unit_id", "unit"))
		unit.display_name = entry.get("display_name", "Unit")

	var team: int = entry.get("team", CombatSystem.Team.PLAYER)
	var max_hp: int = entry.get("max_hp", 100)
	var pos_dict: Dictionary = entry.get("position", {})
	var pos := Vector2i(pos_dict.get("x", 0), pos_dict.get("y", 0))
	_register_unit(unit, team, max_hp, pos)
	_unit_tactical_profiles[unit] = entry.get("tactical_profile", {
		"weapon_type": TacticalFormulas.WeaponType.SWORD,
		"element": TacticalFormulas.Element.NONE,
		"ai_type": AI.AIType.BALANCED,
		"move": 3,
		"attack_range": 2,
	}).duplicate(true)
	if entry.has("boss_profile"):
		_boss_profiles[unit] = _normalize_boss_profile(entry.get("boss_profile", {}), unit.display_name)
		_boss_states[unit] = entry.get("boss_state", {
			"phase": 1,
			"checkpoint_phase": 1,
			"checkpoint_hp": max_hp,
		}).duplicate(true)

func _apply_unit_stats(unit: Unit, stats: Dictionary) -> void:
	if stats.is_empty():
		return
	if stats.has("str"):
		var str_comp: AttributeComponent = unit.attributes.get_component(AttributeNames.Attribute.STR)
		str_comp.load_data({
			"value": int(stats["str"]),
			"potential": 3,
			"barrier_stage": 1,
			"barriers_broken": {1: false, 2: false, 3: false},
			"thresholds_reached": {},
		})
	if stats.has("agi"):
		var agi_comp: AttributeComponent = unit.attributes.get_component(AttributeNames.Attribute.AGI)
		agi_comp.load_data({
			"value": int(stats["agi"]),
			"potential": 3,
			"barrier_stage": 1,
			"barriers_broken": {1: false, 2: false, 3: false},
			"thresholds_reached": {},
		})

func _register_unit(unit: Unit, team: int, max_hp: int, pos: Vector2i) -> void:
	_combat.register_unit(unit, team, max_hp)
	_grid_units[pos] = unit
	_unit_cells[unit] = pos
	_create_unit_visual_nodes(unit, max_hp)
	_update_unit_position(unit, pos)

func _create_unit_visual_nodes(unit: Unit, max_hp: int) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(maxf(20.0, _render_cell_size * 0.5), maxf(16.0, _render_cell_size * 0.35))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SRPGTheme.apply_panel(panel, Color(0.120, 0.105, 0.092, 0.96), SRPGTheme.GOLD)
	_grid_container.add_child(panel)
	_unit_panels[unit] = panel

	var hp_bar := ProgressBar.new()
	hp_bar.size = Vector2(maxf(28.0, _render_cell_size * 0.8), 10)
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SRPGTheme.apply_hp_bar(hp_bar, _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER)
	_grid_container.add_child(hp_bar)
	_hp_bars[unit] = hp_bar

	var lbl := Label.new()
	lbl.text = unit.display_name
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", SRPGTheme.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(lbl)
	_unit_labels[unit] = lbl

func _calculate_grid_area_size(size: int) -> Vector2:
	var render_size: float = _RENDER_CELL_SIZES.get(size, 40.0)
	var width: float = maxf(520.0, MARGIN * 2.0 + size * render_size + 24.0)
	var height: float = maxf(420.0, MARGIN * 2.0 + size * render_size + 24.0)
	return Vector2(width, height)

func _compute_render_cell_size(size: int) -> float:
	if not is_instance_valid(_grid_area):
		return _RENDER_CELL_SIZES.get(size, 40.0)
	var area_size: Vector2 = _grid_area.size
	if area_size.x <= 1.0 or area_size.y <= 1.0:
		return _RENDER_CELL_SIZES.get(size, 40.0)
	var usable_width: float = maxf(1.0, area_size.x - MARGIN * 2.0 - 8.0)
	var usable_height: float = maxf(1.0, area_size.y - MARGIN * 2.0 - 8.0)
	return clampf(floor(minf(usable_width, usable_height) / size), 18.0, 76.0)

func _generate_map_heights(size: int) -> Dictionary:
	var heights: Dictionary = {}
	var center: Vector2 = Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	for x in range(size):
		for y in range(size):
			var pos := Vector2i(x, y)
			var dist: float = absf(x - center.x) + absf(y - center.y)
			var height: int = 1
			if dist < size * 0.22:
				height = 2
			elif dist > size * 0.58 or ((x + y) % 6 == 0):
				height = 0
			heights[pos] = height
	return heights

func _generate_map_terrain(size: int) -> Dictionary:
	var terrain: Dictionary = {}
	for x in range(size):
		for y in range(size):
			var pos := Vector2i(x, y)
			var height: int = _map_heights.get(pos, TerrainTypes.HEIGHT_PLAIN)
			if height == TerrainTypes.HEIGHT_HIGH:
				terrain[pos] = TerrainTypes.Terrain.HIGHLAND
			elif height == TerrainTypes.HEIGHT_LOW:
				terrain[pos] = TerrainTypes.Terrain.SAND if (x + y) % 3 == 0 else TerrainTypes.Terrain.GRASS
			else:
				terrain[pos] = TerrainTypes.Terrain.NORMAL
	for entry in _battle_definition.get("terrain", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var pos := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		if pos.x < 0 or pos.x >= size or pos.y < 0 or pos.y >= size:
			continue
		var terrain_id := BattleDefinitionLoader.resolve_terrain(String(entry.get("type", "normal")))
		terrain[pos] = terrain_id
		_map_heights[pos] = TerrainTypes.get_height(terrain_id)
	return terrain

func _build_terrain_grid() -> Array:
	var grid: Array = []
	for y in range(_map_size):
		var row: Array = []
		for x in range(_map_size):
			row.append(int(_map_terrain.get(Vector2i(x, y), TerrainTypes.Terrain.NORMAL)))
		grid.append(row)
	return grid

## Returns the stable scene key used by SaveManager routing.
func get_scene_key() -> String:
	return _SCENE_KEY

## Returns the root-space click point for a grid cell's current projected center.
func get_cell_click_point(grid_pos: Vector2i) -> Vector2:
	var center: Vector2 = _cell_centers.get(grid_pos, Vector2.ZERO)
	return _grid_container.get_global_rect().position + center

## Set the map size to one of the supported presets and rebuild the map visuals.
func set_map_size(size: int) -> void:
	if not MAP_SIZE_OPTIONS.has(size):
		size = DEFAULT_MAP_SIZE
	_map_size = size
	_render_cell_size = _compute_render_cell_size(size)
	_map_heights = _generate_map_heights(size)
	_map_terrain = _generate_map_terrain(size)
	_camera_preferences["map_size"] = size

	if is_instance_valid(_grid_area):
		_grid_area.custom_minimum_size = _calculate_grid_area_size(size)
	if is_instance_valid(_grid_container):
		_update_grid_container_bounds()

	_rebuild_cells()
	_reflow_map_visuals()

## Get the currently active map size preset.
func get_map_size() -> int:
	return _map_size

## Rotate the camera by the given step count (modulo 4).
func rotate_camera(step: int = 1) -> void:
	set_camera_rotation(0)

## Set the camera rotation index directly (0..3).
func set_camera_rotation(index: int) -> void:
	_camera_rotation = 0
	_camera_preferences["rotation_index"] = _camera_rotation
	_reflow_map_visuals()

## Return the active camera heading in degrees.
func get_camera_rotation_degrees() -> int:
	return 0

## Enable or disable the projected grid overlay.
func set_grid_overlay_enabled(enabled: bool) -> void:
	_grid_overlay_enabled = enabled
	_camera_preferences["grid_overlay_enabled"] = enabled
	_reflow_map_visuals()

## Return true when the projected grid overlay is visible.
func is_grid_overlay_enabled() -> bool:
	return _grid_overlay_enabled

## Capture the current scene state for SaveManager persistence.
func capture_runtime_state() -> Dictionary:
	_ui_preferences["last_menu_tab"] = _active_menu_tab
	return {
		"party_units": _capture_party_units(),
		"inventory_items": _capture_inventory_items(),
		"settings": _ui_preferences.duplicate(true),
		"battle_state": _capture_battle_state(),
		"camera_preferences": capture_camera_preferences(),
		"ui_preferences": capture_ui_preferences(),
		"inventory_state": _inventory.serialize(),
		"battle_history": _battle_history_log.serialize(),
		"story_progress": _story_progress.duplicate(true),
	}

## Return the current camera-specific preferences.
func capture_camera_preferences() -> Dictionary:
	return {
		"rotation_index": _camera_rotation,
		"grid_overlay_enabled": _grid_overlay_enabled,
		"map_size": _map_size,
	}

## Apply a camera preference payload to the current scene.
func apply_camera_preferences(data: Dictionary) -> void:
	if data.is_empty():
		return
	_camera_rotation = 0
	_grid_overlay_enabled = data.get("grid_overlay_enabled", _grid_overlay_enabled)
	var target_size: int = data.get("map_size", _map_size)
	set_map_size(target_size)
	_camera_preferences = capture_camera_preferences()

## Return the current UI preference payload.
func capture_ui_preferences() -> Dictionary:
	var data: Dictionary = _ui_preferences.duplicate(true)
	data["last_menu_tab"] = _active_menu_tab
	data["menu_open"] = _menu_open
	data["management_open"] = _is_management_overlay_visible()
	data["management_tab"] = _active_management_tab
	return data

## Apply a UI preference payload to the current scene.
func apply_ui_preferences(data: Dictionary) -> void:
	if data.is_empty():
		return
	for key in data:
		_ui_preferences[key] = data[key]
	_active_menu_tab = String(_ui_preferences.get("last_menu_tab", _active_menu_tab))
	_menu_open = bool(data.get("menu_open", false))
	_set_menu_overlay_visible(_menu_open)
	_active_management_tab = String(data.get("management_tab", _active_management_tab))
	if _management_layer != null:
		_set_management_overlay_visible(bool(data.get("management_open", false)))
		_refresh_management_content()
	_refresh_menu_content()

## Apply a previously captured runtime-state payload to the current scene.
func apply_runtime_state(state: Dictionary) -> void:
	var wrapper := SaveData.new()
	wrapper.party_units = state.get("party_units", [])
	wrapper.inventory_items = state.get("inventory_items", [])
	wrapper.battle_state = state.get("battle_state", {})
	wrapper.camera_preferences = state.get("camera_preferences", {})
	wrapper.ui_preferences = state.get("ui_preferences", {})
	wrapper.inventory_state = state.get("inventory_state", {})
	wrapper.battle_history = state.get("battle_history", {})
	wrapper.story_progress = state.get("story_progress", {})
	_reset_runtime_systems()
	_apply_loaded_save_data(wrapper)

## Change the active menu tab by id.
func set_active_menu_tab(tab_name: String) -> void:
	_active_menu_tab = tab_name
	_ui_preferences["last_menu_tab"] = tab_name
	for key in _menu_buttons.keys():
		SRPGTheme.apply_button(_menu_buttons[key] as Button, key == tab_name, false, true)
	_refresh_menu_content()
	if _menu_buttons.has(tab_name):
		(_menu_buttons[tab_name] as Button).grab_focus()

func _capture_party_units() -> Array:
	if _roster == null:
		return []
	return _roster.get_data().get("characters", []).duplicate(true)

func _capture_inventory_items() -> Array:
	var items: Array = []
	if _inventory == null:
		return items
	var snapshot: Dictionary = _inventory.serialize()
	var resource_ids: Array = snapshot.keys()
	resource_ids.sort()
	for resource_id in resource_ids:
		items.append({
			"resource_type": int(resource_id),
			"amount": int(snapshot[resource_id]),
		})
	return items

func _serialize_position_map(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pos in source:
		out["%d,%d" % [pos.x, pos.y]] = source[pos]
	return out

func _deserialize_position_map(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source:
		var parts := String(key).split(",")
		if parts.size() != 2:
			continue
		out[Vector2i(int(parts[0]), int(parts[1]))] = source[key]
	return out

func _restore_inventory_from_items(items: Array) -> void:
	var snapshot: Dictionary = {}
	for entry in items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		snapshot[int(entry.get("resource_type", -1))] = int(entry.get("amount", 0))
	_inventory.deserialize(snapshot)

func _restore_roster_from_save(save_data: SaveData) -> void:
	if _roster == null:
		return
	if save_data.party_units.is_empty():
		_rebuild_roster_from_active_units()
		return
	_roster.load_data({
		"characters": save_data.party_units,
		"battle_active": _phase != VSPhase.BATTLE_END,
	}, _build_all_unit_id_map())

func _rebuild_roster_from_active_units() -> void:
	_roster.load_data({"characters": [], "party": [], "battle_active": _phase != VSPhase.BATTLE_END})
	var deployed: Array = []
	for unit in _unit_cells.keys():
		if _combat.get_unit_team(unit) != CombatSystem.Team.PLAYER:
			continue
		deployed.append(String(unit.unit_id))
		_roster.add_character(unit, CharacterRoster.Status.DEPLOYED)
	_roster.set_party(deployed)

func _capture_battle_state() -> Dictionary:
	var units: Array = []
	for unit in _unit_cells.keys():
		var unit_state := {
			"unit": unit.serialize(),
			"team": _combat.get_unit_team(unit),
			"max_hp": _combat._combat_units[unit]["max_hp"],
			"position": {"x": _unit_cells[unit].x, "y": _unit_cells[unit].y},
		}
		if _boss_profiles.has(unit):
			unit_state["boss_profile"] = _boss_profiles[unit].duplicate(true)
			unit_state["boss_state"] = _boss_states.get(unit, {}).duplicate(true)
		if _unit_tactical_profiles.has(unit):
			unit_state["tactical_profile"] = _unit_tactical_profiles[unit].duplicate(true)
		units.append(unit_state)

	return {
		"map_size": _map_size,
		"camera_rotation": 0,
		"grid_overlay_enabled": _grid_overlay_enabled,
		"phase": _phase,
		"selected_unit_id": String(_selected_unit.unit_id) if _selected_unit != null else "",
		"units": units,
		"combat": _combat.serialize(),
		"action": _actions.serialize(),
		"speed_state": _speed_controller.serialize(),
		"auto_battle": _auto_battle_controller.serialize(),
		"battle_end_emitted": _battle_end_emitted,
		"battle_definition_path": _get_battle_definition_path(),
		"difficulty_profile": _difficulty_profile.duplicate(true),
		"battle_id": get_battle_id(),
		"map_id": _get_map_id(),
		"map_terrain": _serialize_position_map(_map_terrain),
		"last_camp_report": _last_camp_report,
		"player_damage_taken": _player_damage_taken,
		"player_deaths": _player_deaths,
		"settlement_reward_summary": _settlement_reward_summary.duplicate(true),
	}

func _rebuild_cells() -> void:
	for node in _cells.values():
		if is_instance_valid(node):
			node.queue_free()
	for label in _cell_height_labels.values():
		if is_instance_valid(label):
			label.queue_free()
	_cells.clear()
	_cell_centers.clear()
	_cell_height_labels.clear()

	for x in range(_map_size):
		for y in range(_map_size):
			var cell := ColorRect.new()
			cell.size = Vector2(_render_cell_size - 3.0, _render_cell_size - 3.0)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pos := Vector2i(x, y)
			_cells[pos] = cell
			_grid_container.add_child(cell)
			var label := Label.new()
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", Color(SRPGTheme.PAPER.r, SRPGTheme.PAPER.g, SRPGTheme.PAPER.b, 0.72))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_cell_height_labels[pos] = label
			_grid_container.add_child(label)

func _on_grid_area_resized() -> void:
	if _map_size <= 0 or _cells.is_empty():
		return
	var next_cell_size: float = _compute_render_cell_size(_map_size)
	if is_equal_approx(next_cell_size, _render_cell_size):
		_update_grid_container_bounds()
		return
	_render_cell_size = next_cell_size
	_apply_render_cell_size_to_nodes()
	_reflow_map_visuals()

func _apply_render_cell_size_to_nodes() -> void:
	for cell in _cells.values():
		if is_instance_valid(cell):
			(cell as ColorRect).size = Vector2(_render_cell_size - 3.0, _render_cell_size - 3.0)
	for unit in _unit_panels.keys():
		var panel: Panel = _unit_panels.get(unit)
		if panel != null:
			panel.custom_minimum_size = Vector2(maxf(20.0, _render_cell_size * 0.5), maxf(16.0, _render_cell_size * 0.35))
			panel.size = panel.custom_minimum_size
		var hp_bar: ProgressBar = _hp_bars.get(unit)
		if hp_bar != null:
			hp_bar.size = Vector2(maxf(28.0, _render_cell_size * 0.8), 10)

func _update_grid_container_bounds() -> void:
	if not is_instance_valid(_grid_container):
		return
	var content_size := Vector2(
		MARGIN * 2.0 + _map_size * _render_cell_size,
		MARGIN * 2.0 + _map_size * _render_cell_size
	)
	_grid_container.size = content_size
	if not is_instance_valid(_grid_area):
		_grid_container.position = Vector2.ZERO
		return
	var area_size: Vector2 = _grid_area.size
	if area_size.x <= 1.0 or area_size.y <= 1.0:
		area_size = _grid_area.custom_minimum_size
	_grid_container.position = Vector2(
		maxf(0.0, (area_size.x - content_size.x) * 0.5),
		maxf(0.0, (area_size.y - content_size.y) * 0.5)
	)

func _reflow_map_visuals() -> void:
	_update_grid_container_bounds()
	for pos in _cells.keys():
		_update_cell_transform(pos)
		_update_cell_color(pos)
	for unit in _unit_cells.keys():
		_update_unit_position(unit, _unit_cells[unit])
	_refresh_camera_status()
	_refresh_turn_display()
	_refresh_status_panel()

func _update_cell_transform(pos: Vector2i) -> void:
	var cell: ColorRect = _cells[pos]
	cell.position = Vector2(
		MARGIN + pos.x * _render_cell_size + 1.0,
		MARGIN + pos.y * _render_cell_size + 1.0
	)
	var center: Vector2 = cell.position + cell.size * 0.5
	_cell_centers[pos] = center
	var label: Label = _cell_height_labels[pos]
	label.position = cell.position + Vector2(4.0, 2.0)
	label.visible = _grid_overlay_enabled
	if _grid_overlay_enabled:
		label.text = "%s H%d" % [_terrain_short_name(int(_map_terrain.get(pos, TerrainTypes.Terrain.NORMAL))), _map_heights.get(pos, 1)]
	else:
		label.text = ""

func _update_cell_color(pos: Vector2i, override_color: Color = Color.TRANSPARENT) -> void:
	var cell: ColorRect = _cells[pos]
	if override_color != Color.TRANSPARENT:
		cell.color = override_color
		if _cell_height_labels.has(pos):
			var override_label: Label = _cell_height_labels[pos] as Label
			override_label.visible = _grid_overlay_enabled
			var override_alpha: float = 0.95 if _grid_overlay_enabled else 0.0
			override_label.modulate = Color(1, 1, 1, override_alpha)
		return

	var terrain: int = int(_map_terrain.get(pos, TerrainTypes.Terrain.NORMAL))
	var parity: bool = (pos.x + pos.y) % 2 == 0
	var base_color: Color
	match terrain:
		TerrainTypes.Terrain.GRASS:
			base_color = Color(0.145, 0.215, 0.170) if parity else Color(0.170, 0.245, 0.190)
		TerrainTypes.Terrain.SAND:
			base_color = Color(0.420, 0.350, 0.210) if parity else Color(0.470, 0.390, 0.240)
		TerrainTypes.Terrain.WATER_PUDDLE:
			base_color = Color(0.120, 0.205, 0.255) if parity else Color(0.150, 0.245, 0.300)
		TerrainTypes.Terrain.MUD:
			base_color = Color(0.230, 0.170, 0.120) if parity else Color(0.280, 0.205, 0.145)
		TerrainTypes.Terrain.HIGHLAND:
			base_color = Color(0.350, 0.255, 0.185) if parity else Color(0.395, 0.290, 0.205)
		TerrainTypes.Terrain.OBSTACLE:
			base_color = Color(0.105, 0.105, 0.102) if parity else Color(0.135, 0.128, 0.120)
		_:
			base_color = Color(0.245, 0.235, 0.185) if parity else Color(0.285, 0.268, 0.205)
	base_color.a = 0.94 if _grid_overlay_enabled else 0.62
	cell.color = base_color
	if _cell_height_labels.has(pos):
		var terrain_label: Label = _cell_height_labels[pos] as Label
		terrain_label.visible = _grid_overlay_enabled
		var label_alpha: float = 0.78 if _grid_overlay_enabled else 0.0
		terrain_label.modulate = Color(0.92, 0.84, 0.66, label_alpha)

func _terrain_short_name(terrain: int) -> String:
	match terrain:
		TerrainTypes.Terrain.GRASS:
			return "Gr"
		TerrainTypes.Terrain.WATER_PUDDLE:
			return "Wa"
		TerrainTypes.Terrain.SAND:
			return "Sa"
		TerrainTypes.Terrain.MUD:
			return "Mu"
		TerrainTypes.Terrain.HIGHLAND:
			return "Hi"
		TerrainTypes.Terrain.OBSTACLE:
			return "Ob"
		_:
			return "No"

func _project_cell_center(pos: Vector2i) -> Vector2:
	return Vector2(
		MARGIN + pos.x * _render_cell_size + (_render_cell_size * 0.5),
		MARGIN + pos.y * _render_cell_size + (_render_cell_size * 0.5)
	)

func _should_play_battle_feedback() -> bool:
	if not is_instance_valid(_grid_container):
		return false
	if _speed_controller != null and _speed_controller.should_skip_animations():
		return false
	return true

func _get_unit_visual_nodes(unit: Unit) -> Array:
	var nodes := []
	for node in [_unit_panels.get(unit), _unit_labels.get(unit), _hp_bars.get(unit)]:
		if node != null and is_instance_valid(node):
			nodes.append(node)
	return nodes

func _get_unit_visual_positions(unit: Unit, pos: Vector2i) -> Dictionary:
	var center: Vector2 = _project_cell_center(pos)
	var positions := {}
	var panel: Panel = _unit_panels.get(unit)
	if panel != null:
		positions["panel"] = center + Vector2(-panel.custom_minimum_size.x * 0.5, -panel.custom_minimum_size.y * 0.5)
	var label: Label = _unit_labels.get(unit)
	if label != null:
		positions["label"] = center + Vector2(-24.0, -_render_cell_size * 0.62)
	var hp_bar: ProgressBar = _hp_bars.get(unit)
	if hp_bar != null:
		positions["hp_bar"] = center + Vector2(-hp_bar.size.x * 0.5, _render_cell_size * 0.18)
	return positions

func _set_unit_visual_positions(unit: Unit, positions: Dictionary) -> void:
	var panel: Panel = _unit_panels.get(unit)
	if panel != null and positions.has("panel"):
		panel.position = positions["panel"]
	var label: Label = _unit_labels.get(unit)
	if label != null and positions.has("label"):
		label.position = positions["label"]
	var hp_bar: ProgressBar = _hp_bars.get(unit)
	if hp_bar != null and positions.has("hp_bar"):
		hp_bar.position = positions["hp_bar"]

func _tween_unit_visuals_to(unit: Unit, positions: Dictionary) -> void:
	_kill_unit_tween(_unit_move_tweens, unit)
	var tween := create_tween()
	tween.set_parallel(true)
	var panel: Panel = _unit_panels.get(unit)
	if panel != null and positions.has("panel"):
		tween.tween_property(panel, "position", positions["panel"], _MOVE_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var label: Label = _unit_labels.get(unit)
	if label != null and positions.has("label"):
		tween.tween_property(label, "position", positions["label"], _MOVE_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var hp_bar: ProgressBar = _hp_bars.get(unit)
	if hp_bar != null and positions.has("hp_bar"):
		tween.tween_property(hp_bar, "position", positions["hp_bar"], _MOVE_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_unit_move_tweens[unit] = tween
	tween.finished.connect(func() -> void:
		_unit_move_tweens.erase(unit)
	)

func _play_attack_feedback(actor: Unit, target_unit: Unit) -> void:
	if actor == null or target_unit == null:
		return
	if not _unit_cells.has(actor) or not _unit_cells.has(target_unit):
		return
	if not _should_play_battle_feedback():
		return

	_kill_unit_tween(_unit_move_tweens, actor)
	_set_unit_visual_positions(actor, _get_unit_visual_positions(actor, _unit_cells[actor]))

	var origin: Vector2 = _project_cell_center(_unit_cells[actor])
	var target: Vector2 = _project_cell_center(_unit_cells[target_unit])
	var direction: Vector2 = target - origin
	if direction.length() <= 0.01:
		return
	var offset: Vector2 = direction.normalized() * minf(12.0, _render_cell_size * 0.24)
	for node in _get_unit_visual_nodes(actor):
		var start_position: Vector2 = node.position
		var tween := create_tween()
		tween.tween_property(node, "position", start_position + offset, _ATTACK_LUNGE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position", start_position, _ATTACK_RECOVER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _play_hit_feedback(unit: Node) -> void:
	if not (unit is Unit):
		return
	var target_unit := unit as Unit
	if not _should_play_battle_feedback():
		return
	_kill_unit_tween(_unit_flash_tweens, target_unit)
	var nodes := _get_unit_visual_nodes(target_unit)
	if nodes.is_empty():
		return
	for node in nodes:
		node.modulate = Color(1.0, 0.36, 0.30, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	for node in nodes:
		tween.tween_property(node, "modulate", Color.WHITE, _HIT_FLASH_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_unit_flash_tweens[target_unit] = tween
	tween.finished.connect(func() -> void:
		_unit_flash_tweens.erase(target_unit)
	)

func _play_death_feedback(unit: Node) -> void:
	if not (unit is Unit):
		return
	var target_unit := unit as Unit
	_kill_unit_tween(_unit_move_tweens, target_unit)
	_kill_unit_tween(_unit_flash_tweens, target_unit)
	_kill_unit_tween(_unit_death_tweens, target_unit)
	var nodes := _get_unit_visual_nodes(target_unit)
	if nodes.is_empty():
		return
	for node in nodes:
		node.modulate = Color(1.0, 0.28, 0.22, 1.0)
	if not _should_play_battle_feedback():
		for node in nodes:
			node.modulate = Color(0.55, 0.52, 0.48, 0.24)
		return
	var tween := create_tween()
	tween.set_parallel(true)
	for node in nodes:
		tween.tween_property(node, "modulate", Color(0.55, 0.52, 0.48, 0.24), _DEATH_FADE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_unit_death_tweens[target_unit] = tween
	tween.finished.connect(func() -> void:
		_unit_death_tweens.erase(target_unit)
	)

func _find_nearest_grid_pos(click_pos: Vector2) -> Vector2i:
	var local_click: Vector2 = click_pos - _grid_container.get_global_rect().position
	local_click -= Vector2(MARGIN, MARGIN)
	if local_click.x < 0 or local_click.y < 0:
		return Vector2i(-1, -1)
	var grid_x: int = int(floor(local_click.x / _render_cell_size))
	var grid_y: int = int(floor(local_click.y / _render_cell_size))
	if grid_x < 0 or grid_y < 0 or grid_x >= _map_size or grid_y >= _map_size:
		return Vector2i(-1, -1)
	return Vector2i(grid_x, grid_y)

func _refresh_all() -> void:
	_reflow_map_visuals()
	_refresh_all_units()
	_refresh_resource_hud()
	_refresh_objective_label()
	_refresh_boss_label()
	_refresh_menu_content()
	_refresh_management_content()
	_refresh_action_bar()

func _refresh_all_units() -> void:
	for unit in _unit_panels.keys():
		_refresh_unit_visual(unit)
	_refresh_status_panel()

func _refresh_unit_visual(unit: Unit) -> void:
	var panel: Panel = _unit_panels.get(unit)
	if panel == null:
		return
	var is_player := _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER
	var is_alive := _combat.is_unit_alive(unit)
	var body_color := Color(0.150, 0.245, 0.205, 0.98) if is_player else Color(0.330, 0.075, 0.065, 0.98)
	var border_color := SRPGTheme.JADE if is_player else SRPGTheme.VERMILION
	if not is_alive:
		body_color = Color(0.105, 0.100, 0.096, 0.60)
		border_color = Color(0.220, 0.205, 0.180, 0.70)
	if _selected_unit == unit:
		body_color = Color(0.540, 0.405, 0.145, 0.98)
		border_color = SRPGTheme.GOLD
	panel.self_modulate = Color.WHITE
	panel.add_theme_stylebox_override("panel", SRPGTheme.panel(body_color, border_color, 4, 1))
	if is_player:
		(_unit_labels[unit] as Label).add_theme_color_override("font_color", SRPGTheme.WHITE if is_alive else SRPGTheme.PAPER_MUTED)
	else:
		(_unit_labels[unit] as Label).add_theme_color_override("font_color", Color(1.0, 0.86, 0.78, 1.0) if is_alive else SRPGTheme.PAPER_MUTED)

func _refresh_turn_display() -> void:
	for child in _turn_list.get_children():
		child.queue_free()
	var order := _combat.get_turn_order()
	var current := _combat.get_current_actor()
	for unit in order:
		if not _combat.is_unit_alive(unit):
			continue
		# UI-P0-03: 每个立牌用 VBoxContainer 包含名称行 + 迷你 HP 条
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 1)
		var lbl := Label.new()
		var prefix := ">" if unit == current else " "
		var team_tag := "[P]" if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER else "[E]"
		lbl.text = "%s %s %s HP:%d" % [prefix, team_tag, unit.display_name, _combat.get_unit_hp(unit)]
		SRPGTheme.apply_label(lbl, SRPGTheme.GOLD if unit == current else SRPGTheme.PAPER, 14)
		card.add_child(lbl)
		# 迷你 HP 条：4px 高，颜色按 HP% 三段着色
		var hp_bar := ProgressBar.new()
		hp_bar.custom_minimum_size = Vector2(0, 4)
		hp_bar.show_percentage = false
		hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unit_data: Dictionary = _combat._combat_units[unit]
		var max_hp: int = int(unit_data.get("max_hp", 1))
		var cur_hp: int = _combat.get_unit_hp(unit)
		hp_bar.max_value = max(max_hp, 1)
		hp_bar.value = cur_hp
		var hp_pct: float = float(cur_hp) / float(max(max_hp, 1))
		var bar_color: Color
		if hp_pct > 0.5:
			bar_color = SRPGTheme.JADE
		elif hp_pct > 0.25:
			bar_color = Color(0.85, 0.75, 0.15, 1.0)
		else:
			bar_color = SRPGTheme.VERMILION
		var bar_bg := SRPGTheme.button_style(Color(0.08, 0.07, 0.07, 0.90), Color(0.22, 0.19, 0.15, 0.70), 1)
		var bar_fill := SRPGTheme.button_style(bar_color, Color(bar_color.r, bar_color.g, bar_color.b, 0.90), 1)
		hp_bar.add_theme_stylebox_override("background", bar_bg)
		hp_bar.add_theme_stylebox_override("fill", bar_fill)
		card.add_child(hp_bar)
		_turn_list.add_child(card)

func _clear_highlights() -> void:
	for pos in _cells.keys():
		_update_cell_color(pos)

func _highlight_cells(positions: Array, color: Color) -> void:
	for pos in positions:
		if _cells.has(pos):
			_update_cell_color(pos, color)

func _get_move_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result: Array = []
	var movement := MovementSystem.new()
	var budget := int(_get_tactical_profile(unit).get("move", 3))
	for target in movement.get_reachable_cells(_build_terrain_grid(), pos, budget):
		if _grid_units.has(target) and _grid_units[target] != unit:
			continue
		result.append(target)
	return result

func _get_attack_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result: Array = []
	var base_range := int(_get_tactical_profile(unit).get("attack_range", 2))
	for dx in range(-base_range - 2, base_range + 3):
		for dy in range(-base_range - 2, base_range + 3):
			if dx == 0 and dy == 0:
				continue
			var target := pos + Vector2i(dx, dy)
			if target.x < 0 or target.x >= _map_size or target.y < 0 or target.y >= _map_size:
				continue
			var effective_range := TacticalFormulas.get_effective_range(
				base_range,
				int(_map_heights.get(pos, TerrainTypes.HEIGHT_PLAIN)),
				int(_map_heights.get(target, TerrainTypes.HEIGHT_PLAIN))
			)
			if abs(dx) + abs(dy) > maxi(1, effective_range):
				continue
			if _grid_units.has(target):
				var target_unit: Unit = _grid_units[target]
				if _combat.get_unit_team(target_unit) != _combat.get_unit_team(unit):
					result.append(target)
	return result

func _update_unit_position(unit: Unit, pos: Vector2i, animate: bool = false) -> void:
	var positions := _get_unit_visual_positions(unit, pos)
	if positions.is_empty():
		return
	if animate and _should_play_battle_feedback():
		_tween_unit_visuals_to(unit, positions)
		return
	_kill_unit_tween(_unit_move_tweens, unit)
	_set_unit_visual_positions(unit, positions)

func _refresh_status_panel() -> void:
	var focus_unit: Unit = _selected_unit if _selected_unit != null else _combat.get_current_actor()
	if focus_unit == null:
		_status_name_label.text = "Unit: —"
		_status_hp_label.text = "HP: —"
		_status_mp_label.text = "MP: —"
		_status_misc_label.text = "Phase: %s" % VSPhase.keys()[_phase]
		return

	_status_name_label.text = "Unit: %s" % focus_unit.display_name
	_status_hp_label.text = "HP: %d" % _combat.get_unit_hp(focus_unit)
	_status_mp_label.text = "MP: %d / %d" % [_actions.get_current_mp(focus_unit), _actions.get_max_mp(focus_unit)]
	var team_name := "Player" if _combat.get_unit_team(focus_unit) == CombatSystem.Team.PLAYER else "Enemy"
	_status_misc_label.text = "Team: %s | Phase: %s | View: Top-Down" % [team_name, VSPhase.keys()[_phase]]

func _refresh_resource_hud() -> void:
	if _inventory == null:
		return
	_resource_labels["gold"].text = "Gold: %d" % _inventory.get_amount(ResourceTypes.ResourceId.GOLD)
	_resource_labels["materials"].text = "Materials: %d" % _inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	_resource_labels["fruit"].text = "Fruit: %d" % _inventory.get_amount(ResourceTypes.ResourceId.FRUIT_STR)
	_resource_labels["protect"].text = "Protect: %d" % _inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL)

func _refresh_objective_label() -> void:
	if _objective_label == null:
		return
	var completion_key := String(_battle_definition.get("completion_key", "chapter_01_complete"))
	var state := "Complete" if bool(_story_progress.get(completion_key, false)) else "Active"
	_objective_label.text = "%s\nObjective: %s\nDifficulty: %s\nProgress: %s" % [
		_get_chapter_title(),
		get_objective_text(),
		_get_difficulty_summary(),
		state,
	]

func _refresh_camera_status() -> void:
	_camera_state_label.text = "%s | %s | View Top-Down | Grid %s | Map %d×%d | Speed x%d | Auto %s" % [
		_get_chapter_title(),
		String(_difficulty_profile.get("label", "Fixed Curve")),
		"ON" if _grid_overlay_enabled else "OFF",
		_map_size,
		_map_size,
		int(_speed_controller.get_animation_multiplier()),
		"ON" if _auto_battle_controller.is_enabled() else "OFF",
	]
	_refresh_auto_button()

func _refresh_auto_button() -> void:
	if _auto_button == null:
		return
	var enabled := _auto_battle_controller.is_enabled()
	_auto_button.text = "Auto ON (B)" if enabled else "Auto OFF (B)"
	SRPGTheme.apply_button(_auto_button, enabled, false, true)
	# UI-P0-02: 更新 Auto 状态徽章文字与颜色
	if _auto_badge_label != null:
		if enabled:
			_auto_badge_label.text = "[Auto]"
			_auto_badge_label.add_theme_color_override("font_color", SRPGTheme.VERMILION)
		else:
			_auto_badge_label.text = "[手动]"
			_auto_badge_label.add_theme_color_override("font_color", SRPGTheme.JADE)
	# UI-P0-02: 更新速度档位标签（1x/2x/3x）
	if _speed_badge_label != null:
		var tier_label: String = "%dx" % int(_speed_controller.get_animation_multiplier())
		_speed_badge_label.text = tier_label

func _refresh_action_bar() -> void:
	if _turn_sequence_running or _phase in [VSPhase.ANIMATING, VSPhase.ENEMY_TURN, VSPhase.BATTLE_END]:
		for button in _action_buttons.values():
			(button as Button).disabled = true
		return
	var move_enabled: bool = _phase == VSPhase.SELECT_UNIT or _phase == VSPhase.SELECT_MOVE
	var acting_unit: Unit = _selected_unit if _selected_unit != null else _combat.get_current_actor()
	(_action_buttons["move"] as Button).disabled = not move_enabled
	(_action_buttons["attack"] as Button).disabled = _selected_unit == null and _phase != VSPhase.SELECT_TARGET
	(_action_buttons["skill"] as Button).disabled = not _can_use_skill_action(acting_unit)
	(_action_buttons["standby"] as Button).disabled = _phase not in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]
	(_action_buttons["end_turn"] as Button).disabled = _phase not in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]
	if not _menu_open and _phase in [VSPhase.SELECT_UNIT, VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		(_action_buttons["move"] as Button).grab_focus()

func _refresh_menu_content() -> void:
	if _menu_content_label == null:
		return
	var text := ""
	match _active_menu_tab:
		"character":
			var actor: Unit = _selected_unit if _selected_unit != null else _combat.get_current_actor()
			if actor == null:
				text = "No active character."
			else:
				text = "Character\nName: %s\nHP: %d\nMP: %d/%d\nSTR: %d\nAGI: %d\nClass: %s\nSkills: %s\nParty: %s\nReserve: %d | Departed: %d\nEquipment: %s" % [
					actor.display_name,
					_combat.get_unit_hp(actor),
					_actions.get_current_mp(actor),
					_actions.get_max_mp(actor),
					actor.get_effective_attribute(AttributeNames.Attribute.STR),
					actor.get_effective_attribute(AttributeNames.Attribute.AGI),
					ClassNames.ClassID.keys()[actor.class_component.get_class_id()],
					_format_skill_summary(actor),
					", ".join(_stringify_name_array(_roster.get_party())),
					_roster.get_reserve_ids().size(),
					_roster.get_departed_ids().size(),
					_format_equipment_summary(actor),
				]
		"campaign":
			text = "Campaign\n%s" % _format_campaign_menu()
		"camp":
			text = "Camp\n%s" % _format_camp_menu()
		"equipment":
			text = "Equipment\n%s" % _format_equipment_menu()
		"roster":
			text = "Roster\n%s" % _format_roster_menu()
		"tactics":
			text = "Tactics\n%s" % _format_tactics_menu()
		"boss":
			text = "Boss\n%s" % _format_boss_menu()
		"settlement":
			text = "Settlement\n%s" % _format_settlement_menu()
		"inventory":
			text = "Inventory\nGold: %d\nMaterials: %d\nSTR Fruit: %d\nProtect Symbols: %d\nSerialized entries: %d" % [
				_inventory.get_amount(ResourceTypes.ResourceId.GOLD),
				_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL),
				_inventory.get_amount(ResourceTypes.ResourceId.FRUIT_STR),
				_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL),
				_capture_inventory_items().size(),
			]
		"save":
			text = "Save / Load\nChapter: %s\nObjective: %s\nDifficulty: %s\nStory Progress: %s\nCurrent Slot: %d\nPress F5 to save slot 1.\nPress F9 to load slot 1.\nContinue is now wired through SaveManager." % [
				_get_chapter_title(),
				get_objective_text(),
				_get_difficulty_summary(),
				JSON.stringify(_story_progress),
				SaveManager.get_current_slot(),
			]
		"settings":
			text = "Settings\nMaster Volume: %d\nSFX Volume: %d\nBGM Volume: %d\nScreen Mode: %s\nLast Menu Tab: %s" % [
				_ui_preferences.get("master_volume", 70),
				_ui_preferences.get("sfx_volume", 70),
				_ui_preferences.get("bgm_volume", 70),
				_ui_preferences.get("screen_mode", "windowed"),
				_ui_preferences.get("last_menu_tab", "character"),
			]
		_:
			text = "Unknown menu tab."
	_menu_content_label.text = text

func _refresh_management_content() -> void:
	if _management_content_label == null:
		return
	var text := ""
	match _active_management_tab:
		"rewards":
			text = _format_management_rewards()
		"camp":
			text = _format_management_camp()
		"party":
			text = _format_management_party()
		"equipment":
			text = _format_management_equipment()
		_:
			text = _format_management_rewards()
	_management_content_label.text = text

func _format_management_rewards() -> String:
	var next_text := _get_next_battle_definition_path()
	if next_text == "":
		next_text = "Chapter 1 route secured; no further battle configured in this slice."
	return "Rewards / 战果\n%s\n\nCurrent Battle: %s\nBriefing: %s\nNext: %s" % [
		_format_settlement_menu(),
		get_battle_id(),
		get_briefing_text(),
		next_text,
	]

func _format_management_camp() -> String:
	return "Recommended Camp / 推荐回营\nPlan: learn Defend, drill skills, add class unlock EXP, use STR fruit, enhance equipped gear.\n\nResources: Gold %d | Materials %d | STR Fruit %d | Protect %d\n\nLast Report:\n%s" % [
		_inventory.get_amount(ResourceTypes.ResourceId.GOLD),
		_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL),
		_inventory.get_amount(ResourceTypes.ResourceId.FRUIT_STR),
		_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL),
		_last_camp_report,
	]

func _format_management_party() -> String:
	var lines: Array[String] = []
	for unit_id_variant in _roster.get_party():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			continue
		lines.append("DEPLOYED %s | %s | STR %d | AGI %d | %s" % [
			unit.display_name,
			ClassNames.ClassID.keys()[unit.class_component.get_class_id()],
			unit.get_effective_attribute(AttributeNames.Attribute.STR),
			unit.get_effective_attribute(AttributeNames.Attribute.AGI),
			_format_skill_summary(unit),
		])
	for unit_id_variant in _roster.get_reserve_ids():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			continue
		lines.append("RESERVE %s | %s | %s" % [
			unit.display_name,
			ClassNames.ClassID.keys()[unit.class_component.get_class_id()],
			_format_equipment_summary(unit),
		])
	for unit_id_variant in _roster.get_departed_ids():
		lines.append("DEPARTED %s" % String(unit_id_variant))
	if lines.is_empty():
		lines.append("No roster data available.")
	return "Party Management / 队伍编成\nRecommended roster is locked during active combat; campaign definitions can deploy reserves between battles.\n\n%s" % "\n".join(lines)

func _format_management_equipment() -> String:
	var lines: Array[String] = []
	for unit_id_variant in _roster.get_party():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			continue
		lines.append("%s\n  Equipped: %s\n  Bonus STR: +%d | Bonus AGI: +%d" % [
			unit.display_name,
			_format_equipment_summary(unit),
			unit.get_equipment_bonus(AttributeNames.Attribute.STR),
			unit.get_equipment_bonus(AttributeNames.Attribute.AGI),
		])
	if lines.is_empty():
		lines.append("No equipped party items.")
	return "Equipment Management / 装备管理\nRecommended enhancement uses the first equipped item when resources allow.\n\n%s" % "\n".join(lines)

func _format_equipment_summary(unit: Unit) -> String:
	var parts: Array[String] = []
	for slot in unit.equipment_component.get_loadout():
		var item: EquipmentItem = unit.equipment_component.get_equipped_item(slot)
		if item == null:
			continue
		parts.append(item.name if item.name != "" else String(item.item_id))
	if parts.is_empty():
		return "None"
	return ", ".join(parts)

func _format_skill_summary(unit: Unit) -> String:
	var parts: Array[String] = []
	for skill_data in unit.skill_component.get_all_skills():
		var skill: SkillData = skill_data
		parts.append("%s MP:%d CD:%d" % [skill.name, skill.mp_cost, skill.cooldown_remaining])
	if parts.is_empty():
		return "None"
	return ", ".join(parts)

func _get_tactical_profile(unit: Unit) -> Dictionary:
	return _unit_tactical_profiles.get(unit, {
		"weapon_type": TacticalFormulas.WeaponType.SWORD,
		"element": TacticalFormulas.Element.NONE,
		"ai_type": AI.AIType.BALANCED,
		"move": 3,
		"attack_range": 2,
	})

func _format_tactical_profile(unit: Unit) -> String:
	var profile := _get_tactical_profile(unit)
	var pos: Vector2i = _unit_cells.get(unit, Vector2i(-1, -1))
	var terrain := int(_map_terrain.get(pos, TerrainTypes.Terrain.NORMAL))
	return "%s: %s/%s | Move %d | Range %d | Tile %s H%d" % [
		unit.display_name,
		TacticalFormulas.WeaponType.keys()[int(profile.get("weapon_type", 0))],
		TacticalFormulas.Element.keys()[int(profile.get("element", 0))],
		int(profile.get("move", 3)),
		int(profile.get("attack_range", 2)),
		TerrainTypes.Terrain.keys()[terrain],
		int(_map_heights.get(pos, TerrainTypes.HEIGHT_PLAIN)),
	]

func _format_campaign_menu() -> String:
	var next_path := _get_next_battle_definition_path()
	var next_text := next_path if next_path != "" else "None"
	var state := "Battle cleared" if _phase == VSPhase.BATTLE_END and bool(_settlement_reward_summary.get("rewards_enabled", false)) else "In battle"
	return "Current: %s\nMap: %s\nState: %s\nNext: %s\nStory: %s" % [
		get_battle_id(),
		_get_map_id(),
		state,
		next_text,
		JSON.stringify(_story_progress),
	]

func _format_camp_menu() -> String:
	return "Default Plan: train class progress, learn baseline skills, use available fruit, and enhance equipped gear when resources allow.\nLast Report:\n%s" % _last_camp_report

func _format_tactics_menu() -> String:
	var lines: Array[String] = []
	for unit in _unit_cells.keys():
		lines.append(_format_tactical_profile(unit))
	if lines.is_empty():
		return "No tactical profiles loaded."
	return "\n".join(lines)

func _format_equipment_menu() -> String:
	var lines: Array[String] = []
	for unit_id_variant in _roster.get_party():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			continue
		lines.append("%s: %s" % [unit.display_name, _format_equipment_summary(unit)])
	for unit_id_variant in _roster.get_reserve_ids():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			continue
		var equipment := _format_equipment_summary(unit)
		if equipment != "None":
			lines.append("Reserve %s: %s" % [unit.display_name, equipment])
	if lines.is_empty():
		return "No equipment tracked."
	return "\n".join(lines)

func _format_roster_menu() -> String:
	var party_names := _stringify_name_array(_roster.get_party())
	var reserve_names := _stringify_name_array(_roster.get_reserve_ids())
	var departed_names := _stringify_name_array(_roster.get_departed_ids())
	return "Party: %s\nReserve: %s\nDeparted: %s" % [
		", ".join(party_names) if not party_names.is_empty() else "None",
		", ".join(reserve_names) if not reserve_names.is_empty() else "None",
		", ".join(departed_names) if not departed_names.is_empty() else "None",
	]

func _format_boss_menu() -> String:
	var boss := _get_primary_boss_unit()
	if boss == null:
		return "No boss in this battle."
	var profile: Dictionary = _boss_profiles.get(boss, {})
	var state: Dictionary = _boss_states.get(boss, {})
	var max_hp: int = _combat._combat_units[boss]["max_hp"]
	var hp: int = _combat.get_unit_hp(boss)
	var phase := int(state.get("phase", 1))
	return "%s\nPhase: %d - %s\nHP: %d/%d\nCheckpoint: Phase %d at %d HP\nHint: %s" % [
		String(profile.get("title", boss.display_name)),
		phase,
		_get_boss_phase_name(profile, phase),
		hp,
		max_hp,
		int(state.get("checkpoint_phase", phase)),
		int(state.get("checkpoint_hp", hp)),
		String(profile.get("hint", "None")),
	]

func _format_settlement_menu() -> String:
	if _settlement_reward_summary.is_empty():
		return "No settlement result yet. Win or lose the battle to generate rewards."
	var equipment_names: Array[String] = []
	for name in _settlement_reward_summary.get("equipment_names", []):
		equipment_names.append(String(name))
	var note: String = String(_settlement_reward_summary.get("note", ""))
	return "Result: %s\nRating: %s\nEXP per survivor: %d\nGold: +%d\nMaterials: +%d\nEquipment: %s\nPlayer damage taken: %d\nPlayer deaths: %d\n%s" % [
		String(_settlement_reward_summary.get("result", "Unknown")),
		_rating_name(int(_settlement_reward_summary.get("rating", BattleEvaluation.Rating.NORMAL))),
		int(_settlement_reward_summary.get("exp_per_unit", 0)),
		int(_settlement_reward_summary.get("gold_awarded", 0)),
		int(_settlement_reward_summary.get("materials_awarded", 0)),
		", ".join(equipment_names) if not equipment_names.is_empty() else "None",
		int(_settlement_reward_summary.get("player_damage_taken", 0)),
		int(_settlement_reward_summary.get("player_deaths", 0)),
		note,
	]

func _get_primary_boss_unit() -> Unit:
	for unit in _boss_profiles.keys():
		if is_instance_valid(unit):
			return unit
	return null

func _get_boss_phase_name(profile: Dictionary, phase: int) -> String:
	var phase_names: Array = profile.get("phase_names", [])
	var index := maxi(phase - 1, 0)
	if index < phase_names.size():
		return String(phase_names[index])
	return "Phase %d" % phase

func _refresh_boss_label() -> void:
	if _boss_label == null:
		return
	var boss := _get_primary_boss_unit()
	if boss == null:
		_boss_label.visible = false
		_boss_label.text = ""
		return
	_boss_label.visible = true
	var profile: Dictionary = _boss_profiles.get(boss, {})
	var state: Dictionary = _boss_states.get(boss, {})
	var phase := int(state.get("phase", 1))
	if not _combat.is_unit_alive(boss):
		_boss_label.text = "Boss: %s\nDefeated" % String(profile.get("title", boss.display_name))
		return
	_boss_label.text = "Boss: %s\nPhase %d: %s\nHP: %d/%d" % [
		String(profile.get("title", boss.display_name)),
		phase,
		_get_boss_phase_name(profile, phase),
		_combat.get_unit_hp(boss),
		int(_combat._combat_units[boss]["max_hp"]),
	]

func _stringify_name_array(unit_ids: Array) -> Array[String]:
	var names: Array[String] = []
	for unit_id_variant in unit_ids:
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit == null:
			names.append(String(unit_id_variant))
		else:
			names.append(unit.display_name)
	return names

func _restore_result_ui() -> void:
	_result_label.visible = false
	if _combat.get_result() == CombatSystem.CombatResult.VICTORY:
		_result_label.text = "VICTORY!"
		_result_label.modulate = Color(0.2, 0.8, 0.3)
		_result_label.visible = true
	elif _combat.get_result() == CombatSystem.CombatResult.DEFEAT:
		_result_label.text = "DEFEAT..."
		_result_label.modulate = Color(0.9, 0.2, 0.2)
		_result_label.visible = true

func _sync_phase_prompt() -> void:
	_refresh_action_bar()
	var actor: Unit = _combat.get_current_actor()
	if _phase == VSPhase.BATTLE_END:
		return
	if actor == null:
		_info_label.text = "Battle state restored."
		return
	if _combat.get_unit_team(actor) == CombatSystem.Team.ENEMY:
		_info_label.text = "Enemy turn: %s" % actor.display_name
	else:
		_info_label.text = "Your turn: Click %s or use the action bar." % actor.display_name

func _build_unit_id_map() -> Dictionary:
	var out: Dictionary = {}
	for unit in _unit_cells.keys():
		out[String(unit.unit_id)] = unit
	return out

func _build_all_unit_id_map() -> Dictionary:
	var out: Dictionary = {}
	for child in get_children():
		if child is Unit:
			out[String((child as Unit).unit_id)] = child
	return out

func _find_unit_by_id(unit_id: String) -> Unit:
	for unit in _unit_cells.keys():
		if String(unit.unit_id) == unit_id:
			return unit
	return null

func _cycle_map_size() -> void:
	var idx: int = MAP_SIZE_OPTIONS.find(_map_size)
	idx = (idx + 1) % MAP_SIZE_OPTIONS.size()
	set_map_size(MAP_SIZE_OPTIONS[idx])
	_info_label.text = "Map size changed to %d×%d." % [_map_size, _map_size]

func _cycle_speed_tier() -> void:
	var next_tier: int = (_speed_controller.get_tier() + 1) % 3
	_speed_controller.set_tier(next_tier)
	_refresh_camera_status()

func _toggle_auto_battle() -> void:
	if _phase == VSPhase.BATTLE_END:
		_info_label.text = "Auto-battle is paused at battle end."
		return
	if _is_settlement_overlay_visible():
		_info_label.text = "Auto-battle is paused during settlement."
		return
	_auto_battle_controller.set_enabled(not _auto_battle_controller.is_enabled())
	_refresh_camera_status()
	_refresh_action_bar()
	if _auto_battle_controller.is_enabled():
		if not _try_start_auto_current_turn():
			_info_label.text = "Auto-battle enabled. It will control player units when their turns are ready."
	else:
		_info_label.text = "Auto-battle disabled. Player control restored."

func _toggle_menu() -> void:
	_menu_open = not _menu_open
	_set_menu_overlay_visible(_menu_open)
	if _menu_open:
		_set_management_overlay_visible(false)
	if _menu_open:
		_play_ui_cue("menu")
	_refresh_menu_content()
	if _menu_open:
		set_active_menu_tab(_active_menu_tab)
	else:
		_refresh_action_bar()

func _save_to_slot(slot: int) -> void:
	if SaveManager.save_game(slot):
		_info_label.text = "Saved to slot %d." % slot
		_play_ui_cue("save")
	else:
		_info_label.text = "Save failed for slot %d." % slot
		_play_ui_cue("error")

func _load_from_slot(slot: int) -> void:
	if not SaveManager.load_game(slot):
		_info_label.text = "No save in slot %d." % slot
		_play_ui_cue("error")
		return
	var save_data: SaveData = SaveManager.consume_pending_loaded_data()
	_reset_runtime_systems()
	_apply_loaded_save_data(save_data)
	_refresh_all()
	_info_label.text = "Loaded slot %d." % slot
	_play_ui_cue("save")

func _return_to_main_menu() -> void:
	SaveManager.clear_pending_loaded_data()
	SceneManager.switch_scene("main_menu")

# --- Input ---

func _input(event: InputEvent) -> void:
	if _is_settlement_overlay_visible():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				if _settlement_continue_btn != null and not _settlement_continue_btn.disabled:
					_on_settlement_continue_pressed()
		return
	if _is_management_overlay_visible():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_M]:
			close_management_screen()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _menu_open:
		if _turn_sequence_running:
			return
		_handle_grid_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if _turn_sequence_running:
			match event.keycode:
				KEY_B:
					_toggle_auto_battle()
				KEY_ESCAPE, KEY_M:
					_toggle_menu()
			return
		match event.keycode:
			KEY_1:
				_on_action_move()
			KEY_2:
				_on_action_attack()
			KEY_3:
				_on_action_standby()
			KEY_4:
				_on_action_end_turn()
			KEY_5:
				_on_action_skill()
			KEY_G:
				set_grid_overlay_enabled(not _grid_overlay_enabled)
			KEY_C:
				_cycle_map_size()
			KEY_V:
				_cycle_speed_tier()
			KEY_B:
				_toggle_auto_battle()
			KEY_ESCAPE, KEY_M:
				_toggle_menu()
			KEY_F5:
				_save_to_slot(1)
			KEY_F9:
				_load_from_slot(1)

func _handle_grid_click(click_pos: Vector2) -> void:
	var grid_pos := _find_nearest_grid_pos(click_pos)
	if grid_pos.x < 0:
		return

	match _phase:
		VSPhase.SELECT_UNIT:
			if _grid_units.has(grid_pos):
				var unit: Unit = _grid_units[grid_pos]
				if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER and _combat.is_unit_alive(unit) and unit == _combat.get_current_actor():
					_select_unit(unit)
		VSPhase.SELECT_MOVE:
			if grid_pos in _move_range:
				_do_move(grid_pos)
		VSPhase.SELECT_TARGET:
			if grid_pos in _attack_range:
				if _targeting_skill_id != &"":
					_do_skill(grid_pos)
				else:
					_do_attack(grid_pos)

func _select_unit(unit: Unit) -> void:
	_selected_unit = unit
	_targeting_skill_id = &""
	_clear_highlights()
	_move_range = _get_move_range(unit)
	_highlight_cells(_move_range, Color(SRPGTheme.JADE.r, SRPGTheme.JADE.g, SRPGTheme.JADE.b, 0.72))
	_phase = VSPhase.SELECT_MOVE
	_info_label.text = "%s selected. Click a highlighted tile to move, or press 2 to attack." % unit.display_name
	_refresh_all_units()
	_refresh_action_bar()

func _do_move(target_pos: Vector2i) -> void:
	_move_unit_to_cell(_selected_unit, target_pos)
	_clear_highlights()
	_move_range.clear()
	_info_label.text = "%s moved. Press 2 to attack or 3 to standby." % _selected_unit.display_name
	_phase = VSPhase.SELECT_TARGET
	_attack_range = _get_attack_range(_selected_unit)
	_highlight_cells(_attack_range, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.78))
	_refresh_action_bar()

func _do_attack(target_pos: Vector2i) -> void:
	var target: Unit = _grid_units[target_pos]
	var applied_damage: int = _apply_basic_attack(_selected_unit, target, 20.0, 10.0)
	_show_damage_number(target_pos, applied_damage)
	_clear_highlights()
	_attack_range.clear()
	_targeting_skill_id = &""
	_end_player_turn()

func _do_skill(target_pos: Vector2i) -> void:
	var target: Unit = _grid_units[target_pos]
	var skill_id: StringName = _targeting_skill_id
	var skill: SkillData = _selected_unit.skill_component.get_skill(skill_id)
	if skill == null:
		_info_label.text = "Skill unavailable."
		_targeting_skill_id = &""
		_refresh_action_bar()
		return
	if not _actions.execute_action(_selected_unit, ActionSystem.ActionType.SKILL, skill.mp_cost):
		_info_label.text = "%s does not have enough MP for %s." % [_selected_unit.display_name, skill.name]
		_targeting_skill_id = &""
		_refresh_action_bar()
		return
	_play_attack_feedback(_selected_unit, target)
	var damage: int = int(round(float(_selected_unit.skill_component.calculate_skill_damage(skill_id)) * _get_tactical_damage_multiplier(_selected_unit, target)))
	var applied_damage: int = _combat.apply_damage(target, damage, _selected_unit)
	_selected_unit.skill_component.use_skill(skill_id, [target])
	_show_damage_number(target_pos, applied_damage)
	_info_label.text = "%s used %s for %d damage." % [_selected_unit.display_name, skill.name, applied_damage]
	_clear_highlights()
	_attack_range.clear()
	_targeting_skill_id = &""
	_end_player_turn()

# --- Actions ---

func _on_action_move() -> void:
	if _phase == VSPhase.SELECT_UNIT and _combat.get_current_actor() != null:
		_select_unit(_combat.get_current_actor())

func _on_action_attack() -> void:
	if _phase == VSPhase.SELECT_MOVE:
		_clear_highlights()
		_move_range.clear()
		_targeting_skill_id = &""
		_phase = VSPhase.SELECT_TARGET
		_attack_range = _get_attack_range(_selected_unit)
		_highlight_cells(_attack_range, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.78))
		_info_label.text = "%s: Click a highlighted enemy tile to attack." % _selected_unit.display_name
		_refresh_action_bar()

func _on_action_skill() -> void:
	var actor: Unit = _selected_unit if _selected_unit != null else _combat.get_current_actor()
	if not _can_use_skill_action(actor):
		return
	if _selected_unit == null:
		_selected_unit = actor
	_targeting_skill_id = _get_first_available_skill_id(actor)
	_clear_highlights()
	_move_range.clear()
	_phase = VSPhase.SELECT_TARGET
	_attack_range = _get_attack_range(actor)
	_highlight_cells(_attack_range, Color(SRPGTheme.GOLD.r, SRPGTheme.GOLD.g, SRPGTheme.GOLD.b, 0.86))
	_info_label.text = "%s: choose a target for %s." % [actor.display_name, SkillDefinitions.get_skill_name(_targeting_skill_id)]
	_refresh_all_units()
	_refresh_action_bar()

func _can_use_skill_action(unit: Unit) -> bool:
	if unit == null or _phase not in [VSPhase.SELECT_UNIT, VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		return false
	if _combat.get_unit_team(unit) != CombatSystem.Team.PLAYER:
		return false
	return _get_first_available_skill_id(unit) != &""

func _get_first_available_skill_id(unit: Unit) -> StringName:
	if unit == null:
		return &""
	var skills: Array = unit.skill_component.get_available_active_skills(_actions.get_current_mp(unit))
	if skills.is_empty():
		return &""
	return StringName(skills[0].get("skill_id", ""))

func _on_action_standby() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_targeting_skill_id = &""
		_end_player_turn()

func _on_action_end_turn() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_targeting_skill_id = &""
		_end_player_turn()

func _end_player_turn() -> void:
	_selected_unit = null
	_targeting_skill_id = &""
	_refresh_all_units()
	_combat.end_turn()
	_check_battle_end()
	if _phase != VSPhase.BATTLE_END:
		_process_next_turn()

func _process_next_turn() -> void:
	var actor: Unit = _combat.get_current_actor()
	if actor == null:
		return

	if _combat.get_unit_team(actor) == CombatSystem.Team.ENEMY:
		_phase = VSPhase.ENEMY_TURN
		_info_label.text = "Enemy turn: %s" % actor.display_name
		_refresh_turn_display()
		_refresh_all_units()
		_queue_controlled_turn(actor, CombatSystem.Team.PLAYER, 15.0, 8.0, "Enemy")
		return

	if _auto_battle_controller.should_auto_control(actor):
		_phase = VSPhase.ANIMATING
		_info_label.text = "Auto-battle: %s" % actor.display_name
		_refresh_turn_display()
		_refresh_all_units()
		_queue_controlled_turn(actor, CombatSystem.Team.ENEMY, 20.0, 10.0, "Auto-battle")
		return

	_phase = VSPhase.SELECT_UNIT
	_info_label.text = "Your turn: Click %s or use the action bar." % actor.display_name
	_refresh_turn_display()
	_refresh_all_units()
	_refresh_action_bar()

func _do_enemy_turn(enemy: Unit) -> void:
	var nearest_player: Unit = _find_nearest_target(enemy, CombatSystem.Team.PLAYER)

	if nearest_player != null:
		_perform_simple_turn(enemy, nearest_player, 15.0, 8.0)

	_combat.end_turn()
	_check_battle_end()
	if _phase != VSPhase.BATTLE_END:
		_process_next_turn()

func _do_auto_player_turn(unit: Unit) -> void:
	var nearest_enemy: Unit = _find_nearest_target(unit, CombatSystem.Team.ENEMY)

	if nearest_enemy != null:
		_perform_simple_turn(unit, nearest_enemy, 20.0, 10.0)

	_end_player_turn()

func _perform_simple_turn(actor: Unit, target_unit: Unit, attack_value: float, defense_value: float) -> void:
	if not _unit_cells.has(actor) or not _unit_cells.has(target_unit):
		return
	var actor_pos: Vector2i = _unit_cells[actor]
	var move_range: Array = _get_move_range(actor)
	var best_pos: Vector2i = _choose_best_approach_position(actor, target_unit, move_range)

	if best_pos != actor_pos:
		_move_unit_to_cell(actor, best_pos)

	if _can_attack_target(actor, target_unit):
		var target_pos: Vector2i = _unit_cells.get(target_unit, Vector2i(-1, -1))
		var damage: int = _apply_basic_attack(actor, target_unit, attack_value, defense_value)
		_show_damage_number(target_pos, damage)

func _try_start_auto_current_turn() -> bool:
	if _turn_sequence_running or _phase == VSPhase.BATTLE_END:
		return false
	var actor: Unit = _combat.get_current_actor()
	if actor == null:
		return false
	if _combat.get_unit_team(actor) != CombatSystem.Team.PLAYER:
		return false
	if not _auto_battle_controller.should_auto_control(actor):
		return false
	_phase = VSPhase.ANIMATING
	return _queue_controlled_turn(actor, CombatSystem.Team.ENEMY, 20.0, 10.0, "Auto-battle")

func _queue_controlled_turn(actor: Unit, target_team: int, attack_value: float, defense_value: float, label: String) -> bool:
	if _turn_sequence_running or actor == null or not _unit_cells.has(actor):
		return false
	_clear_highlights()
	_move_range.clear()
	_attack_range.clear()
	_selected_unit = actor
	_turn_sequence_running = true
	_controlled_turn_plan = {
		"actor": actor,
		"target_team": target_team,
		"attack_value": attack_value,
		"defense_value": defense_value,
		"label": label,
		"step": 0,
		"target": null,
		"best_pos": _unit_cells[actor],
	}
	_controlled_turn_timer = 0.0
	_refresh_turn_display()
	_refresh_all_units()
	_refresh_action_bar()
	_advance_controlled_turn_step()
	return true

func _advance_controlled_turn_step() -> void:
	if not _turn_sequence_running:
		return
	var actor: Unit = _controlled_turn_plan.get("actor")
	if actor == null or not _unit_cells.has(actor) or not _combat.is_unit_alive(actor):
		_finish_controlled_turn()
		return

	match int(_controlled_turn_plan.get("step", 0)):
		0:
			_begin_controlled_turn_step(actor)
		1:
			_move_controlled_turn_actor(actor)
		2:
			_attack_controlled_turn_target(actor)
		_:
			_finish_controlled_turn()

func _begin_controlled_turn_step(actor: Unit) -> void:
	var label: String = _controlled_turn_plan.get("label", "Auto-battle")
	var target_team: int = _controlled_turn_plan.get("target_team", CombatSystem.Team.ENEMY)
	_move_range = _get_move_range(actor)
	var target: Unit = _choose_ai_target(actor, target_team, float(_controlled_turn_plan.get("attack_value", 20.0)), _move_range)
	_controlled_turn_plan["target"] = target
	_highlight_cells(_move_range, Color(SRPGTheme.JADE.r, SRPGTheme.JADE.g, SRPGTheme.JADE.b, 0.72))
	if target == null:
		_info_label.text = "%s: %s has no available target." % [label, actor.display_name]
		_controlled_turn_plan["step"] = 3
	else:
		var best_pos: Vector2i = _choose_best_ai_position(actor, target, _move_range)
		_controlled_turn_plan["best_pos"] = best_pos
		_info_label.text = "%s: %s chooses a move." % [label, actor.display_name]
		_controlled_turn_plan["step"] = 1
	_refresh_all_units()
	_schedule_controlled_turn_step()

func _move_controlled_turn_actor(actor: Unit) -> void:
	var label: String = _controlled_turn_plan.get("label", "Auto-battle")
	var target: Unit = _controlled_turn_plan.get("target")
	var actor_pos: Vector2i = _unit_cells.get(actor, Vector2i(-1, -1))
	var best_pos: Vector2i = _controlled_turn_plan.get("best_pos", actor_pos)
	_clear_highlights()
	_move_range.clear()
	if best_pos != actor_pos:
		_move_unit_to_cell(actor, best_pos)
		if target != null:
			_info_label.text = "%s: %s moves toward %s." % [label, actor.display_name, target.display_name]
		else:
			_info_label.text = "%s: %s moves." % [label, actor.display_name]
	else:
		_info_label.text = "%s: %s holds position." % [label, actor.display_name]
	_attack_range = _get_attack_range(actor)
	_highlight_cells(_attack_range, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.78))
	_controlled_turn_plan["step"] = 2
	_refresh_all_units()
	_schedule_controlled_turn_step()

func _attack_controlled_turn_target(actor: Unit) -> void:
	var label: String = _controlled_turn_plan.get("label", "Auto-battle")
	var target: Unit = _controlled_turn_plan.get("target")
	_clear_highlights()
	_attack_range.clear()
	if target != null and _unit_cells.has(target) and _combat.is_unit_alive(target) and _can_attack_target(actor, target):
		var target_pos: Vector2i = _unit_cells.get(target, Vector2i(-1, -1))
		var damage: int = _apply_basic_attack(
			actor,
			target,
			float(_controlled_turn_plan.get("attack_value", 20.0)),
			float(_controlled_turn_plan.get("defense_value", 10.0))
		)
		if target_pos.x >= 0:
			_highlight_cells([target_pos], Color(SRPGTheme.GOLD.r, SRPGTheme.GOLD.g, SRPGTheme.GOLD.b, 0.90))
			_show_damage_number(target_pos, damage)
		_info_label.text = "%s: %s attacks %s for %d damage." % [label, actor.display_name, target.display_name, damage]
	else:
		_info_label.text = "%s: %s ends turn without an attack." % [label, actor.display_name]
	_controlled_turn_plan["step"] = 3
	_refresh_all_units()
	_schedule_controlled_turn_step()

func _finish_controlled_turn() -> void:
	_clear_highlights()
	_move_range.clear()
	_attack_range.clear()
	_selected_unit = null
	_turn_sequence_running = false
	_controlled_turn_plan.clear()
	_controlled_turn_timer = 0.0
	_refresh_all_units()
	_combat.end_turn()
	_check_battle_end()
	if _phase != VSPhase.BATTLE_END:
		_process_next_turn()

func _schedule_controlled_turn_step() -> void:
	_controlled_turn_timer = _get_controlled_turn_delay()

func _get_controlled_turn_delay() -> float:
	if _speed_controller.should_skip_animations():
		return 0.0
	var delay: float = _speed_controller.get_ai_delay() * 0.45
	return clampf(delay, _MIN_CONTROLLED_TURN_DELAY, _MAX_CONTROLLED_TURN_DELAY)

func _find_nearest_target(actor: Unit, target_team: int) -> Unit:
	if actor == null or not _unit_cells.has(actor):
		return null
	var actor_pos: Vector2i = _unit_cells[actor]
	var nearest: Unit = null
	var nearest_dist := 999
	for other in _unit_cells:
		if _combat.get_unit_team(other) != target_team or not _combat.is_unit_alive(other):
			continue
		var dist: int = abs(_unit_cells[other].x - actor_pos.x) + abs(_unit_cells[other].y - actor_pos.y)
		if dist < nearest_dist:
			nearest = other
			nearest_dist = dist
	return nearest

func _choose_ai_target(actor: Unit, target_team: int, attack_value: float, candidate_positions: Array = []) -> Unit:
	var candidates: Array[int] = []
	var actionable_candidates: Array[int] = []
	var hp_map: Dictionary = {}
	var target_weapons: Dictionary = {}
	var killable_ids: Array[int] = []
	var target_by_id: Dictionary = {}
	var index: int = 0
	for other in _unit_cells:
		if _combat.get_unit_team(other) != target_team or not _combat.is_unit_alive(other):
			continue
		candidates.append(index)
		target_by_id[index] = other
		hp_map[index] = _combat.get_unit_hp(other)
		target_weapons[index] = int(_get_tactical_profile(other).get("weapon_type", TacticalFormulas.WeaponType.SWORD))
		if _can_attack_target_from_any_position(actor, other, candidate_positions):
			actionable_candidates.append(index)
		var expected := DamageCalculation.calculate_damage(
			{"attack": attack_value, "strength": actor.get_effective_attribute(AttributeNames.Attribute.STR)},
			{"defense": 10.0},
			{"damage_multiplier": _get_actor_damage_multiplier(actor, other)}
		)
		if expected >= _combat.get_unit_hp(other):
			killable_ids.append(index)
		index += 1
	if candidates.is_empty():
		return null
	var brain := AIBrain.new(int(_get_tactical_profile(actor).get("ai_type", AI.AIType.BALANCED)))
	var target_candidates: Array[int] = candidates
	if not actionable_candidates.is_empty():
		target_candidates = actionable_candidates
	var viable_killable_ids: Array[int] = []
	for id in killable_ids:
		if target_candidates.has(id):
			viable_killable_ids.append(id)
	var chosen: int = brain.select_target_with_restraint(
		target_candidates,
		hp_map,
		viable_killable_ids,
		int(_get_tactical_profile(actor).get("weapon_type", TacticalFormulas.WeaponType.SWORD)),
		target_weapons
	)
	return target_by_id.get(chosen, _find_nearest_target(actor, target_team))

func _choose_best_ai_position(actor: Unit, target_unit: Unit, move_range: Array) -> Vector2i:
	var actor_pos: Vector2i = _unit_cells[actor]
	if target_unit == null or not _unit_cells.has(target_unit):
		return actor_pos
	var target_pos: Vector2i = _unit_cells[target_unit]
	var positions: Array[Dictionary] = []
	var attack_positions: Array[Dictionary] = []
	var candidate_positions: Array = move_range.duplicate()
	if not candidate_positions.has(actor_pos):
		candidate_positions.append(actor_pos)
	for pos in candidate_positions:
		var dist: int = abs(pos.x - target_pos.x) + abs(pos.y - target_pos.y)
		var entry := {
			"pos": pos,
			"height": int(_map_heights.get(pos, TerrainTypes.HEIGHT_PLAIN)),
			"dangerous": int(_map_terrain.get(pos, TerrainTypes.Terrain.NORMAL)) in [TerrainTypes.Terrain.MUD, TerrainTypes.Terrain.WATER_PUDDLE],
			"support": _has_nearby_ally(actor, pos),
			"distance_score": 1.0 / float(maxi(1, dist)),
		}
		positions.append(entry)
		if _can_attack_target_from_position(actor, pos, target_unit):
			attack_positions.append(entry)
	var current_dist: int = abs(actor_pos.x - target_pos.x) + abs(actor_pos.y - target_pos.y)
	var current_score: float = 1.0 / float(maxi(1, current_dist))
	if not _can_attack_target_from_position(actor, actor_pos, target_unit):
		current_score = -1.0
	var positions_to_score: Array[Dictionary] = positions
	if not attack_positions.is_empty():
		positions_to_score = attack_positions
	var brain := AIBrain.new(int(_get_tactical_profile(actor).get("ai_type", AI.AIType.BALANCED)))
	var best_idx := brain.select_position(positions_to_score, current_score)
	if best_idx < 0:
		return _choose_best_approach_position(actor, target_unit, move_range)
	return positions_to_score[best_idx]["pos"]

func _can_attack_target_from_any_position(actor: Unit, target_unit: Unit, positions: Array) -> bool:
	if not _unit_cells.has(actor):
		return false
	if _can_attack_target_from_position(actor, _unit_cells[actor], target_unit):
		return true
	for pos in positions:
		if _can_attack_target_from_position(actor, pos, target_unit):
			return true
	return false

func _can_attack_target_from_position(actor: Unit, from_pos: Vector2i, target_unit: Unit) -> bool:
	if not _unit_cells.has(target_unit):
		return false
	var target_pos: Vector2i = _unit_cells[target_unit]
	if target_pos == from_pos:
		return false
	var base_range := int(_get_tactical_profile(actor).get("attack_range", 2))
	var effective_range := TacticalFormulas.get_effective_range(
		base_range,
		int(_map_heights.get(from_pos, TerrainTypes.HEIGHT_PLAIN)),
		int(_map_heights.get(target_pos, TerrainTypes.HEIGHT_PLAIN))
	)
	return abs(from_pos.x - target_pos.x) + abs(from_pos.y - target_pos.y) <= maxi(1, effective_range)

func _has_nearby_ally(actor: Unit, pos: Vector2i) -> bool:
	var team := _combat.get_unit_team(actor)
	for other in _unit_cells:
		if other == actor or _combat.get_unit_team(other) != team or not _combat.is_unit_alive(other):
			continue
		var other_pos: Vector2i = _unit_cells[other]
		if abs(other_pos.x - pos.x) + abs(other_pos.y - pos.y) <= 2:
			return true
	return false

func _choose_best_approach_position(actor: Unit, target_unit: Unit, move_range: Array) -> Vector2i:
	var actor_pos: Vector2i = _unit_cells[actor]
	if target_unit == null or not _unit_cells.has(target_unit):
		return actor_pos
	var target_pos: Vector2i = _unit_cells[target_unit]
	var best_pos := actor_pos
	var best_dist: int = abs(actor_pos.x - target_pos.x) + abs(actor_pos.y - target_pos.y)
	for pos in move_range:
		var dist: int = abs(pos.x - target_pos.x) + abs(pos.y - target_pos.y)
		if dist < best_dist:
			best_dist = dist
			best_pos = pos
	return best_pos

func _move_unit_to_cell(unit: Unit, target_pos: Vector2i, animate: bool = true) -> void:
	var old_pos: Vector2i = _unit_cells[unit]
	_grid_units.erase(old_pos)
	_grid_units[target_pos] = unit
	_unit_cells[unit] = target_pos
	_update_unit_position(unit, target_pos, animate)

func _can_attack_target(actor: Unit, target_unit: Unit) -> bool:
	if not _unit_cells.has(actor) or not _unit_cells.has(target_unit):
		return false
	var target_pos: Vector2i = _unit_cells[target_unit]
	var attack_range: Array = _get_attack_range(actor)
	var final_pos: Vector2i = _unit_cells[actor]
	return attack_range.has(target_pos) or (abs(final_pos.x - target_pos.x) + abs(final_pos.y - target_pos.y) <= 2)

func _apply_basic_attack(actor: Unit, target_unit: Unit, attack_value: float, defense_value: float) -> int:
	_play_attack_feedback(actor, target_unit)
	_play_ui_cue("attack")
	var damage := DamageCalculation.calculate_damage(
		{"attack": attack_value, "strength": actor.get_effective_attribute(AttributeNames.Attribute.STR)},
		{"defense": defense_value},
		{"damage_multiplier": _get_actor_damage_multiplier(actor, target_unit)}
	)
	return _combat.apply_damage(target_unit, damage, actor)

func _get_actor_damage_multiplier(actor: Unit, target_unit: Unit = null) -> float:
	var multiplier := 1.0
	if _boss_profiles.has(actor):
		var state: Dictionary = _boss_states.get(actor, {})
		if int(state.get("phase", 1)) > 1:
			var profile: Dictionary = _boss_profiles.get(actor, {})
			multiplier *= maxf(1.0, float(profile.get("phase_damage_multiplier", 1.3)))
	if target_unit != null:
		multiplier *= _get_tactical_damage_multiplier(actor, target_unit)
	return multiplier

func _get_tactical_damage_multiplier(actor: Unit, target_unit: Unit) -> float:
	var actor_profile := _get_tactical_profile(actor)
	var target_profile := _get_tactical_profile(target_unit)
	var multiplier := TacticalFormulas.get_triangle_modifier(
		int(actor_profile.get("weapon_type", TacticalFormulas.WeaponType.SWORD)),
		int(target_profile.get("weapon_type", TacticalFormulas.WeaponType.SWORD))
	)
	var actor_pos: Vector2i = _unit_cells.get(actor, Vector2i(-1, -1))
	var target_pos: Vector2i = _unit_cells.get(target_unit, Vector2i(-1, -1))
	if actor_pos.x >= 0 and target_pos.x >= 0:
		var height_mods := TacticalFormulas.get_height_modifiers(
			int(_map_heights.get(actor_pos, TerrainTypes.HEIGHT_PLAIN)),
			int(_map_heights.get(target_pos, TerrainTypes.HEIGHT_PLAIN))
		)
		var height_bonus := maxf(0.0, float(height_mods.get("hit_modifier", 0.0)))
		multiplier *= 1.0 + height_bonus
		var target_terrain := int(_map_terrain.get(target_pos, TerrainTypes.Terrain.NORMAL))
		multiplier *= _get_elemental_damage_multiplier(int(actor_profile.get("element", TacticalFormulas.Element.NONE)), target_terrain)
	return multiplier

func _get_elemental_damage_multiplier(element: int, target_terrain: int) -> float:
	var reaction := TacticalFormulas.get_element_reaction(element, target_terrain)
	match reaction:
		TacticalFormulas.ElementReaction.BURN:
			return 1.20
		TacticalFormulas.ElementReaction.CONDUCT:
			return 1.25
		TacticalFormulas.ElementReaction.EVAPORATE:
			return 1.15
		TacticalFormulas.ElementReaction.MUD:
			return 0.90
		_:
			return 1.0

func _show_damage_number(target_pos: Vector2i, damage: int) -> void:
	if target_pos.x < 0 or not is_instance_valid(_grid_container):
		return
	var label := Label.new()
	label.text = "%d" % damage
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(72.0, 36.0)
	label.position = _project_cell_center(target_pos) - Vector2(36.0, _render_cell_size * 0.82)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SRPGTheme.apply_label(label, SRPGTheme.GOLD, 30)
	label.add_theme_color_override("font_shadow_color", Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	_grid_container.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -30.0), 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)

func _build_settlement_reward_summary(result_type: int) -> Dictionary:
	var is_defeat := result_type == SettlementResult.SettlementType.DEFEAT
	var rating := BattleEvaluation.classify(_player_deaths, _player_damage_taken, is_defeat)
	var survivors := _get_surviving_player_units()
	var rewards_enabled := result_type == SettlementResult.SettlementType.VICTORY
	var settlement: Dictionary = _battle_definition.get("settlement", {})
	var summary := {
		"result": "Victory" if rewards_enabled else "Defeat",
		"rating": rating,
		"rewards_enabled": rewards_enabled,
		"survivor_ids": _unit_ids(survivors),
		"exp_per_unit": 0,
		"gold_awarded": 0,
		"materials_awarded": 0,
		"equipment_items": [],
		"equipment_names": [],
		"equipment_count": 0,
		"player_damage_taken": _player_damage_taken,
		"player_deaths": _player_deaths,
		"note": String(settlement.get("reward_note", "")),
	}
	if not rewards_enabled:
		return summary

	var enemy_tiers := _build_defeated_enemy_tiers()
	var base_exp := ExperienceDistribution.distribute(
		enemy_tiers,
		survivors.size(),
		BattleEvaluation.bonus_for(rating)
	)
	summary["exp_per_unit"] = int(round(float(base_exp) * float(_difficulty_profile.get("exp_multiplier", 1.0))))

	var rng_seed := int(settlement.get("rng_seed", 0))
	var drops := DropCalculator.aggregate_drops(_build_defeated_enemy_reward_specs(), rng_seed)
	var resource_multiplier := float(_difficulty_profile.get("resource_multiplier", 1.0))
	summary["gold_awarded"] = int(round(float(drops.get("gold", 0)) * resource_multiplier))
	summary["materials_awarded"] = int(round(float(drops.get("materials", 0)) * resource_multiplier))
	var generated_equipment := _generate_reward_equipment_items(drops.get("equipment", []), rng_seed)
	summary["equipment_items"] = generated_equipment
	summary["equipment_names"] = _equipment_names(generated_equipment)
	summary["equipment_count"] = generated_equipment.size()
	return summary

func _apply_settlement_rewards(summary: Dictionary) -> void:
	if not bool(summary.get("rewards_enabled", false)):
		return
	var exp_per_unit := int(summary.get("exp_per_unit", 0))
	for unit_id in summary.get("survivor_ids", []):
		var unit := _find_unit_by_id(String(unit_id))
		if unit != null and exp_per_unit > 0:
			unit.class_component.add_class_exp(exp_per_unit)
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, int(summary.get("gold_awarded", 0)))
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, int(summary.get("materials_awarded", 0)))

	var receiver := _get_first_surviving_player()
	if receiver == null:
		return
	for item_def in summary.get("equipment_items", []):
		if typeof(item_def) != TYPE_DICTIONARY:
			continue
		receiver.equipment_component.add_item(EquipmentItem.new(item_def))

func _build_defeated_enemy_tiers() -> Array:
	var tiers: Array = []
	for entry in _battle_definition.get("units", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if BattleDefinitionLoader.resolve_team(String(entry.get("team", "enemy"))) != CombatSystem.Team.ENEMY:
			continue
		var reward: Dictionary = entry.get("reward", {})
		var fallback := "boss" if bool(entry.get("boss", false)) else "normal"
		tiers.append(BattleDefinitionLoader.resolve_enemy_tier(String(reward.get("tier", fallback))))
	return tiers

func _build_defeated_enemy_reward_specs() -> Array:
	var specs: Array = []
	for entry in _battle_definition.get("units", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if BattleDefinitionLoader.resolve_team(String(entry.get("team", "enemy"))) != CombatSystem.Team.ENEMY:
			continue
		var reward: Dictionary = entry.get("reward", {})
		var fallback_tier := "boss" if bool(entry.get("boss", false)) else "normal"
		var tier := BattleDefinitionLoader.resolve_enemy_tier(String(reward.get("tier", fallback_tier)))
		specs.append({
			"tier": tier,
			"damage_dealt": int(reward.get("damage_dealt", entry.get("hp", 0))),
			"is_boss_kill": tier == DropCalculator.EnemyTier.BOSS,
			"base_gold": int(reward.get("base_gold", 50)),
		})
	return specs

func _generate_reward_equipment_items(qualities: Array, rng_seed: int) -> Array:
	var items: Array = []
	for i in range(qualities.size()):
		var quality := int(qualities[i])
		var item_seed := rng_seed + i + 31 if rng_seed != 0 else 0
		var name := "%s Pass Trophy" % _quality_name(quality)
		items.append({
			"item_id": "chapter_01_reward_%d_%d" % [quality, i],
			"name": name,
			"slot": EquipmentDefinitions.Slot.WEAPON,
			"quality": quality,
			"rng_seed": item_seed,
			"affixes": EquipmentAffixGenerator.generate_affixes(quality, -1, item_seed),
		})
	return items

func _get_surviving_player_units() -> Array:
	var survivors: Array = []
	for unit in _unit_cells.keys():
		if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER and _combat.is_unit_alive(unit):
			survivors.append(unit)
	return survivors

func _get_first_surviving_player() -> Unit:
	var survivors := _get_surviving_player_units()
	if survivors.is_empty():
		return null
	return survivors[0]

func _unit_ids(units: Array) -> Array:
	var ids: Array = []
	for unit in units:
		ids.append(String(unit.unit_id))
	return ids

func _equipment_names(items: Array) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		if typeof(item) == TYPE_DICTIONARY:
			names.append(String(item.get("name", "Equipment")))
	return names

func _rating_name(rating: int) -> String:
	match rating:
		BattleEvaluation.Rating.PERFECT:
			return "Perfect"
		BattleEvaluation.Rating.EXCELLENT:
			return "Excellent"
		BattleEvaluation.Rating.FAIL:
			return "Fail"
		_:
			return "Normal"

func _quality_name(quality: int) -> String:
	match quality:
		EquipmentDefinitions.Quality.GOLD:
			return "Gold"
		EquipmentDefinitions.Quality.PURPLE:
			return "Purple"
		EquipmentDefinitions.Quality.BLUE:
			return "Blue"
		EquipmentDefinitions.Quality.GREEN:
			return "Green"
		_:
			return "White"

func _capture_campaign_carry_state() -> Dictionary:
	var carry_ui: Dictionary = capture_ui_preferences()
	carry_ui["menu_open"] = false
	carry_ui["management_open"] = false
	var carry_camera: Dictionary = capture_camera_preferences()
	carry_camera["grid_overlay_enabled"] = false
	return {
		"party_units": _capture_party_units(),
		"inventory_state": _inventory.serialize(),
		"battle_history": _battle_history_log.serialize(),
		"story_progress": _story_progress.duplicate(true),
		"ui_preferences": carry_ui,
		"camera_preferences": carry_camera,
		"last_camp_report": _last_camp_report,
	}

func _start_campaign_battle(path: String, carry: Dictionary) -> void:
	_hide_settlement_and_transient_overlays()
	var carried_units: Dictionary = _index_carried_units(carry.get("party_units", []))
	var carried_inventory: Dictionary = carry.get("inventory_state", {})
	var carried_history: Dictionary = carry.get("battle_history", {})
	var carried_story: Dictionary = carry.get("story_progress", {})
	var carried_ui: Dictionary = carry.get("ui_preferences", {})
	var carried_camera: Dictionary = carry.get("camera_preferences", {})
	var carried_camp_report: String = String(carry.get("last_camp_report", _last_camp_report))

	_reset_runtime_systems()
	_load_battle_definition(path)
	_last_camp_report = carried_camp_report
	_story_progress = _battle_definition.get("progress_on_start", {}).duplicate(true)
	for key in carried_story:
		_story_progress[key] = carried_story[key]
	for key in _battle_definition.get("progress_on_start", {}):
		_story_progress[key] = _battle_definition["progress_on_start"][key]

	set_map_size(int(_battle_definition.get("map_size", DEFAULT_MAP_SIZE)))
	if carried_inventory.is_empty():
		_seed_inventory_from_definition()
	else:
		_inventory.deserialize(carried_inventory)

	var deployed_units: Array = []
	for entry in _battle_definition.get("units", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var unit := _create_unit_from_definition(entry)
		if carried_units.has(String(unit.unit_id)):
			_apply_carried_unit_state(unit, carried_units[String(unit.unit_id)])
		if unit != null and _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
			deployed_units.append(unit)
	_seed_roster_from_definition(deployed_units)
	if not carried_history.is_empty():
		_battle_history_log.deserialize(carried_history)
	if not carried_ui.is_empty():
		apply_ui_preferences(carried_ui)
	if not carried_camera.is_empty():
		apply_camera_preferences(carried_camera)
	_hide_settlement_and_transient_overlays()
	_combat.start_battle(get_battle_id(), _get_map_id(), int(_battle_definition.get("difficulty", 1)))
	_actions.initialize(_unit_cells.keys(), _build_default_mp_config(_unit_cells.keys()))
	_speed_controller.deserialize({"tier": SpeedController.SpeedTier.NORMAL})
	_auto_battle_controller.deserialize({"enabled": false})
	_sync_phase_prompt()
	call_deferred("_hide_settlement_and_transient_overlays")
	_is_chapter_transitioning = false

func _index_carried_units(entries: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var unit_payload: Dictionary = entry.get("unit", {})
		var unit_id := String(unit_payload.get("unit_id", ""))
		if unit_id == "":
			continue
		out[unit_id] = unit_payload
	return out

func _apply_carried_unit_state(unit: Unit, payload: Dictionary) -> void:
	if unit == null or payload.is_empty():
		return
	unit.deserialize(payload)
	if _unit_labels.has(unit):
		(_unit_labels[unit] as Label).text = unit.display_name

func _apply_default_camp_plan() -> Dictionary:
	var lines: Array[String] = []
	var party_units := _get_party_units()
	for unit in party_units:
		_apply_default_skill_training(unit, lines)
		_apply_default_class_drill(unit, lines)
		_apply_default_attribute_training(unit, lines)
		_apply_default_equipment_enhancement(unit, lines)
	if lines.is_empty():
		lines.append("No eligible camp actions; resources or unlock conditions are insufficient.")
	_story_progress["last_camp_battle"] = get_battle_id()
	_story_progress["camp_actions_total"] = int(_story_progress.get("camp_actions_total", 0)) + lines.size()
	_last_camp_report = "\n".join(lines)
	return {"actions": lines.duplicate(), "report": _last_camp_report}

func _get_party_units() -> Array:
	var units: Array = []
	for unit_id_variant in _roster.get_party():
		var unit: Unit = _roster.get_character(StringName(unit_id_variant))
		if unit != null:
			units.append(unit)
	return units

func _apply_default_skill_training(unit: Unit, lines: Array[String]) -> void:
	if _inventory.has_resource(ResourceTypes.ResourceId.GOLD, 80) and unit.learn_skill(&"defend"):
		_inventory.remove_resource(ResourceTypes.ResourceId.GOLD, 80)
		lines.append("%s learned Defend." % unit.display_name)
	var skill_id := _get_first_trainable_skill_id(unit)
	if skill_id != &"":
		var result := unit.skill_component.apply_battle_proficiency(skill_id, 90)
		for trigger in result.get("trait_triggers", []):
			var traits: Array = trigger.get("available_traits", [])
			if not traits.is_empty():
				unit.skill_component.select_trait(skill_id, int(trigger.get("level", 0)), String(traits[0].get("trait_id", "")))
		if int(result.get("gained", 0)) > 0:
			lines.append("%s drilled %s (+%d proficiency)." % [unit.display_name, SkillDefinitions.get_skill_name(skill_id), int(result.get("gained", 0))])

func _get_first_trainable_skill_id(unit: Unit) -> StringName:
	for skill_data in unit.skill_component.get_all_skills():
		var skill: SkillData = skill_data
		if skill.frozen:
			continue
		return skill.skill_id
	return &""

func _apply_default_class_drill(unit: Unit, lines: Array[String]) -> void:
	var target_class := _get_recommended_advanced_class(unit.class_component.get_class_id())
	if target_class < 0:
		return
	if _inventory.has_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 2):
		_inventory.remove_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 2)
		unit.class_component.add_class_unlock_exp(target_class, 140)
		lines.append("%s gained %d %s unlock EXP." % [unit.display_name, 140, ClassNames.ClassID.keys()[target_class]])
	if unit.class_component.get_state() == ClassNames.ClassState.BASIC_ACTIVE:
		unit.class_component.try_unlock_advanced()
	var result := unit.execute_class_change(target_class)
	if bool(result.get("success", false)):
		lines.append("%s changed class to %s." % [unit.display_name, ClassNames.ClassID.keys()[target_class]])

func _apply_default_attribute_training(unit: Unit, lines: Array[String]) -> void:
	if not _inventory.has_resource(ResourceTypes.ResourceId.FRUIT_STR, 1):
		return
	if unit.use_fruit(AttributeNames.Attribute.STR):
		_inventory.remove_resource(ResourceTypes.ResourceId.FRUIT_STR, 1)
		lines.append("%s used STR fruit." % unit.display_name)

func _apply_default_equipment_enhancement(unit: Unit, lines: Array[String]) -> void:
	var item := _get_first_equipped_item(unit)
	if item == null:
		return
	var cost := unit.equipment_component.get_enhancement_cost(item.item_id)
	if cost.is_empty():
		return
	if not _inventory.has_resource(ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0))):
		return
	if not _inventory.has_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("materials", 0))):
		return
	var protected := _inventory.has_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 1)
	var result := unit.equipment_component.attempt_enhancement(item.item_id, _inventory, protected, 20260425)
	lines.append("%s enhanced %s -> %s level %d." % [
		unit.display_name,
		item.name,
		String(result.get("result", "attempted")),
		int(result.get("new_level", item.enhancement_level)),
	])

func _get_first_equipped_item(unit: Unit) -> EquipmentItem:
	for slot in unit.equipment_component.get_loadout():
		var item: EquipmentItem = unit.equipment_component.get_equipped_item(slot)
		if item != null:
			return item
	return null

func _get_recommended_advanced_class(class_id: int) -> int:
	match class_id:
		ClassNames.ClassID.BASIC_WARRIOR:
			return ClassNames.ClassID.ADV_SWORDMASTER
		ClassNames.ClassID.BASIC_MAGE:
			return ClassNames.ClassID.ADV_BATTLEMAGE
		ClassNames.ClassID.BASIC_ARCHER:
			return ClassNames.ClassID.ADV_MARKSMAN
		ClassNames.ClassID.BASIC_ROGUE:
			return ClassNames.ClassID.ADV_ASSASSIN
		ClassNames.ClassID.BASIC_CLERIC:
			return ClassNames.ClassID.ADV_HIGHCLERIC
		ClassNames.ClassID.BASIC_KNIGHT:
			return ClassNames.ClassID.ADV_PALADIN
		_:
			return -1

func _check_battle_end() -> void:
	var result := _combat.check_end_conditions()
	if result == CombatSystem.CombatResult.VICTORY:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "VICTORY!"
		_result_label.modulate = Color(0.2, 0.8, 0.3)
		_result_label.visible = true
		_info_label.text = "Battle won! All enemies defeated."
		_play_ui_cue("victory")
		_finalize_battle_result(SettlementResult.SettlementType.VICTORY, BattleEvaluation.Rating.PERFECT)
	elif result == CombatSystem.CombatResult.DEFEAT:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "DEFEAT..."
		_result_label.modulate = Color(0.9, 0.2, 0.2)
		_result_label.visible = true
		_info_label.text = "All allies defeated."
		_play_ui_cue("error")
		_finalize_battle_result(SettlementResult.SettlementType.DEFEAT, BattleEvaluation.Rating.FAIL)
	_refresh_action_bar()

func _finalize_battle_result(result_type: int, rating: int) -> void:
	if _battle_end_emitted:
		return
	_battle_end_emitted = true
	_settlement_reward_summary = _build_settlement_reward_summary(result_type)
	_apply_settlement_rewards(_settlement_reward_summary)
	_story_progress["last_battle_result"] = "victory" if result_type == SettlementResult.SettlementType.VICTORY else "defeat"
	if result_type == SettlementResult.SettlementType.VICTORY:
		for key in _battle_definition.get("progress_on_victory", {}):
			_story_progress[key] = _battle_definition["progress_on_victory"][key]
	_battle_history_log.append_battle({
		"battle_id": get_battle_id(),
		"result_type": result_type,
		"rating": int(_settlement_reward_summary.get("rating", rating)),
		"rewards_enabled": result_type == SettlementResult.SettlementType.VICTORY,
		"exp_awarded": int(_settlement_reward_summary.get("exp_per_unit", 0)),
		"gold_awarded": int(_settlement_reward_summary.get("gold_awarded", 0)),
		"materials_awarded": int(_settlement_reward_summary.get("materials_awarded", 0)),
		"equipment_count": int(_settlement_reward_summary.get("equipment_count", 0)),
		"timestamp": Time.get_unix_time_from_system(),
	})
	if _result_label.visible:
		_result_label.text = "%s\n%s\nEXP +%d | Gold +%d | Materials +%d" % [
			"VICTORY!" if result_type == SettlementResult.SettlementType.VICTORY else "DEFEAT...",
			_rating_name(int(_settlement_reward_summary.get("rating", rating))),
			int(_settlement_reward_summary.get("exp_per_unit", 0)),
			int(_settlement_reward_summary.get("gold_awarded", 0)),
			int(_settlement_reward_summary.get("materials_awarded", 0)),
		]
	_info_label.text = _format_settlement_menu()
	if result_type == SettlementResult.SettlementType.VICTORY:
		_show_settlement_overlay()
	_refresh_objective_label()
	_refresh_menu_content()
	_refresh_management_content()
	var winner: Node = _combat.get_current_actor()
	GameEvents.combat_ended.emit(winner)

# --- Signal handlers ---

func _on_turn_started(actor: Node) -> void:
	_refresh_turn_display()
	_refresh_status_panel()
	_refresh_action_bar()

func _on_health_changed(unit: Node, old_value: int, new_value: int) -> void:
	if _hp_bars.has(unit):
		_hp_bars[unit].value = new_value
	if unit is Unit and _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER and new_value < old_value:
		_player_damage_taken += old_value - new_value
	if new_value < old_value and new_value > 0:
		_play_hit_feedback(unit)
		_update_boss_phase(unit as Unit, new_value)
	_refresh_boss_label()
	_refresh_turn_display()
	_refresh_status_panel()

func _on_unit_died(unit: Node, killer: Node) -> void:
	if unit is Unit and _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
		_player_deaths += 1
	var pos: Vector2i = _unit_cells.get(unit, Vector2i(-1, -1))
	if pos.x >= 0:
		_grid_units.erase(pos)
	_unit_cells.erase(unit)
	_refresh_all_units()
	_refresh_turn_display()
	_refresh_boss_label()
	_play_death_feedback(unit)

func _update_boss_phase(unit: Unit, new_hp: int) -> void:
	if unit == null or not _boss_profiles.has(unit):
		return
	var max_hp := maxf(1.0, float(_combat._combat_units[unit]["max_hp"]))
	var hp_percent := clampf(float(new_hp) / max_hp, 0.0, 1.0)
	var profile: Dictionary = _boss_profiles[unit]
	var state: Dictionary = _boss_states.get(unit, {})
	var thresholds: Array = profile.get("phase_thresholds", [])
	var crossed := int(state.get("phase", 1)) - 1
	var changed := false
	while crossed < thresholds.size() and hp_percent <= float(thresholds[crossed]):
		crossed += 1
		changed = true
	if not changed:
		return
	var phase := crossed + 1
	state["phase"] = phase
	state["checkpoint_phase"] = phase
	state["checkpoint_hp"] = maxi(1, new_hp)
	_boss_states[unit] = state
	_story_progress["active_boss"] = String(unit.unit_id)
	_story_progress["boss_phase"] = phase
	_story_progress["boss_checkpoint"] = {
		"boss_id": String(unit.unit_id),
		"phase": phase,
		"hp": maxi(1, new_hp),
		"retained_hp_ratio": float(profile.get("checkpoint_retained_hp_ratio", 0.15)),
	}
	_info_label.text = "%s shifts to %s. Checkpoint saved." % [
		String(profile.get("title", unit.display_name)),
		_get_boss_phase_name(profile, phase),
	]

func _on_resource_changed(resource_type: int, old_amount: int, new_amount: int) -> void:
	_refresh_resource_hud()
