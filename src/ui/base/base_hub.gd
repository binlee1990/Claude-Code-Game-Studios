class_name BaseHub
extends Control

## BASE-001 基地主界面
## 包含功能区 Tab 切换（训练场/市集）

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")
const HintBarScript := preload("res://src/ui/common/hint_bar.gd")
const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")
const ActionPoints := preload("res://src/core/base/action_points.gd")

const TAB_TRAINING: int = 0
const TAB_MARKET: int = 1
const TAB_INTEL: int = 2
const TAB_MANAGEMENT: int = 3
const DESIGN_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const MIN_UI_SCALE: float = 1.0
const MAX_UI_SCALE: float = 1.3
const _SCENE_KEY := "base"
const _BATTLE_END_PHASE := 5
const _CHAPTER_01_TO_CHAPTER_02_PATH := "res://src/ui/combat/battle_definitions/chapter_02_act_a.json"
const TrainingGroundScript := preload("res://src/ui/base/training_ground.gd")
const CharacterManagementScene := preload("res://src/ui/management/character_management_screen.tscn")

@onready var _tab_container: TabContainer
var _training_ground: Control = null
var _roster: CharacterRoster = null
var _character_screen: CharacterManagement = null
var _management_empty_label: Label = null
var _continue_campaign_btn: Button = null
var _campaign_status_label: Label = null
var _ui_scale: float = 1.0
var _advance_after_base_requested: bool = false

var _base_level: int = 1
var _gold: int = 0
var _materials: int = 0
var _action_points: int = 5
var _max_action_points: int = 5
var _action_point_model: ActionPoints = ActionPoints.new()

# Market state
var _market_item_list: VBoxContainer = null
var _market_item_count_ref: Label = null
var _market_selected_label_ref: Label = null
var _market_total_label_ref: Label = null
var _market_confirm_btn_ref: Button = null
var _market_msg_label_ref: Label = null
var _market_qty_spinbox_ref: SpinBox = null
var _market_inventory_list: VBoxContainer = null
var _market_is_buying: bool = true
var _market_selected_id: int = -1
var _market_selected_price: int = 0

const MARKET_ITEMS: Array[Dictionary] = [
	{"id": ResourceTypes.ResourceId.BASIC_MATERIAL, "name_key": "market.item.basic_material", "buy": 50, "sell": 25},
	{"id": ResourceTypes.ResourceId.FRUIT_STR, "name_key": "market.item.fruit_str", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_AGI, "name_key": "market.item.fruit_agi", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_CON, "name_key": "market.item.fruit_con", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_INT, "name_key": "market.item.fruit_int", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_CHA, "name_key": "market.item.fruit_cha", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.PROTECT_SYMBOL, "name_key": "market.item.protect_symbol", "buy": 500, "sell": 250},
]

func _ready() -> void:
	add_to_group("save_state_provider")
	_ui_scale = _calculate_ui_scale()
	_load_inventory_from_save()
	_load_action_points_from_save()
	_build_visuals()
	_setup_hint_bar()
	_update_resource_display()
	resized.connect(_on_resized)

func _calculate_ui_scale() -> float:
	return _calculate_ui_scale_for_size(get_viewport_rect().size)

