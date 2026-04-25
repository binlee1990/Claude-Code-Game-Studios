class_name VSBattle
extends Control
## Canonical vertical-slice battle scene.
## Combines the playable combat loop with the current Camera / UI / Save
## productization layer used by the formal `battle_arena.tscn` entry path.

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")

const GRID_SIZE := 15
const CELL_SIZE := 64
const MARGIN := 20
const DEFAULT_MAP_SIZE := 15
const MAP_SIZE_OPTIONS := [15, 20, 25]
const _RENDER_CELL_SIZES := {15: 42.0, 20: 32.0, 25: 26.0}
const _MIN_CONTROLLED_TURN_DELAY := 0.18
const _MAX_CONTROLLED_TURN_DELAY := 0.65
const _CAMERA_ROTATION_DEGREES := [0]
const _SCENE_KEY := "battle"
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
var _grid_units: Dictionary = {}  # Vector2i -> Unit
var _unit_cells: Dictionary = {}  # Unit -> Vector2i
var _move_range: Array = []
var _attack_range: Array = []

var _map_size: int = DEFAULT_MAP_SIZE
var _camera_rotation: int = 0
var _grid_overlay_enabled: bool = true
var _map_heights: Dictionary = {}  # Vector2i -> int
var _render_cell_size: float = 52.0
var _menu_open: bool = false
var _active_menu_tab: String = "character"
var _ui_preferences: Dictionary = _DEFAULT_UI_PREFERENCES.duplicate(true)
var _camera_preferences: Dictionary = _DEFAULT_CAMERA_PREFERENCES.duplicate(true)
var _battle_end_emitted: bool = false
var _turn_sequence_running: bool = false
var _controlled_turn_plan: Dictionary = {}
var _controlled_turn_timer: float = 0.0

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
var _result_label: Label
var _camera_state_label: Label
var _auto_button: Button
var _menu_layer: CanvasLayer
var _menu_panel: Panel
var _menu_content_label: Label
var _menu_buttons: Dictionary = {}

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
	_result_label.visible = false
	add_child(_result_label)

	_build_menu_overlay()

func _build_top_bar() -> void:
	var title := Label.new()
	title.text = "江湖试锋"
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

	_camera_state_label = Label.new()
	SRPGTheme.apply_label(_camera_state_label, SRPGTheme.PAPER_MUTED, 13)
	_top_bar.add_child(_camera_state_label)

func _build_action_bar() -> void:
	var action_specs := [
		{"id": "move", "text": "Move (1)", "cb": _on_action_move},
		{"id": "attack", "text": "Attack (2)", "cb": _on_action_attack},
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

	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.62)
	_menu_layer.add_child(blocker)

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

	_menu_layer.visible = false

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
	_move_range.clear()
	_attack_range.clear()
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

func _load_default_battle() -> void:
	_apply_default_preferences()
	set_map_size(DEFAULT_MAP_SIZE)
	_seed_demo_inventory()

	var p1: Unit = _create_unit("P1", "Swordsman", true, 80, Vector2i(2, 5), {"str": 22, "agi": 24})
	var p2: Unit = _create_unit("P2", "Archer", true, 60, Vector2i(4, 6), {"str": 18, "agi": 20})
	_create_unit("E1", "Dark Knight", false, 70, Vector2i(11, 7), {"str": 20, "agi": 12})
	_create_unit("E2", "Dark Mage", false, 55, Vector2i(9, 9), {"str": 16, "agi": 10})
	_seed_demo_equipment(p1, [
		{
			"item_id": "p1_bronze_sword",
			"name": "Bronze Sword",
			"slot": EquipmentDefinitions.Slot.WEAPON,
			"quality": EquipmentDefinitions.Quality.BLUE,
			"affixes": [{
				"type": EquipmentDefinitions.AffixType.STR,
				"value": 8,
				"attribute_type": AttributeNames.Attribute.STR,
				"stat_key": "",
				"category": EquipmentDefinitions.AffixCategory.ATTACK,
			}],
		},
	])
	_seed_demo_equipment(p2, [
		{
			"item_id": "p2_longbow",
			"name": "Longbow",
			"slot": EquipmentDefinitions.Slot.WEAPON,
			"quality": EquipmentDefinitions.Quality.BLUE,
			"affixes": [{
				"type": EquipmentDefinitions.AffixType.AGI,
				"value": 7,
				"attribute_type": AttributeNames.Attribute.AGI,
				"stat_key": "",
				"category": EquipmentDefinitions.AffixCategory.ATTACK,
			}],
		},
	])
	_seed_demo_roster([p1, p2])

	var all_units: Array = _unit_cells.keys()
	_combat.start_battle("vs_demo", "demo_map", 1)
	_actions.initialize(all_units, _build_default_mp_config(all_units))
	_speed_controller.deserialize({"tier": SpeedController.SpeedTier.NORMAL})
	_auto_battle_controller.deserialize({"enabled": false})
	_sync_phase_prompt()

