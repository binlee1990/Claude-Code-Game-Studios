class_name BaseHub
extends Control

## BASE-001 基地主界面
## 包含功能区 Tab 切换（训练场/市集）

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")
const HintBarScript := preload("res://src/ui/common/hint_bar.gd")

const TAB_TRAINING: int = 0
const TAB_MARKET: int = 1
const TrainingGroundScript := preload("res://src/ui/base/training_ground.gd")

@onready var _tab_container: TabContainer
var _training_ground: Control = null

var _base_level: int = 1
var _gold: int = 0
var _materials: int = 0
var _action_points: int = 5
var _max_action_points: int = 5

# Market state
var _market_item_list: VBoxContainer = null
var _market_item_count_ref: Label = null
var _market_selected_label_ref: Label = null
var _market_total_label_ref: Label = null
var _market_confirm_btn_ref: Button = null
var _market_msg_label_ref: Label = null
var _market_qty_spinbox_ref: SpinBox = null
var _market_is_buying: bool = true
var _market_selected_id: int = -1
var _market_selected_price: int = 0

const MARKET_ITEMS: Array[Dictionary] = [
	{"id": ResourceTypes.ResourceId.BASIC_MATERIAL, "name": "基础材料", "buy": 50, "sell": 25},
	{"id": ResourceTypes.ResourceId.FRUIT_STR, "name": "力量果实", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_AGI, "name": "敏捷果实", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_CON, "name": "体力果实", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_INT, "name": "智力果实", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.FRUIT_CHA, "name": "魅力果实", "buy": 200, "sell": 100},
	{"id": ResourceTypes.ResourceId.PROTECT_SYMBOL, "name": "保护符", "buy": 500, "sell": 250},
]

func _ready() -> void:
	_build_visuals()
	_setup_hint_bar()
	_update_resource_display()