func _calculate_ui_scale_for_size(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return MIN_UI_SCALE
	var width_density: float = 1.0 + maxf(0.0, viewport_size.x - DESIGN_VIEWPORT_SIZE.x) / DESIGN_VIEWPORT_SIZE.x * 0.30
	var height_guard: float = viewport_size.y / DESIGN_VIEWPORT_SIZE.y
	return clampf(minf(width_density, height_guard), MIN_UI_SCALE, MAX_UI_SCALE)

func _scaled(value: float) -> float:
	return SRPGTheme.scale_size(value, _ui_scale)

func _scaled_vec2(width: float, height: float) -> Vector2:
	return Vector2(_scaled(width), _scaled(height))

func _on_resized() -> void:
	var next_scale := _calculate_ui_scale()
	if absf(next_scale - _ui_scale) < 0.05:
		return
	_ui_scale = next_scale
	_rebuild_visuals()

func _rebuild_visuals() -> void:
	var current_tab: int = _tab_container.current_tab if _tab_container != null else TAB_TRAINING
	_clear_visuals()
	_build_visuals()
	_setup_hint_bar()
	_update_resource_display()
	if _tab_container != null:
		_tab_container.current_tab = clampi(current_tab, 0, _tab_container.get_child_count() - 1)

func _clear_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_tab_container = null
	_training_ground = null
	_roster = null
	_character_screen = null
	_management_empty_label = null
	_continue_campaign_btn = null
	_campaign_status_label = null
	_market_item_list = null
	_market_item_count_ref = null
	_market_selected_label_ref = null
	_market_total_label_ref = null
	_market_confirm_btn_ref = null
	_market_msg_label_ref = null
	_market_qty_spinbox_ref = null
	_market_inventory_list = null

func _build_visuals() -> void:
	_load_roster_from_save()

	# 背景墨迹效果
	var backdrop := InkBackdrop.new()
	backdrop.name = "InkBackdrop"
	backdrop.intensity = 0.92
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	# 整体布局：左侧信息面板 + 右侧 TabContainer
	var main_hbox := HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 0
	main_hbox.offset_top = 0
	main_hbox.offset_right = 0
	main_hbox.offset_bottom = 0
	main_hbox.add_theme_constant_override("separation", int(_scaled(16.0)))
	add_child(main_hbox)

	# 左侧基地信息面板（宽度 280px）
	var info_panel := _create_info_panel()
	info_panel.custom_minimum_size = Vector2(_scaled(320.0), 0.0)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_panel)

	# 右侧 TabContainer
	_tab_container = TabContainer.new()
	_tab_container.name = "TabContainer"
	_tab_container.tabs_visible = true
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(_tab_container)

	# Tab 1: 训练场
	var training_panel := _create_training_tab()
	_tab_container.add_child(training_panel)
	_tab_container.set_tab_title(TAB_TRAINING, _tr("base.tab.training"))

	# Tab 2: 市集
	var market_panel := _create_market_tab()
	_tab_container.add_child(market_panel)
	_tab_container.set_tab_title(TAB_MARKET, _tr("base.tab.market"))

	# Tab 3: 管理
	var intel_panel := _create_intel_tab()
	_tab_container.add_child(intel_panel)
	_tab_container.set_tab_title(TAB_INTEL, _tr("base.tab.intel"))

	# Tab 4: 管理
	var management_panel := _create_management_tab()
	_tab_container.add_child(management_panel)
	_tab_container.set_tab_title(TAB_MANAGEMENT, _tr("base.tab.management"))

	# 设置 Tab 切换信号
	_tab_container.tab_changed.connect(_on_tab_changed)

	# 底部 HintBar
	var hint_bar: Control = HintBarScript.new()
	hint_bar.name = "HintBar"
	add_child(hint_bar)