func _apply_loaded_save_data(save_data: SaveData) -> void:
	if save_data == null or save_data.battle_state.is_empty():
		_load_default_battle()
		return

	_apply_default_preferences()
	apply_ui_preferences(save_data.ui_preferences)
	apply_camera_preferences(save_data.camera_preferences)

	if not save_data.inventory_state.is_empty():
		_inventory.deserialize(save_data.inventory_state)
	elif not save_data.inventory_items.is_empty():
		_restore_inventory_from_items(save_data.inventory_items)
	else:
		_seed_demo_inventory()

	if not save_data.battle_history.is_empty():
		_battle_history_log.deserialize(save_data.battle_history)

	_load_battle_from_state(save_data.battle_state)
	_restore_roster_from_save(save_data)

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

	var selected_unit_id: String = state.get("selected_unit_id", "")
	_selected_unit = _find_unit_by_id(selected_unit_id)
	_reflow_map_visuals()
	_restore_result_ui()
	_sync_phase_prompt()

func _seed_demo_inventory() -> void:
	_inventory.add_resource(ResourceTypes.ResourceId.GOLD, 500)
	_inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 18)
	_inventory.add_resource(ResourceTypes.ResourceId.FRUIT_STR, 3)
	_inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 2)

func _seed_demo_roster(deployed_units: Array) -> void:
	for unit in deployed_units:
		_roster.add_character(unit, CharacterRoster.Status.DEPLOYED)
	_roster.set_party([&"P1", &"P2"])
	var reserve_specs := [
		{"id": "R1", "name": "Cleric", "stats": {"str": 12, "agi": 14}, "status": CharacterRoster.Status.AVAILABLE},
		{"id": "R2", "name": "Rogue", "stats": {"str": 16, "agi": 21}, "status": CharacterRoster.Status.AVAILABLE},
		{"id": "R3", "name": "Lancer", "stats": {"str": 20, "agi": 16}, "status": CharacterRoster.Status.DEPARTED, "reason": "chapter_2_exit"},
		{"id": "R4", "name": "Mage", "stats": {"str": 11, "agi": 17}, "status": CharacterRoster.Status.AVAILABLE},
	]
	for spec in reserve_specs:
		var reserve_unit := Unit.new()
		reserve_unit.unit_id = StringName(spec["id"])
		reserve_unit.display_name = String(spec["name"])
		add_child(reserve_unit)
		_apply_unit_stats(reserve_unit, spec["stats"])
		if reserve_unit.unit_id == &"R2":
			_seed_demo_equipment(reserve_unit, [
				{
					"item_id": "r2_dagger",
					"name": "Scout Dagger",
					"slot": EquipmentDefinitions.Slot.WEAPON,
					"quality": EquipmentDefinitions.Quality.GREEN,
					"affixes": [{
						"type": EquipmentDefinitions.AffixType.AGI,
						"value": 4,
						"attribute_type": AttributeNames.Attribute.AGI,
						"stat_key": "",
						"category": EquipmentDefinitions.AffixCategory.ATTACK,
					}],
				},
			])
		_roster.add_character(reserve_unit, int(spec["status"]))
		if int(spec["status"]) == CharacterRoster.Status.DEPARTED:
			_roster.mark_story_departed(reserve_unit.unit_id, String(spec.get("reason", "")))