func _build_visuals() -> void:
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
	main_hbox.add_theme_constant_override("separation", 16)
	add_child(main_hbox)

	# 左侧基地信息面板（宽度 280px）
	var info_panel := _create_info_panel()
	info_panel.custom_minimum_size = Vector2(280.0, 0.0)
	main_hbox.add_child(info_panel)

	# 右侧 TabContainer
	_tab_container = TabContainer.new()
	_tab_container.name = "TabContainer"
	_tab_container.tabs_visible = true
	main_hbox.add_child(_tab_container)

	# Tab 1: 训练场
	var training_panel := _create_training_tab()
	_tab_container.add_child(training_panel)
	_tab_container.set_tab_title(TAB_TRAINING, "训练场")

	# Tab 2: 市集
	var market_panel := _create_market_tab()
	_tab_container.add_child(market_panel)
	_tab_container.set_tab_title(TAB_MARKET, "市集")

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
	vbox.offset_left = 12
	vbox.offset_top = 12
	vbox.offset_right = -12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "基地"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label(title, SRPGTheme.GOLD, 22, true)
	vbox.add_child(title)

	# 等级
	var level_row := _create_info_row("等级", "Lv.%d" % _base_level)
	vbox.add_child(level_row)

	# 分隔线
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	vbox.add_child(sep)

	# 资源区域
	var resource_title := Label.new()
	resource_title.text = "资源"
	SRPGTheme.apply_label(resource_title, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(resource_title)

	var gold_row := _create_info_row("金币", "%d" % _gold, SRPGTheme.GOLD)
	gold_row.name = "GoldRow"
	vbox.add_child(gold_row)

	var mat_row := _create_info_row("材料", "%d" % _materials, SRPGTheme.JADE)
	mat_row.name = "MaterialRow"
	vbox.add_child(mat_row)

	# 分隔线
	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	vbox.add_child(sep2)

	# 行动点
	var ap_title := Label.new()
	ap_title.text = "行动点"
	SRPGTheme.apply_label(ap_title, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(ap_title)

	var ap_row := _create_info_row("剩余", "%d / %d" % [_action_points, _max_action_points], SRPGTheme.CYAN)
	vbox.add_child(ap_row)

	# 添加弹性空间
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 返回按钮
	var back_btn := Button.new()
	back_btn.text = "返回主菜单"
	back_btn.pressed.connect(_on_back_pressed)
	SRPGTheme.apply_button(back_btn)
	vbox.add_child(back_btn)

	return panel

func _create_info_row(label_text: String, value_text: String, value_color: Color = SRPGTheme.PAPER) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(lbl, SRPGTheme.PAPER_MUTED, 14)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	SRPGTheme.apply_label(val, value_color, 14)
	row.add_child(val)

	return row

func _create_training_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "TrainingTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8

	_training_ground = TrainingGroundScript.new()
	_training_ground.name = "TrainingGround"
	_training_ground.closed.connect(_on_training_closed)
	panel.add_child(_training_ground)

	return panel

func _create_market_tab() -> Panel:
	var panel := Panel.new()
	panel.name = "MarketTab"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8

	var hbox := HBoxContainer.new()
	hbox.name = "MarketHBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_top = 12
	hbox.offset_right = -12
	hbox.offset_bottom = -12
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Left: item list
	var item_panel := Panel.new()
	item_panel.name = "ItemPanel"
	item_panel.custom_minimum_size = Vector2(220.0, 0.0)
	SRPGTheme.apply_panel(item_panel, SRPGTheme.INK_SOFT, SRPGTheme.GOLD)
	hbox.add_child(item_panel)

	var item_scroll := ScrollContainer.new()
	item_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_scroll.offset_left = 8
	item_scroll.offset_top = 8
	item_scroll.offset_right = -8
	item_scroll.offset_bottom = -40
	item_panel.add_child(item_scroll)

	_market_item_list = VBoxContainer.new()
	_market_item_list.name = "ItemList"
	_market_item_list.add_theme_constant_override("separation", 6)
	item_scroll.add_child(_market_item_list)

	_market_item_count_ref = Label.new()
	_market_item_count_ref.name = "ItemCountLabel"
	_market_item_count_ref.anchor_top = 1.0
	_market_item_count_ref.anchor_bottom = 1.0
	_market_item_count_ref.offset_top = -30.0
	_market_item_count_ref.offset_bottom = -8.0
	_market_item_count_ref.offset_left = 8.0
	_market_item_count_ref.offset_right = -8.0
	_market_item_count_ref.text = "持有: 0"
	SRPGTheme.apply_label(_market_item_count_ref, SRPGTheme.PAPER_MUTED, 12)
	item_panel.add_child(_market_item_count_ref)

	# Right: trade panel
	var trade_panel := Panel.new()
	trade_panel.name = "TradePanel"
	SRPGTheme.apply_panel(trade_panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)
	hbox.add_child(trade_panel)

	var trade_vbox := VBoxContainer.new()
	trade_vbox.name = "TradeVBox"
	trade_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	trade_vbox.offset_left = 12
	trade_vbox.offset_top = 12
	trade_vbox.offset_right = -12
	trade_vbox.offset_bottom = -12
	trade_vbox.add_theme_constant_override("separation", 12)
	trade_panel.add_child(trade_vbox)

	# Mode toggle
	var mode_hbox := HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 8)
	trade_vbox.add_child(mode_hbox)

	var buy_btn := Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = "买入"
	buy_btn.custom_minimum_size = Vector2(80, 36)
	buy_btn.pressed.connect(_set_trade_mode.bind(true))
	SRPGTheme.apply_button(buy_btn, true)
	mode_hbox.add_child(buy_btn)

	var sell_btn := Button.new()
	sell_btn.name = "SellButton"
	sell_btn.text = "卖出"
	sell_btn.custom_minimum_size = Vector2(80, 36)
	sell_btn.pressed.connect(_set_trade_mode.bind(false))
	SRPGTheme.apply_button(sell_btn)
	mode_hbox.add_child(sell_btn)

	# Selected item info
	var selected_title := Label.new()
	selected_title.text = "选择物品"
	SRPGTheme.apply_label(selected_title, SRPGTheme.GOLD, 16, true)
	trade_vbox.add_child(selected_title)

	_market_selected_label_ref = Label.new()
	_market_selected_label_ref.name = "SelectedLabel"
	_market_selected_label_ref.text = "请从左侧选择物品"
	_market_selected_label_ref.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_market_selected_label_ref, SRPGTheme.PAPER, 14)
	trade_vbox.add_child(_market_selected_label_ref)

	# Quantity
	var qty_hbox := HBoxContainer.new()
	qty_hbox.add_theme_constant_override("separation", 8)
	trade_vbox.add_child(qty_hbox)

	var qty_lbl := Label.new()
	qty_lbl.text = "数量:"
	SRPGTheme.apply_label(qty_lbl, SRPGTheme.PAPER_MUTED, 14)
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
	_market_total_label_ref.text = "总价: 0 金"
	SRPGTheme.apply_label(_market_total_label_ref, SRPGTheme.GOLD, 16)
	trade_vbox.add_child(_market_total_label_ref)

	# Confirm button
	_market_confirm_btn_ref = Button.new()
	_market_confirm_btn_ref.name = "ConfirmButton"
	_market_confirm_btn_ref.text = "确认交易"
	_market_confirm_btn_ref.disabled = true
	_market_confirm_btn_ref.pressed.connect(_on_market_confirm)
	SRPGTheme.apply_button(_market_confirm_btn_ref, true)
	trade_vbox.add_child(_market_confirm_btn_ref)

	# Message
	_market_msg_label_ref = Label.new()
	_market_msg_label_ref.name = "MessageLabel"
	_market_msg_label_ref.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.VERMILION, 14)
	trade_vbox.add_child(_market_msg_label_ref)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trade_vbox.add_child(spacer)

	# Populate items
	_populate_market_items()
	_market_is_buying = true
	_market_selected_id = -1
	_market_selected_price = 0

	return panel