func _create_info_panel() -> Panel:
	var panel := Panel.new()
	panel.name = "InfoPanel"
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.GOLD)

	var vbox := VBoxContainer.new()
	vbox.name = "InfoVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(12.0)
	vbox.offset_top = _scaled(12.0)
	vbox.offset_right = -_scaled(12.0)
	vbox.offset_bottom = -_scaled(12.0)
	vbox.add_theme_constant_override("separation", int(_scaled(16.0)))
	panel.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = _tr("base.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label_scaled(title, _ui_scale, SRPGTheme.GOLD, 22, true)
	vbox.add_child(title)

	# 等级
	var level_row := _create_info_row(_tr("base.level"), "%s%d" % [_display_text("Lv."), _base_level])
	vbox.add_child(level_row)

	# 分隔线
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", int(_scaled(8.0)))
	vbox.add_child(sep)

	# 资源区域
	var resource_title := Label.new()
	resource_title.text = _tr("base.resources")
	SRPGTheme.apply_label_scaled(resource_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(resource_title)

	var gold_row := _create_info_row(_tr("base.gold"), "%d" % _gold, SRPGTheme.GOLD)
	gold_row.name = "GoldRow"
	vbox.add_child(gold_row)

	var mat_row := _create_info_row(_tr("base.materials"), "%d" % _materials, SRPGTheme.JADE)
	mat_row.name = "MaterialRow"
	vbox.add_child(mat_row)

	# 分隔线
	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", int(_scaled(8.0)))
	vbox.add_child(sep2)

	# 行动点
	var ap_title := Label.new()
	ap_title.text = _tr("base.action_points")
	SRPGTheme.apply_label_scaled(ap_title, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(ap_title)

	var ap_row := _create_info_row(_tr("base.remaining"), "%d / %d" % [_action_points, _max_action_points], SRPGTheme.CYAN)
	ap_row.name = "ActionPointRow"
	vbox.add_child(ap_row)

	var campaign_sep := HSeparator.new()
	campaign_sep.add_theme_constant_override("separation", int(_scaled(8.0)))
	vbox.add_child(campaign_sep)

	_campaign_status_label = Label.new()
	_campaign_status_label.name = "CampaignStatusLabel"
	_campaign_status_label.text = _get_campaign_status_text()
	_campaign_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label_scaled(_campaign_status_label, _ui_scale, SRPGTheme.PAPER_MUTED, 13)
	vbox.add_child(_campaign_status_label)

	# 添加弹性空间
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_continue_campaign_btn = Button.new()
	_continue_campaign_btn.name = "ContinueCampaignButton"
	_continue_campaign_btn.text = _tr("base.continue_campaign")
	_continue_campaign_btn.disabled = not can_continue_campaign()
	_continue_campaign_btn.pressed.connect(_on_continue_campaign_pressed)
	SRPGTheme.apply_button_scaled(_continue_campaign_btn, _ui_scale, true)
	vbox.add_child(_continue_campaign_btn)

	# 返回按钮
	var back_btn := Button.new()
	back_btn.text = _tr("base.back_main_menu")
	back_btn.pressed.connect(_on_back_pressed)
	SRPGTheme.apply_button_scaled(back_btn, _ui_scale)
	vbox.add_child(back_btn)

	return panel

func _create_info_row(label_text: String, value_text: String, value_color: Color = SRPGTheme.PAPER) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(_scaled(8.0)))

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label_scaled(lbl, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	SRPGTheme.apply_label_scaled(val, _ui_scale, value_color, 14)
	row.add_child(val)

	return row

func _create_training_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "TrainingTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = _scaled(8.0)
	panel.offset_top = _scaled(8.0)
	panel.offset_right = -_scaled(8.0)
	panel.offset_bottom = -_scaled(8.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_training_ground = TrainingGroundScript.new()
	_training_ground.name = "TrainingGround"
	if _training_ground.has_method("set_ui_scale"):
		_training_ground.set_ui_scale(_ui_scale)
	_training_ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	_training_ground.offset_left = 0
	_training_ground.offset_top = 0
	_training_ground.offset_right = 0
	_training_ground.offset_bottom = 0
	_training_ground.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_ground.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _training_ground.has_method("initialize"):
		_training_ground.initialize(_roster)
	if _training_ground.has_method("set_action_points"):
		_training_ground.set_action_points(_action_point_model)
	_training_ground.closed.connect(_on_training_closed)
	if _training_ground.has_signal("training_changed"):
		_training_ground.training_changed.connect(_on_training_changed)
	panel.add_child(_training_ground)

	return panel

func _create_intel_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "IntelTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = _scaled(8.0)
	panel.offset_top = _scaled(8.0)
	panel.offset_right = -_scaled(8.0)
	panel.offset_bottom = -_scaled(8.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var content_panel := Panel.new()
	content_panel.name = "IntelPanel"
	content_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_panel.offset_left = _scaled(12.0)
	content_panel.offset_top = _scaled(12.0)
	content_panel.offset_right = -_scaled(12.0)
	content_panel.offset_bottom = -_scaled(12.0)
	SRPGTheme.apply_panel(content_panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)
	panel.add_child(content_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(16.0)
	vbox.offset_top = _scaled(16.0)
	vbox.offset_right = -_scaled(16.0)
	vbox.offset_bottom = -_scaled(16.0)
	vbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	content_panel.add_child(vbox)

	var title := Label.new()
	title.name = "IntelTitleLabel"
	title.text = _tr("base.intel.title")
	SRPGTheme.apply_label_scaled(title, _ui_scale, SRPGTheme.GOLD, 20, true)
	vbox.add_child(title)

	var briefing := Label.new()
	briefing.name = "IntelBriefingLabel"
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing.text = _format_intel_briefing()
	SRPGTheme.apply_label_scaled(briefing, _ui_scale, SRPGTheme.PAPER, 15)
	vbox.add_child(briefing)

	var next := Label.new()
	next.name = "IntelNextLabel"
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next.text = _format_intel_next_preview()
	SRPGTheme.apply_label_scaled(next, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(next)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var ap_note := Label.new()
	ap_note.name = "IntelApLabel"
	ap_note.text = _tr("base.intel.no_ap")
	SRPGTheme.apply_label_scaled(ap_note, _ui_scale, SRPGTheme.JADE, 13)
	vbox.add_child(ap_note)

	return panel

func _create_market_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "MarketTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = _scaled(8.0)
	panel.offset_top = _scaled(8.0)
	panel.offset_right = -_scaled(8.0)
	panel.offset_bottom = -_scaled(8.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.name = "MarketHBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = _scaled(12.0)
	hbox.offset_top = _scaled(12.0)
	hbox.offset_right = -_scaled(12.0)
	hbox.offset_bottom = -_scaled(12.0)
	hbox.add_theme_constant_override("separation", int(_scaled(16.0)))
	panel.add_child(hbox)

	# Left: item list
	var item_panel := Panel.new()
	item_panel.name = "ItemPanel"
	item_panel.custom_minimum_size = Vector2(_scaled(280.0), 0.0)
	item_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(item_panel, SRPGTheme.INK_SOFT, SRPGTheme.GOLD)
	hbox.add_child(item_panel)

	var item_scroll := ScrollContainer.new()
	item_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_scroll.offset_left = _scaled(8.0)
	item_scroll.offset_top = _scaled(8.0)
	item_scroll.offset_right = -_scaled(8.0)
	item_scroll.offset_bottom = -_scaled(40.0)
	item_panel.add_child(item_scroll)

	_market_item_list = VBoxContainer.new()
	_market_item_list.name = "ItemList"
	_market_item_list.add_theme_constant_override("separation", int(_scaled(6.0)))
	item_scroll.add_child(_market_item_list)

	_market_item_count_ref = Label.new()
	_market_item_count_ref.name = "ItemCountLabel"
	_market_item_count_ref.anchor_top = 1.0
	_market_item_count_ref.anchor_bottom = 1.0
	_market_item_count_ref.offset_top = -_scaled(30.0)
	_market_item_count_ref.offset_bottom = -_scaled(8.0)
	_market_item_count_ref.offset_left = _scaled(8.0)
	_market_item_count_ref.offset_right = -_scaled(8.0)
	_market_item_count_ref.text = _tr("market.holding_count") % 0
	SRPGTheme.apply_label_scaled(_market_item_count_ref, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
	item_panel.add_child(_market_item_count_ref)

	# Right: trade panel
	var trade_panel := Panel.new()
	trade_panel.name = "TradePanel"
	trade_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(trade_panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)
	hbox.add_child(trade_panel)

	var trade_vbox := VBoxContainer.new()
	trade_vbox.name = "TradeVBox"
	trade_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	trade_vbox.offset_left = _scaled(12.0)
	trade_vbox.offset_top = _scaled(12.0)
	trade_vbox.offset_right = -_scaled(12.0)
	trade_vbox.offset_bottom = -_scaled(12.0)
	trade_vbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	trade_panel.add_child(trade_vbox)

	# Mode toggle
	var mode_hbox := HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", int(_scaled(8.0)))
	trade_vbox.add_child(mode_hbox)

	var buy_btn := Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = _tr("market.buy")
	buy_btn.pressed.connect(_set_trade_mode.bind(true))
	SRPGTheme.apply_button_scaled(buy_btn, _ui_scale, true)
	buy_btn.custom_minimum_size = _scaled_vec2(96.0, 40.0)
	mode_hbox.add_child(buy_btn)

	var sell_btn := Button.new()
	sell_btn.name = "SellButton"
	sell_btn.text = _tr("market.sell")
	sell_btn.pressed.connect(_set_trade_mode.bind(false))
	SRPGTheme.apply_button_scaled(sell_btn, _ui_scale)
	sell_btn.custom_minimum_size = _scaled_vec2(96.0, 40.0)
	mode_hbox.add_child(sell_btn)

	# Selected item info
	var selected_title := Label.new()
	selected_title.text = _tr("market.select_item")
	SRPGTheme.apply_label_scaled(selected_title, _ui_scale, SRPGTheme.GOLD, 16, true)
	trade_vbox.add_child(selected_title)

	_market_selected_label_ref = Label.new()
	_market_selected_label_ref.name = "SelectedLabel"
	_market_selected_label_ref.text = _tr("market.select_prompt")
	_market_selected_label_ref.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label_scaled(_market_selected_label_ref, _ui_scale, SRPGTheme.PAPER, 14)
	trade_vbox.add_child(_market_selected_label_ref)

	# Quantity
	var qty_hbox := HBoxContainer.new()
	qty_hbox.add_theme_constant_override("separation", int(_scaled(8.0)))
	trade_vbox.add_child(qty_hbox)

	var qty_lbl := Label.new()
	qty_lbl.text = _tr("market.quantity")
	SRPGTheme.apply_label_scaled(qty_lbl, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	qty_hbox.add_child(qty_lbl)

	_market_qty_spinbox_ref = SpinBox.new()
	_market_qty_spinbox_ref.name = "QuantitySpinBox"
	_market_qty_spinbox_ref.min_value = 1
	_market_qty_spinbox_ref.max_value = 99
	_market_qty_spinbox_ref.value = 1
	_market_qty_spinbox_ref.step = 1
	_market_qty_spinbox_ref.value_changed.connect(_on_quantity_changed)
	qty_hbox.add_child(_market_qty_spinbox_ref)

	# Total price
	_market_total_label_ref = Label.new()
	_market_total_label_ref.name = "TotalLabel"
	_market_total_label_ref.text = _tr("market.total_zero")
	SRPGTheme.apply_label_scaled(_market_total_label_ref, _ui_scale, SRPGTheme.GOLD, 16)
	trade_vbox.add_child(_market_total_label_ref)

	# Confirm button
	_market_confirm_btn_ref = Button.new()
	_market_confirm_btn_ref.name = "ConfirmButton"
	_market_confirm_btn_ref.text = _tr("market.confirm")
	_market_confirm_btn_ref.disabled = true
	_market_confirm_btn_ref.pressed.connect(_on_market_confirm)
	SRPGTheme.apply_button_scaled(_market_confirm_btn_ref, _ui_scale, true)
	trade_vbox.add_child(_market_confirm_btn_ref)

	# Message
	_market_msg_label_ref = Label.new()
	_market_msg_label_ref.name = "MessageLabel"
	_market_msg_label_ref.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.VERMILION, 14)
	trade_vbox.add_child(_market_msg_label_ref)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trade_vbox.add_child(spacer)

	# Inventory panel
	var inventory_panel := Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.custom_minimum_size = Vector2(_scaled(300.0), 0.0)
	inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(inventory_panel, SRPGTheme.INK_SOFT, SRPGTheme.JADE)
	hbox.add_child(inventory_panel)

	var inventory_vbox := VBoxContainer.new()
	inventory_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_vbox.offset_left = _scaled(12.0)
	inventory_vbox.offset_top = _scaled(12.0)
	inventory_vbox.offset_right = -_scaled(12.0)
	inventory_vbox.offset_bottom = -_scaled(12.0)
	inventory_vbox.add_theme_constant_override("separation", int(_scaled(8.0)))
	inventory_panel.add_child(inventory_vbox)

	var inventory_title := Label.new()
	inventory_title.text = _tr("market.inventory")
	SRPGTheme.apply_label_scaled(inventory_title, _ui_scale, SRPGTheme.GOLD, 16, true)
	inventory_vbox.add_child(inventory_title)

	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_vbox.add_child(inventory_scroll)

	_market_inventory_list = VBoxContainer.new()
	_market_inventory_list.name = "InventoryList"
	_market_inventory_list.add_theme_constant_override("separation", int(_scaled(6.0)))
	_market_inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.add_child(_market_inventory_list)

	# Populate items
	_populate_market_items()
	_refresh_market_inventory()
	_market_is_buying = true
	_market_selected_id = -1
	_market_selected_price = 0

	return panel

func _create_management_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "ManagementTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = _scaled(8.0)
	panel.offset_top = _scaled(8.0)
	panel.offset_right = -_scaled(8.0)
	panel.offset_bottom = -_scaled(8.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if _roster == null:
		_load_roster_from_save()

	if _roster == null or _roster.get_roster_size() == 0:
		_management_empty_label = Label.new()
		_management_empty_label.text = _tr("base.no_roster")
		_management_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_management_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_management_empty_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		SRPGTheme.apply_label_scaled(_management_empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 16)
		panel.add_child(_management_empty_label)
		return panel

	_character_screen = CharacterManagementScene.instantiate()
	if _character_screen.has_method("set_ui_scale"):
		_character_screen.set_ui_scale(_ui_scale)
	_character_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_character_screen.offset_left = 0
	_character_screen.offset_top = 0
	_character_screen.offset_right = 0
	_character_screen.offset_bottom = 0
	_character_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_character_screen)
	_character_screen.initialize(_roster)
	if _character_screen.has_method("set_story_progress"):
		var save_data := _get_current_save()
		_character_screen.set_story_progress(save_data.story_progress if save_data != null else {})
	_character_screen.party_changed.connect(_on_management_party_changed)
	if _character_screen.has_signal("equipment_changed"):
		_character_screen.equipment_changed.connect(_on_management_equipment_changed)

	return panel

func _load_inventory_from_save() -> void:
	if _inventory_has_any_resource():
		return
	var save_data: SaveData = SaveManager.peek_save(_get_save_slot())
	if save_data == null:
		return
	if not save_data.inventory_state.is_empty():
		Inventory.deserialize(save_data.inventory_state)
	elif not save_data.inventory_items.is_empty():
		_restore_inventory_from_items(save_data.inventory_items)

func _inventory_has_any_resource() -> bool:
	for resource_id in ResourceTypes.all_resource_ids():
		if Inventory.get_amount(int(resource_id)) > 0:
			return true
	return false

func _restore_inventory_from_items(items: Array) -> void:
	var snapshot: Dictionary = {}
	for entry in items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		snapshot[int(entry.get("resource_type", -1))] = int(entry.get("amount", 0))
	Inventory.deserialize(snapshot)

func _load_roster_from_save() -> void:
	if _roster != null:
		return
	var save_data: SaveData = SaveManager.peek_save(_get_save_slot())
	if save_data == null or save_data.party_units.is_empty():
		return
	_roster = CharacterRoster.new()
	add_child(_roster)
	_roster.load_data({"characters": save_data.party_units})

func _load_action_points_from_save() -> void:
	var save_data: SaveData = SaveManager.peek_save(_get_save_slot())
	if save_data == null:
		_action_point_model.reset_for_chapter(1)
		_sync_action_point_fields()
		return
	var story: Dictionary = save_data.story_progress
	var chapter_id := int(story.get("chapter", 1))
	var payload: Dictionary = story.get("base_action_points", {})
	if payload.is_empty():
		_action_point_model.reset_for_chapter(chapter_id)
	else:
		_action_point_model.deserialize(payload)
		_action_point_model.ensure_chapter(chapter_id)
	_sync_action_point_fields()

func _sync_action_point_fields() -> void:
	_action_points = _action_point_model.current_points
	_max_action_points = _action_point_model.max_points
	_set_info_row_value("ActionPointRow", "%d / %d" % [_action_points, _max_action_points])

func _get_save_slot() -> int:
	var current_slot := SaveManager.get_current_slot()
	if current_slot >= 0:
		return current_slot
	return 1

func get_scene_key() -> String:
	return _SCENE_KEY

func can_continue_campaign() -> bool:
	var save_data := _get_current_save()
	if save_data == null:
		return false
	var path := String(save_data.battle_state.get("battle_definition_path", ""))
	return not path.is_empty()

func _get_current_save() -> SaveData:
	return SaveManager.peek_save(_get_save_slot())

func _get_campaign_status_text() -> String:
	var save_data := _get_current_save()
	if save_data == null or save_data.battle_state.is_empty():
		return _tr("base.no_campaign_resume")
	if _should_advance_saved_battle_after_base(save_data):
		return _tr("base.next_ready") % _get_next_battle_title(save_data)
	return _tr("base.resume_ready") % _get_saved_battle_title(save_data)

func _get_saved_battle_title(save_data: SaveData) -> String:
	var path := String(save_data.battle_state.get("battle_definition_path", ""))
	var definition := _load_definition_preview(path)
	var fallback := String(save_data.story_progress.get("current_battle", save_data.battle_state.get("battle_id", "")))
	return _display_text(String(definition.get("chapter_title", fallback)))

func _get_next_battle_title(save_data: SaveData) -> String:
	var path := _get_next_battle_path_for_save(save_data)
	var definition := _load_definition_preview(path)
	if definition.has("chapter_title"):
		return _display_text(String(definition.get("chapter_title", "")))
	return _display_text(path.get_file().trim_suffix(".json").capitalize())

func _get_next_battle_path_for_save(save_data: SaveData) -> String:
	var current_path := String(save_data.battle_state.get("battle_definition_path", ""))
	var definition := _load_definition_preview(current_path)
	var next_path_variant: Variant = definition.get("next_battle_definition_path", "")
	if typeof(next_path_variant) == TYPE_STRING and String(next_path_variant).strip_edges() != "":
		return String(next_path_variant).strip_edges()
	if String(save_data.battle_state.get("battle_id", "")) == "chapter_01_finale":
		return _CHAPTER_01_TO_CHAPTER_02_PATH
	return ""

func _load_definition_preview(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _format_intel_briefing() -> String:
	var save_data := _get_current_save()
	if save_data == null:
		return _tr("base.no_campaign_resume")
	var path := String(save_data.battle_state.get("battle_definition_path", ""))
	var definition := _load_definition_preview(path)
	var title := _display_text(String(definition.get("chapter_title", save_data.story_progress.get("current_battle", ""))))
	var briefing := _display_text(String(definition.get("briefing", "No briefing available.")))
	var objective := _display_text(String(definition.get("objective", "")))
	return _tr("base.intel.briefing") % [title, briefing, objective]

func _format_intel_next_preview() -> String:
	var save_data := _get_current_save()
	if save_data == null:
		return _tr("base.intel.no_next")
	var next_path := _get_next_battle_path_for_save(save_data)
	if next_path == "":
		return _tr("base.intel.no_next")
	var definition := _load_definition_preview(next_path)
	var title := _display_text(String(definition.get("chapter_title", next_path.get_file().trim_suffix(".json").capitalize())))
	var objective := _display_text(String(definition.get("objective", "")))
	var briefing := _display_text(String(definition.get("briefing", "No briefing available.")))
	return _tr("base.intel.next") % [title, objective, briefing]

func _should_advance_saved_battle_after_base(save_data: SaveData = null) -> bool:
	if save_data == null:
		save_data = _get_current_save()
	if save_data == null:
		return false
	var state := save_data.battle_state
	if int(state.get("phase", -1)) != _BATTLE_END_PHASE:
		return false
	var summary: Dictionary = state.get("settlement_reward_summary", {})
	return bool(summary.get("rewards_enabled", false))

func _populate_market_items() -> void:
	if _market_item_list == null:
		return
	for item_def in MARKET_ITEMS:
		var item_name: String = _get_market_item_name(item_def)
		var buy_price: int = item_def.get("buy", 0)
		var sell_price: int = item_def.get("sell", 0)
		var btn := Button.new()
		btn.name = "Item_%s" % item_def.get("id", -1)
		btn.text = _tr("market.price_pair") % [item_name, buy_price, sell_price]
		btn.pressed.connect(_select_market_item.bind(item_def))
		SRPGTheme.apply_button_scaled(btn, _ui_scale, false, false, true)
		btn.custom_minimum_size = _scaled_vec2(240.0, 44.0)
		_market_item_list.add_child(btn)

func _select_market_item(item_def: Dictionary) -> void:
	_market_selected_id = item_def.get("id", -1)
	_market_selected_price = _get_market_price_for_mode(item_def, _market_is_buying)
	_update_market_ui()

func _set_trade_mode(is_buying: bool) -> void:
	_market_is_buying = is_buying
	if _market_qty_spinbox_ref != null:
		_market_qty_spinbox_ref.value = 1
	if _market_selected_id >= 0:
		for item_def in MARKET_ITEMS:
			if item_def.get("id", -1) == _market_selected_id:
				_market_selected_price = _get_market_price_for_mode(item_def, is_buying)
				break
	_update_market_item_list()
	_update_market_ui()

func _update_market_item_list() -> void:
	if _market_item_list == null:
		return
	var idx := 0
	for item_def in MARKET_ITEMS:
		if idx < _market_item_list.get_child_count():
			var btn: Button = _market_item_list.get_child(idx)
			var item_name: String = _get_market_item_name(item_def)
			var buy_price: int = item_def.get("buy", 0)
			var sell_price: int = item_def.get("sell", 0)
			btn.text = _tr("market.price_pair") % [item_name, buy_price, sell_price]
		idx += 1

func _update_market_ui() -> void:
	if _market_selected_label_ref == null:
		return
	if _market_selected_id < 0:
		_market_selected_label_ref.text = _tr("market.select_prompt")
		_market_total_label_ref.text = _tr("market.total_zero")
		_market_confirm_btn_ref.disabled = true
		_market_msg_label_ref.text = ""
		if _market_item_count_ref != null:
			_market_item_count_ref.text = _tr("market.holding_count") % 0
		return

	var item_name: String = ""
	var price: int = 0
	var player_amount: int = 0
	for item_def in MARKET_ITEMS:
		if item_def.get("id", -1) == _market_selected_id:
			item_name = _get_market_item_name(item_def)
			price = _get_market_price_for_mode(item_def, _market_is_buying)
			player_amount = Inventory.get_amount(_market_selected_id)
			break

	_market_selected_price = price
	var qty: int = int(_market_qty_spinbox_ref.value)
	var total: int = price * qty
	var mode_text := _tr("market.buy") if _market_is_buying else _tr("market.sell")

	_market_selected_label_ref.text = _tr("market.unit_price") % [item_name, mode_text, price, player_amount]
	_market_total_label_ref.text = _tr("market.total") % total

	if _market_is_buying:
		var can_buy: bool = Inventory.has_resource(ResourceTypes.ResourceId.GOLD, total)
		_market_confirm_btn_ref.disabled = not can_buy
		if not can_buy:
			_market_msg_label_ref.text = _tr("market.gold_insufficient")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.VERMILION, 14)
		else:
			_market_msg_label_ref.text = ""
	else:
		var can_sell: bool = player_amount >= qty
		_market_confirm_btn_ref.disabled = not can_sell
		if not can_sell:
			_market_msg_label_ref.text = _tr("market.item_insufficient")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.VERMILION, 14)
		else:
			_market_msg_label_ref.text = ""

	if _market_item_count_ref != null:
		_market_item_count_ref.text = _tr("market.holding_count") % player_amount

func _on_quantity_changed(_value: float) -> void:
	_update_market_ui()

func _on_market_confirm() -> void:
	if _market_selected_id < 0:
		return

	var qty: int = int(_market_qty_spinbox_ref.value)
	var total: int = _market_selected_price * qty
	var transaction_succeeded := false

	if _market_is_buying:
		if Inventory.has_resource(ResourceTypes.ResourceId.GOLD, total):
			Inventory.remove_resource(ResourceTypes.ResourceId.GOLD, total)
			Inventory.add_resource(_market_selected_id, qty)
			_market_msg_label_ref.text = _tr("market.buy_success")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.JADE, 14)
			transaction_succeeded = true
		else:
			_market_msg_label_ref.text = _tr("market.gold_insufficient")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.VERMILION, 14)
	else:
		if Inventory.has_resource(_market_selected_id, qty):
			Inventory.remove_resource(_market_selected_id, qty)
			Inventory.add_resource(ResourceTypes.ResourceId.GOLD, total)
			_market_msg_label_ref.text = _tr("market.sell_success")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.JADE, 14)
			transaction_succeeded = true
		else:
			_market_msg_label_ref.text = _tr("market.item_insufficient")
			SRPGTheme.apply_label_scaled(_market_msg_label_ref, _ui_scale, SRPGTheme.VERMILION, 14)

	_update_resource_display()
	_update_market_ui()
	_refresh_market_inventory()
	if transaction_succeeded:
		SaveManager.save_game(_get_save_slot())

func _get_market_price_for_mode(item_def: Dictionary, is_buying: bool) -> int:
	return int(item_def.get("buy" if is_buying else "sell", 0))

func _refresh_market_inventory() -> void:
	if _market_inventory_list == null:
		return
	for child in _market_inventory_list.get_children():
		child.queue_free()

	var shown := 0
	for resource_id in ResourceTypes.all_resource_ids():
		var amount := Inventory.get_amount(int(resource_id))
		if amount <= 0:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(_scaled(8.0)))
		_market_inventory_list.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = ResourceTypes.get_resource_name(int(resource_id))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.PAPER, 13)
		row.add_child(name_lbl)

		var amount_lbl := Label.new()
		amount_lbl.text = str(amount)
		amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		SRPGTheme.apply_label_scaled(amount_lbl, _ui_scale, SRPGTheme.GOLD, 13)
		row.add_child(amount_lbl)
		shown += 1

	if shown == 0:
		var empty_label := Label.new()
		empty_label.text = _tr("market.inventory_empty")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		SRPGTheme.apply_label_scaled(empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 13)
		_market_inventory_list.add_child(empty_label)

func _update_resource_display() -> void:
	_gold = Inventory.get_amount(ResourceTypes.ResourceId.GOLD)
	_materials = Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	_set_info_row_value("GoldRow", "%d" % _gold)
	_set_info_row_value("MaterialRow", "%d" % _materials)
	_sync_action_point_fields()
	_refresh_market_inventory()

func _set_info_row_value(row_name: String, text: String) -> void:
	var row := find_child(row_name, true, false)
	if row == null or row.get_child_count() < 2:
		return
	var val_label := row.get_child(1)
	if val_label is Label:
		(val_label as Label).text = text

func _setup_hint_bar() -> void:
	var hint_bar: Control = get_node_or_null("HintBar")
	if hint_bar != null and hint_bar.has_method("set_hints"):
		hint_bar.set_hints([
			{"key": "Tab",    "action": _tr("base.hint.switch")},
			{"key": "Enter",  "action": _tr("base.hint.continue")},
			{"key": "Esc",    "action": _tr("base.back_main_menu")},
		])

func _on_tab_changed(tab_index: int) -> void:
	if tab_index == TAB_MARKET:
		_update_resource_display()
		_update_market_item_list()
		_update_market_ui()
		_refresh_market_inventory()

func _on_back_pressed() -> void:
	if _roster != null and is_instance_valid(_roster):
		_roster.queue_free()
		_roster = null
	SceneManager.switch_scene("main_menu")

func _on_continue_campaign_pressed() -> void:
	if not can_continue_campaign():
		_set_campaign_status(_tr("base.no_campaign_resume"))
		return
	var slot := _get_save_slot()
	_advance_after_base_requested = _should_advance_saved_battle_after_base()
	if not SaveManager.save_game(slot):
		_advance_after_base_requested = false
		_set_campaign_status(_tr("base.continue_save_failed"))
		return
	if not SaveManager.load_game(slot):
		_advance_after_base_requested = false
		_set_campaign_status(_tr("base.continue_load_failed"))
		return
	_advance_after_base_requested = false
	SceneManager.switch_scene("battle")

func _set_campaign_status(text: String) -> void:
	if _campaign_status_label != null:
		_campaign_status_label.text = text

func _on_training_closed() -> void:
	pass

func _on_management_party_changed(_new_party: Array) -> void:
	SaveManager.save_game(_get_save_slot())

func _on_management_equipment_changed(_unit: Unit, _slot: int, _old_item_id: StringName, _new_item_id: StringName) -> void:
	SaveManager.save_game(_get_save_slot())

func _on_training_changed(_unit_id: StringName, _skill_id: StringName, _result: Dictionary) -> void:
	_sync_action_point_fields()
	SaveManager.save_game(_get_save_slot())

func _capture_inventory_items() -> Array:
	var items: Array = []
	var snapshot: Dictionary = Inventory.serialize()
	var resource_ids: Array = snapshot.keys()
	resource_ids.sort()
	for resource_id in resource_ids:
		items.append({
			"resource_type": int(resource_id),
			"amount": int(snapshot[resource_id]),
		})
	return items

func capture_runtime_state() -> Dictionary:
	var result := {
		"party_units": [],
		"inventory_items": _capture_inventory_items(),
		"inventory_state": Inventory.serialize(),
		"story_progress": _capture_story_progress(),
		"settings": {
			"locale": SRPGLocalizationScript.get_locale(),
		},
		"ui_preferences": _capture_base_ui_preferences(),
	}
	if _roster != null:
		result["party_units"] = _roster.get_data().get("characters", [])
	return result

func _capture_story_progress() -> Dictionary:
	var data: Dictionary = {}
	var save_data := _get_current_save()
	if save_data != null:
		data = save_data.story_progress.duplicate(true)
	_action_point_model.ensure_chapter(int(data.get("chapter", _action_point_model.chapter_id)))
	data["base_action_points"] = _action_point_model.serialize()
	return data

func _capture_base_ui_preferences() -> Dictionary:
	var data: Dictionary = {}
	var save_data := _get_current_save()
	if save_data != null:
		data = save_data.ui_preferences.duplicate(true)
	data["locale"] = SRPGLocalizationScript.get_locale()
	if _advance_after_base_requested:
		data["advance_after_base"] = true
	else:
		data.erase("advance_after_base")
	return data

func _get_market_item_name(item_def: Dictionary) -> String:
	return _tr(String(item_def.get("name_key", "")))

func _tr(key: String) -> String:
	return SRPGLocalizationScript.translate(key)

func _display_text(value: String) -> String:
	return SRPGLocalizationScript.display_text(value)