func _seed_demo_equipment(unit: Unit, item_defs: Array) -> void:
	for item_def in item_defs:
		var item := EquipmentItem.new(item_def)
		unit.equipment_component.add_item(item)
		unit.equipment_component.equip_item(item.item_id)

func _build_default_mp_config(units: Array) -> Dictionary:
	var config: Dictionary = {}
	for unit in units:
		if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER:
			config[unit] = {"max_mp": 100, "skill_costs": [20]}
		else:
			config[unit] = {"max_mp": 60, "skill_costs": [15]}
	return config

func _clear_unit_nodes() -> void:
	for unit in _unit_cells.keys():
		if is_instance_valid(unit):
			unit.free()
	_grid_units.clear()
	_unit_cells.clear()
	for child in get_children():
		if child is Unit and is_instance_valid(child):
			child.free()

	for dict_ref in [_unit_panels, _unit_labels, _hp_bars]:
		for value in dict_ref.values():
			if is_instance_valid(value):
				value.queue_free()
		dict_ref.clear()

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
	return data

## Apply a UI preference payload to the current scene.
func apply_ui_preferences(data: Dictionary) -> void:
	if data.is_empty():
		return
	for key in data:
		_ui_preferences[key] = data[key]
	_active_menu_tab = _ui_preferences.get("last_menu_tab", _active_menu_tab)
	_menu_open = data.get("menu_open", false)
	_menu_layer.visible = _menu_open
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
		units.append({
			"unit": unit.serialize(),
			"team": _combat.get_unit_team(unit),
			"max_hp": _combat._combat_units[unit]["max_hp"],
			"position": {"x": _unit_cells[unit].x, "y": _unit_cells[unit].y},
		})

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
	label.text = "H%d" % _map_heights.get(pos, 1)

func _update_cell_color(pos: Vector2i, override_color: Color = Color.TRANSPARENT) -> void:
	var cell: ColorRect = _cells[pos]
	if override_color != Color.TRANSPARENT:
		cell.color = override_color
		if _cell_height_labels.has(pos):
			(_cell_height_labels[pos] as Label).modulate = Color(1, 1, 1, 0.95)
		return

	var height: int = _map_heights.get(pos, 1)
	var parity: bool = (pos.x + pos.y) % 2 == 0
	var base_color: Color
	match height:
		0:
			base_color = Color(0.145, 0.215, 0.170) if parity else Color(0.170, 0.245, 0.190)
		1:
			base_color = Color(0.245, 0.235, 0.185) if parity else Color(0.285, 0.268, 0.205)
		2:
			base_color = Color(0.350, 0.255, 0.185) if parity else Color(0.395, 0.290, 0.205)
		_:
			base_color = Color(0.205, 0.210, 0.175)
	base_color.a = 0.94 if _grid_overlay_enabled else 0.62
	cell.color = base_color
	if _cell_height_labels.has(pos):
		(_cell_height_labels[pos] as Label).modulate = Color(0.92, 0.84, 0.66, 0.78)

