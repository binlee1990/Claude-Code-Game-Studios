class_name MainMenu
extends Control

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")
const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")
const HintBarScript := preload("res://src/ui/common/hint_bar.gd")
const BATTLE_SCENE_PATH := "res://src/ui/combat/battle_arena.tscn"

@onready var start_button: Button = $VBox/StartButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var base_button: Button = $VBox/BaseButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

var _status_label: Label
var _chapter2_button: Button

func _ready() -> void:
	_build_visuals()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	base_button.pressed.connect(_on_base_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_chapter2_button.pressed.connect(_on_chapter2_pressed)

	# 检查是否有存档
	continue_button.disabled = not SaveManager.has_save(1)
	_refresh_status_label()
	# AUDIO-P0-07: 主菜单 BGM
	_setup_bgm()
	if OS.get_cmdline_args().has("--srpg-playthrough-smoke"):
		call_deferred("_run_packaged_playthrough_smoke")

func _setup_bgm() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = load("res://assets/audio/bgm/main_menu_bgm.ogg")
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var player := AudioStreamPlayer.new()
	player.name = "MainMenuBGM"
	player.stream = stream
	player.volume_db = -10.0
	player.autoplay = true
	add_child(player)

func _on_start_pressed() -> void:
	SceneManager.switch_scene("battle")

func _on_chapter2_pressed() -> void:
	var sd := SaveData.new()
	sd.battle_state = {
		"battle_definition_path": "res://src/ui/combat/battle_definitions/chapter_02_act_a.json"
	}
	sd.story_progress = {
		"chapter": 2,
		"current_battle": "chapter_02_act_a",
		"chapter_02_started": true,
	}
	SaveManager._pending_loaded_data = sd
	SceneManager.switch_scene("battle")

func _on_continue_pressed() -> void:
	# 加载存档
	SaveManager.load_game(1)
	SceneManager.switch_scene("battle")

func _on_base_pressed() -> void:
	SceneManager.switch_scene("base")

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
	eyebrow.text = "SRPG VERTICAL SLICE"
	SRPGTheme.apply_label(eyebrow, SRPGTheme.GOLD, 15)
	title_stack.add_child(eyebrow)

	var title := Label.new()
	title.text = SRPGLocalizationScript.translate("game.title")
	SRPGTheme.apply_label(title, SRPGTheme.WHITE, 56, true)
	title_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SRPGLocalizationScript.translate("main.subtitle")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(subtitle, SRPGTheme.PAPER, 20)
	title_stack.add_child(subtitle)

	var seal := Label.new()
	seal.text = SRPGLocalizationScript.translate("main.seal")
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

	start_button.text = "开始游戏（Chapter 1）"
	continue_button.text = "读取存档"
	base_button.text = "基地"
	settings_button.text = "设置"
	quit_button.text = "退出"
	SRPGTheme.apply_button(start_button, true)
	SRPGTheme.apply_button(continue_button)
	SRPGTheme.apply_button(base_button)
	SRPGTheme.apply_button(settings_button)
	SRPGTheme.apply_button(quit_button, false, true)

	_chapter2_button = Button.new()
	_chapter2_button.name = "Chapter2Button"
	_chapter2_button.text = "开始游戏（Chapter 2）"
	SRPGTheme.apply_button(_chapter2_button)
	vbox.add_child(_chapter2_button)
	vbox.move_child(_chapter2_button, 1)

	_status_label = Label.new()
	_status_label.name = "SaveStatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_status_label, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(_status_label)

	# UI-P0-04: 底部按键提示条
	var hint_bar: Control = HintBarScript.new()
	hint_bar.name = "HintBar"
	add_child(hint_bar)
	hint_bar.set_hints([
		{"key": "↑↓",    "action": "选择"},
		{"key": "Enter",  "action": "确认"},
		{"key": "Esc",    "action": "退出确认"},
		{"key": "手柄A",  "action": "确认"},
		{"key": "手柄B",  "action": "返回"},
	])

func _refresh_status_label() -> void:
	if _status_label == null:
		return
	if continue_button.disabled:
		_status_label.text = "暂无存档"
		return
	var save_data: SaveData = SaveManager.peek_save(1)
	if save_data == null:
		_status_label.text = "暂无存档"
		return
	var progress: Dictionary = save_data.story_progress
	var chapter: int = int(progress.get("chapter", 1))
	var battle_id: String = String(progress.get("current_battle", ""))
	var ts: int = save_data.timestamp
	var save_time: String = "——"
	if ts > 0:
		var dt: Dictionary = Time.get_datetime_dict_from_unix_time(ts)
		save_time = "%02d:%02d" % [int(dt.get("hour", 0)), int(dt.get("minute", 0))]
	if battle_id.is_empty():
		_status_label.text = "第 %d 章 · 上次保存 %s" % [chapter, save_time]
	else:
		_status_label.text = "第 %d 章 · %s · 上次保存 %s" % [chapter, battle_id, save_time]

func _run_packaged_playthrough_smoke() -> void:
	var result := _execute_packaged_playthrough_smoke()
	if bool(result.get("success", false)):
		print("PACKAGED_PLAYTHROUGH_SMOKE PASS %s" % JSON.stringify(result))
		get_tree().quit(0)
	else:
		push_error("PACKAGED_PLAYTHROUGH_SMOKE FAIL %s" % JSON.stringify(result))
		get_tree().quit(1)

func _execute_packaged_playthrough_smoke() -> Dictionary:
	SaveManager.clear_pending_loaded_data()
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		return {"success": false, "reason": "missing_battle_scene"}
	var battle = scene.instantiate()
	add_child(battle)
	if battle.get_battle_id() != "chapter_01_tutorial":
		return {"success": false, "reason": "wrong_start_battle", "battle": battle.get_battle_id()}
	if not _smoke_clear_and_advance(battle, "chapter_01_crossroads"):
		return {"success": false, "reason": "failed_to_reach_crossroads", "battle": battle.get_battle_id()}
	if not _smoke_clear_and_advance(battle, "chapter_01_finale"):
		return {"success": false, "reason": "failed_to_reach_finale", "battle": battle.get_battle_id()}
	battle.open_management_screen("equipment")
	var management_state: Dictionary = battle.get_management_screen_state()
	if not bool(management_state.get("visible", false)):
		return {"success": false, "reason": "management_screen_not_visible"}
	if not SaveManager.save_game(6):
		return {"success": false, "reason": "save_failed"}
	battle.queue_free()
	battle = null
	if not SaveManager.load_game(6):
		return {"success": false, "reason": "load_failed"}
	var restored = scene.instantiate()
	add_child(restored)
	var restored_ok: bool = restored.get_battle_id() == "chapter_01_finale"
	restored_ok = restored_ok and bool(restored.get_management_screen_state().get("visible", false))
	restored_ok = restored_ok and String(restored.get_campaign_state().get("camp_report", "")) != ""
	var report: Dictionary = {
		"success": restored_ok,
		"battle": restored.get_battle_id(),
		"management_tab": restored.get_management_screen_state().get("tab", ""),
		"camp_report_present": String(restored.get_campaign_state().get("camp_report", "")) != "",
	}
	restored.queue_free()
	var save_path := "user://saves/save_6.tres"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	return report

func _smoke_clear_and_advance(battle, expected_next_battle: String) -> bool:
	_smoke_defeat_current_enemies(battle)
	if not battle.advance_to_next_battle():
		return false
	return battle.get_battle_id() == expected_next_battle

func _smoke_defeat_current_enemies(battle) -> void:
	var actor: Unit = battle._combat.get_current_actor()
	var enemies: Array = []
	for unit in battle._unit_cells.keys():
		if battle._combat.get_unit_team(unit) == CombatSystem.Team.ENEMY:
			enemies.append(unit)
	for enemy in enemies:
		battle._combat.apply_damage(enemy, 999, actor)
	battle._check_battle_end()