func _populate_market_items() -> void:
	if _market_item_list == null:
		return
	for item_def in MARKET_ITEMS:
		var item_name: String = item_def.get("name", "Unknown")
		var buy_price: int = item_def.get("buy", 0)
		var btn := Button.new()
		btn.name = "Item_%s" % item_name
		btn.text = "%s (%d 金)" % [item_name, buy_price]
		btn.custom_minimum_size = Vector2(200, 40)
		btn.pressed.connect(_select_market_item.bind(item_def))
		SRPGTheme.apply_button(btn, false, false, true)
		_market_item_list.add_child(btn)

func _select_market_item(item_def: Dictionary) -> void:
	_market_selected_id = item_def.get("id", -1)
	_market_selected_price = item_def.get("buy" if _market_is_buying else "sell", 0)
	_update_market_ui()

func _set_trade_mode(is_buying: bool) -> void:
	_market_is_buying = is_buying
	_market_qty_spinbox_ref.value = 1
	if _market_selected_id >= 0:
		for item_def in MARKET_ITEMS:
			if item_def.get("id", -1) == _market_selected_id:
				_market_selected_price = item_def.get("buy" if is_buying else "sell", 0)
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
			var item_name: String = item_def.get("name", "Unknown")
			var price: int = item_def.get("buy" if _market_is_buying else "sell", 0)
			btn.text = "%s (%d 金)" % [item_name, price]
		idx += 1

func _update_market_ui() -> void:
	if _market_selected_label_ref == null:
		return
	if _market_selected_id < 0:
		_market_selected_label_ref.text = "请从左侧选择物品"
		_market_total_label_ref.text = "总价: 0 金"
		_market_confirm_btn_ref.disabled = true
		_market_msg_label_ref.text = ""
		if _market_item_count_ref != null:
			_market_item_count_ref.text = "持有: 0"
		return

	var item_name: String = ""
	var price: int = 0
	var player_amount: int = 0
	for item_def in MARKET_ITEMS:
		if item_def.get("id", -1) == _market_selected_id:
			item_name = item_def.get("name", "Unknown")
			price = item_def.get("buy" if _market_is_buying else "sell", 0)
			player_amount = Inventory.get_amount(_market_selected_id)
			break

	var qty: int = int(_market_qty_spinbox_ref.value)
	var total: int = price * qty

	_market_selected_label_ref.text = "%s\n单价: %d 金\n持有: %d" % [item_name, price, player_amount]
	_market_total_label_ref.text = "总价: %d 金" % total

	if _market_is_buying:
		var can_buy: bool = Inventory.has_resource(ResourceTypes.ResourceId.GOLD, total)
		_market_confirm_btn_ref.disabled = not can_buy
		if not can_buy:
			_market_msg_label_ref.text = "金币不足"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.VERMILION, 14)
		else:
			_market_msg_label_ref.text = ""
	else:
		var can_sell: bool = player_amount >= qty
		_market_confirm_btn_ref.disabled = not can_sell
		if not can_sell:
			_market_msg_label_ref.text = "持有数量不足"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.VERMILION, 14)
		else:
			_market_msg_label_ref.text = ""

	if _market_item_count_ref != null:
		_market_item_count_ref.text = "持有: %d" % player_amount

func _on_quantity_changed(_value: float) -> void:
	_update_market_ui()

func _on_market_confirm() -> void:
	if _market_selected_id < 0:
		return

	var qty: int = int(_market_qty_spinbox_ref.value)
	var total: int = _market_selected_price * qty

	if _market_is_buying:
		if Inventory.has_resource(ResourceTypes.ResourceId.GOLD, total):
			Inventory.remove_resource(ResourceTypes.ResourceId.GOLD, total)
			Inventory.add_resource(_market_selected_id, qty)
			_market_msg_label_ref.text = "购买成功!"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.JADE, 14)
		else:
			_market_msg_label_ref.text = "金币不足"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.VERMILION, 14)
	else:
		if Inventory.has_resource(_market_selected_id, qty):
			Inventory.remove_resource(_market_selected_id, qty)
			Inventory.add_resource(ResourceTypes.ResourceId.GOLD, total)
			_market_msg_label_ref.text = "出售成功!"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.JADE, 14)
		else:
			_market_msg_label_ref.text = "持有数量不足"
			SRPGTheme.apply_label(_market_msg_label_ref, SRPGTheme.VERMILION, 14)

	_update_resource_display()
	_update_market_ui()

func _update_resource_display() -> void:
	_gold = Inventory.get_amount(ResourceTypes.ResourceId.GOLD)
	_materials = Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	_set_info_row_value("GoldRow", "%d" % _gold)
	_set_info_row_value("MaterialRow", "%d" % _materials)

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
			{"key": "Tab",    "action": "切换功能区"},
			{"key": "Esc",    "action": "返回主菜单"},
		])

func _on_tab_changed(tab_index: int) -> void:
	if tab_index == TAB_MARKET:
		_update_resource_display()
		_update_market_item_list()
		_update_market_ui()

func _on_back_pressed() -> void:
	SceneManager.switch_scene("main_menu")

func _on_training_closed() -> void:
	# Training ground closed - could persist data here if needed
	pass