func _project_cell_center(pos: Vector2i) -> Vector2:
	return Vector2(
		MARGIN + pos.x * _render_cell_size + (_render_cell_size * 0.5),
		MARGIN + pos.y * _render_cell_size + (_render_cell_size * 0.5)
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
	_refresh_menu_content()
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
		var lbl := Label.new()
		var prefix := ">" if unit == current else " "
		var team_tag := "[P]" if _combat.get_unit_team(unit) == CombatSystem.Team.PLAYER else "[E]"
		lbl.text = "%s %s %s HP:%d" % [prefix, team_tag, unit.display_name, _combat.get_unit_hp(unit)]
		SRPGTheme.apply_label(lbl, SRPGTheme.GOLD if unit == current else SRPGTheme.PAPER, 14)
		_turn_list.add_child(lbl)

func _clear_highlights() -> void:
	for pos in _cells.keys():
		_update_cell_color(pos)

func _highlight_cells(positions: Array, color: Color) -> void:
	for pos in positions:
		if _cells.has(pos):
			_update_cell_color(pos, color)

func _get_move_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result := []
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if abs(dx) + abs(dy) > 3:
				continue
			var target := pos + Vector2i(dx, dy)
			if target.x < 0 or target.x >= _map_size or target.y < 0 or target.y >= _map_size:
				continue
			if _grid_units.has(target) and _grid_units[target] != unit:
				continue
			result.append(target)
	return result

func _get_attack_range(unit: Unit) -> Array:
	var pos: Vector2i = _unit_cells[unit]
	var result := []
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if abs(dx) + abs(dy) > 2 or (dx == 0 and dy == 0):
				continue
			var target := pos + Vector2i(dx, dy)
			if target.x < 0 or target.x >= _map_size or target.y < 0 or target.y >= _map_size:
				continue
			if _grid_units.has(target):
				var target_unit: Unit = _grid_units[target]
				if _combat.get_unit_team(target_unit) != _combat.get_unit_team(unit):
					result.append(target)
	return result

func _update_unit_position(unit: Unit, pos: Vector2i) -> void:
	var center: Vector2 = _project_cell_center(pos)
	var panel: Panel = _unit_panels.get(unit)
	if panel:
		panel.position = center + Vector2(-panel.custom_minimum_size.x * 0.5, -panel.custom_minimum_size.y * 0.5)
	var label: Label = _unit_labels.get(unit)
	if label:
		label.position = center + Vector2(-24.0, -_render_cell_size * 0.62)
	var hp_bar: ProgressBar = _hp_bars.get(unit)
	if hp_bar:
		hp_bar.position = center + Vector2(-hp_bar.size.x * 0.5, _render_cell_size * 0.18)

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

func _refresh_camera_status() -> void:
	_camera_state_label.text = "View Top-Down | Grid %s | Map %d×%d | Speed x%d | Auto %s" % [
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

func _refresh_action_bar() -> void:
	if _turn_sequence_running or _phase in [VSPhase.ANIMATING, VSPhase.ENEMY_TURN, VSPhase.BATTLE_END]:
		for button in _action_buttons.values():
			(button as Button).disabled = true
		return
	var move_enabled: bool = _phase == VSPhase.SELECT_UNIT or _phase == VSPhase.SELECT_MOVE
	(_action_buttons["move"] as Button).disabled = not move_enabled
	(_action_buttons["attack"] as Button).disabled = _selected_unit == null and _phase != VSPhase.SELECT_TARGET
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
				text = "Character\nName: %s\nHP: %d\nMP: %d/%d\nSTR: %d\nAGI: %d\nClass: %s\nParty: %s\nReserve: %d | Departed: %d\nEquipment: %s" % [
					actor.display_name,
					_combat.get_unit_hp(actor),
					_actions.get_current_mp(actor),
					_actions.get_max_mp(actor),
					actor.get_effective_attribute(AttributeNames.Attribute.STR),
					actor.get_effective_attribute(AttributeNames.Attribute.AGI),
					ClassNames.ClassID.keys()[actor.class_component.get_class_id()],
					", ".join(_stringify_name_array(_roster.get_party())),
					_roster.get_reserve_ids().size(),
					_roster.get_departed_ids().size(),
					_format_equipment_summary(actor),
				]
		"inventory":
			text = "Inventory\nGold: %d\nMaterials: %d\nSTR Fruit: %d\nProtect Symbols: %d\nSerialized entries: %d" % [
				_inventory.get_amount(ResourceTypes.ResourceId.GOLD),
				_inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL),
				_inventory.get_amount(ResourceTypes.ResourceId.FRUIT_STR),
				_inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL),
				_capture_inventory_items().size(),
			]
		"save":
			text = "Save / Load\nCurrent Slot: %d\nPress F5 to save slot 1.\nPress F9 to load slot 1.\nContinue is now wired through SaveManager." % SaveManager.get_current_slot()
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
	_menu_layer.visible = _menu_open
	_refresh_menu_content()
	if _menu_open:
		set_active_menu_tab(_active_menu_tab)
	else:
		_refresh_action_bar()

