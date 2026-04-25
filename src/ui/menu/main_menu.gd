class_name MainMenu
extends Control

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")

@onready var start_button: Button = $VBox/StartButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

var _status_label: Label

func _ready() -> void:
	_build_visuals()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 检查是否有存档
	continue_button.disabled = not SaveManager.has_save(1)
	_refresh_status_label()

func _on_start_pressed() -> void:
	# 开始新游戏
	SceneManager.switch_scene("battle")

func _on_continue_pressed() -> void:
	# 加载存档
	SaveManager.load_game(1)
	SceneManager.switch_scene("battle")

func _on_settings_pressed() -> void:
	if _status_label != null:
		_status_label.text = "设置会在下一阶段展开。当前版本已支持战斗内菜单与存档。"

func _on_quit_pressed() -> void:
	get_tree().quit()

func _build_visuals() -> void:
	var backdrop := InkBackdrop.new()
	backdrop.name = "InkBackdrop"
	backdrop.intensity = 0.92
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var title_stack := VBoxContainer.new()
	title_stack.name = "TitleStack"
	title_stack.anchor_left = 0.080
	title_stack.anchor_top = 0.180
	title_stack.anchor_right = 0.560
	title_stack.anchor_bottom = 0.720
	title_stack.offset_left = 0.0
	title_stack.offset_top = 0.0
	title_stack.offset_right = 0.0
	title_stack.offset_bottom = 0.0
	title_stack.add_theme_constant_override("separation", 10)
	add_child(title_stack)

	var eyebrow := Label.new()
	eyebrow.text = "VERTICAL SLICE"
	SRPGTheme.apply_label(eyebrow, SRPGTheme.GOLD, 15)
	title_stack.add_child(eyebrow)

	var title := Label.new()
	title.text = "江湖试锋"
	SRPGTheme.apply_label(title, SRPGTheme.WHITE, 56)
	title_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "深墨、纸白、朱红点睛的战棋原型"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(subtitle, SRPGTheme.PAPER, 20)
	title_stack.add_child(subtitle)

	var seal := Label.new()
	seal.text = "斩敌不是炫技，是一招定局。"
	seal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(seal, SRPGTheme.PAPER_MUTED, 16)
	title_stack.add_child(seal)

	var menu_plate := Panel.new()
	menu_plate.name = "MenuPlate"
	menu_plate.anchor_left = 0.610
	menu_plate.anchor_top = 0.315
	menu_plate.anchor_right = 0.910
	menu_plate.anchor_bottom = 0.735
	menu_plate.offset_left = -18.0
	menu_plate.offset_top = -22.0
	menu_plate.offset_right = 18.0
	menu_plate.offset_bottom = 24.0
	SRPGTheme.apply_panel(menu_plate, Color(0.085, 0.075, 0.070, 0.92), SRPGTheme.GOLD)
	add_child(menu_plate)
	move_child(menu_plate, $VBox.get_index())

	var vbox: VBoxContainer = $VBox
	vbox.anchor_left = 0.610
	vbox.anchor_top = 0.335
	vbox.anchor_right = 0.910
	vbox.anchor_bottom = 0.720
	vbox.offset_left = 0.0
	vbox.offset_top = 0.0
	vbox.offset_right = 0.0
	vbox.offset_bottom = 0.0
	vbox.add_theme_constant_override("separation", 12)

	start_button.text = "开始游戏"
	continue_button.text = "读取存档"
	settings_button.text = "设置"
	quit_button.text = "退出"
	SRPGTheme.apply_button(start_button, true)
	SRPGTheme.apply_button(continue_button)
	SRPGTheme.apply_button(settings_button)
	SRPGTheme.apply_button(quit_button, false, true)

	_status_label = Label.new()
	_status_label.name = "SaveStatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_status_label, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(_status_label)

func _refresh_status_label() -> void:
	if _status_label == null:
		return
	if continue_button.disabled:
		_status_label.text = "没有检测到 1 号存档。开始游戏会进入当前可玩战斗。"
	else:
		_status_label.text = "检测到 1 号存档，可以继续上次战斗。"