func _save_to_slot(slot: int) -> void:
	if SaveManager.save_game(slot):
		_info_label.text = "Saved to slot %d." % slot
	else:
		_info_label.text = "Save failed for slot %d." % slot

func _load_from_slot(slot: int) -> void:
	if not SaveManager.load_game(slot):
		_info_label.text = "No save in slot %d." % slot
		return
	var save_data: SaveData = SaveManager.consume_pending_loaded_data()
	_reset_runtime_systems()
	_apply_loaded_save_data(save_data)
	_refresh_all()
	_info_label.text = "Loaded slot %d." % slot

func _return_to_main_menu() -> void:
	SaveManager.clear_pending_loaded_data()
	SceneManager.switch_scene("main_menu")

# --- Input ---

func _input(event: InputEvent) -> void:
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
				_do_attack(grid_pos)

func _select_unit(unit: Unit) -> void:
	_selected_unit = unit
	_clear_highlights()
	_move_range = _get_move_range(unit)
	_highlight_cells(_move_range, Color(SRPGTheme.JADE.r, SRPGTheme.JADE.g, SRPGTheme.JADE.b, 0.72))
	_phase = VSPhase.SELECT_MOVE
	_info_label.text = "%s selected. Click a highlighted tile to move, or press 2 to attack." % unit.display_name
	_refresh_all_units()
	_refresh_action_bar()

func _do_move(target_pos: Vector2i) -> void:
	var old_pos: Vector2i = _unit_cells[_selected_unit]
	_grid_units.erase(old_pos)
	_grid_units[target_pos] = _selected_unit
	_unit_cells[_selected_unit] = target_pos
	_update_unit_position(_selected_unit, target_pos)
	_clear_highlights()
	_move_range.clear()
	_info_label.text = "%s moved. Press 2 to attack or 3 to standby." % _selected_unit.display_name
	_phase = VSPhase.SELECT_TARGET
	_attack_range = _get_attack_range(_selected_unit)
	_highlight_cells(_attack_range, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.78))
	_refresh_action_bar()

func _do_attack(target_pos: Vector2i) -> void:
	var target: Unit = _grid_units[target_pos]
	var damage := DamageCalculation.calculate_damage(
		{"attack": 20.0, "strength": _selected_unit.get_attribute(AttributeNames.Attribute.STR)},
		{"defense": 10.0},
		{"damage_multiplier": 1.0}
	)
	var applied_damage: int = _combat.apply_damage(target, damage, _selected_unit)
	_show_damage_number(target_pos, applied_damage)
	_clear_highlights()
	_attack_range.clear()
	_end_player_turn()

# --- Actions ---

func _on_action_move() -> void:
	if _phase == VSPhase.SELECT_UNIT and _combat.get_current_actor() != null:
		_select_unit(_combat.get_current_actor())

func _on_action_attack() -> void:
	if _phase == VSPhase.SELECT_MOVE:
		_clear_highlights()
		_move_range.clear()
		_phase = VSPhase.SELECT_TARGET
		_attack_range = _get_attack_range(_selected_unit)
		_highlight_cells(_attack_range, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.78))
		_info_label.text = "%s: Click a highlighted enemy tile to attack." % _selected_unit.display_name
		_refresh_action_bar()

func _on_action_standby() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_end_player_turn()

func _on_action_end_turn() -> void:
	if _phase in [VSPhase.SELECT_MOVE, VSPhase.SELECT_TARGET]:
		_clear_highlights()
		_end_player_turn()

func _end_player_turn() -> void:
	_selected_unit = null
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
	var target: Unit = _find_nearest_target(actor, target_team)
	_controlled_turn_plan["target"] = target
	_move_range = _get_move_range(actor)
	_highlight_cells(_move_range, Color(SRPGTheme.JADE.r, SRPGTheme.JADE.g, SRPGTheme.JADE.b, 0.72))
	if target == null:
		_info_label.text = "%s: %s has no available target." % [label, actor.display_name]
		_controlled_turn_plan["step"] = 3
	else:
		var best_pos: Vector2i = _choose_best_approach_position(actor, target, _move_range)
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

func _move_unit_to_cell(unit: Unit, target_pos: Vector2i) -> void:
	var old_pos: Vector2i = _unit_cells[unit]
	_grid_units.erase(old_pos)
	_grid_units[target_pos] = unit
	_unit_cells[unit] = target_pos
	_update_unit_position(unit, target_pos)

func _can_attack_target(actor: Unit, target_unit: Unit) -> bool:
	if not _unit_cells.has(actor) or not _unit_cells.has(target_unit):
		return false
	var target_pos: Vector2i = _unit_cells[target_unit]
	var attack_range: Array = _get_attack_range(actor)
	var final_pos: Vector2i = _unit_cells[actor]
	return attack_range.has(target_pos) or (abs(final_pos.x - target_pos.x) + abs(final_pos.y - target_pos.y) <= 2)

func _apply_basic_attack(actor: Unit, target_unit: Unit, attack_value: float, defense_value: float) -> int:
	var damage := DamageCalculation.calculate_damage(
		{"attack": attack_value, "strength": actor.get_attribute(AttributeNames.Attribute.STR)},
		{"defense": defense_value},
		{"damage_multiplier": 1.0}
	)
	return _combat.apply_damage(target_unit, damage, actor)

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

func _check_battle_end() -> void:
	var result := _combat.check_end_conditions()
	if result == CombatSystem.CombatResult.VICTORY:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "VICTORY!"
		_result_label.modulate = Color(0.2, 0.8, 0.3)
		_result_label.visible = true
		_info_label.text = "Battle won! All enemies defeated."
		_finalize_battle_result(SettlementResult.SettlementType.VICTORY, BattleEvaluation.Rating.PERFECT)
	elif result == CombatSystem.CombatResult.DEFEAT:
		_phase = VSPhase.BATTLE_END
		_result_label.text = "DEFEAT..."
		_result_label.modulate = Color(0.9, 0.2, 0.2)
		_result_label.visible = true
		_info_label.text = "All allies defeated."
		_finalize_battle_result(SettlementResult.SettlementType.DEFEAT, BattleEvaluation.Rating.FAIL)
	_refresh_action_bar()

func _finalize_battle_result(result_type: int, rating: int) -> void:
	if _battle_end_emitted:
		return
	_battle_end_emitted = true
	_battle_history_log.append_battle({
		"battle_id": "vs_demo",
		"result_type": result_type,
		"rating": rating,
		"rewards_enabled": result_type == SettlementResult.SettlementType.VICTORY,
		"gold_awarded": _inventory.get_amount(ResourceTypes.ResourceId.GOLD),
		"materials_awarded": _inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL),
		"timestamp": Time.get_unix_time_from_system(),
	})
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
	_refresh_turn_display()
	_refresh_status_panel()

func _on_unit_died(unit: Node, killer: Node) -> void:
	var pos: Vector2i = _unit_cells.get(unit, Vector2i(-1, -1))
	if pos.x >= 0:
		_grid_units.erase(pos)
	_unit_cells.erase(unit)
	_refresh_all_units()
	_refresh_turn_display()

func _on_resource_changed(resource_type: int, old_amount: int, new_amount: int) -> void:
	_refresh_resource_hud()
