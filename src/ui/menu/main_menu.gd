class_name MainMenu
extends Control

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")
const InkBackdrop := preload("res://src/ui/theme/ink_backdrop.gd")
const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")
const HintBarScript := preload("res://src/ui/common/hint_bar.gd")
const BATTLE_SCENE_PATH := "res://src/ui/combat/battle_arena.tscn"
const BASE_SCENE_PATH := "res://src/ui/base/base_hub.tscn"

@onready var start_button: Button = $VBox/StartButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var base_button: Button = $VBox/BaseButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

var _status_label: Label
var _chapter2_button: Button
var _chapter3_button: Button
var _language_button: Button
var _credits_button: Button
var _eyebrow_label: Label
var _title_label: Label
var _subtitle_label: Label
var _seal_label: Label
var _hint_bar: Control
var _credits_layer: CanvasLayer
var _credits_title_label: Label
var _credits_body_label: Label
var _credits_close_button: Button

func _ready() -> void:
	SRPGLocalizationScript.set_locale(SaveManager.load_locale_preference())
	_build_visuals()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	base_button.pressed.connect(_on_base_pressed)
	_language_button.pressed.connect(_on_language_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_chapter2_button.pressed.connect(_on_chapter2_pressed)
	_chapter3_button.pressed.connect(_on_chapter3_pressed)

	# 检查是否有存档
	continue_button.disabled = not SaveManager.has_save(1)
	_refresh_status_label()
	# AUDIO-P0-07: 主菜单 BGM
	_setup_bgm()
	if OS.get_cmdline_args().has("--srpg-playthrough-smoke"):
		call_deferred("_run_packaged_playthrough_smoke")

func _setup_bgm() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--srpg-playthrough-smoke"):
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

func _on_chapter3_pressed() -> void:
	var sd := SaveData.new()
	sd.battle_state = {
		"battle_definition_path": "res://src/ui/combat/battle_definitions/chapter_03_act_a.json"
	}
	sd.story_progress = {
		"chapter": 3,
		"current_battle": "chapter_03_act_a",
		"chapter_03_started": true,
		"chapter_03_intro_routed": true,
		"chapter_02_influence_applied": true,
		"b3_gate_placeholder": true,
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
		_status_label.text = _tr("main.settings_status")

func _on_language_pressed() -> void:
	var next_locale := SRPGLocalizationScript.ENGLISH_LOCALE
	if SRPGLocalizationScript.get_locale() == SRPGLocalizationScript.ENGLISH_LOCALE:
		next_locale = SRPGLocalizationScript.DEFAULT_LOCALE
	if SaveManager.save_locale_preference(next_locale):
		_refresh_locale_text()

func _on_credits_pressed() -> void:
	_set_credits_visible(true)

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

	_eyebrow_label = Label.new()
	SRPGTheme.apply_label(_eyebrow_label, SRPGTheme.GOLD, 15)
	title_stack.add_child(_eyebrow_label)

	_title_label = Label.new()
	SRPGTheme.apply_label(_title_label, SRPGTheme.WHITE, 56, true)
	title_stack.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_subtitle_label, SRPGTheme.PAPER, 20)
	title_stack.add_child(_subtitle_label)

	_seal_label = Label.new()
	_seal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_seal_label, SRPGTheme.PAPER_MUTED, 16)
	title_stack.add_child(_seal_label)

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

	SRPGTheme.apply_button(start_button, true)
	SRPGTheme.apply_button(continue_button)
	SRPGTheme.apply_button(base_button)
	SRPGTheme.apply_button(settings_button)
	SRPGTheme.apply_button(quit_button, false, true)

	_chapter2_button = Button.new()
	_chapter2_button.name = "Chapter2Button"
	SRPGTheme.apply_button(_chapter2_button)
	vbox.add_child(_chapter2_button)
	vbox.move_child(_chapter2_button, 1)

	_chapter3_button = Button.new()
	_chapter3_button.name = "Chapter3Button"
	SRPGTheme.apply_button(_chapter3_button)
	vbox.add_child(_chapter3_button)
	vbox.move_child(_chapter3_button, 2)

	_language_button = Button.new()
	_language_button.name = "LanguageButton"
	SRPGTheme.apply_button(_language_button)
	vbox.add_child(_language_button)
	vbox.move_child(_language_button, vbox.get_child_count() - 2)

	_credits_button = Button.new()
	_credits_button.name = "CreditsButton"
	SRPGTheme.apply_button(_credits_button)
	vbox.add_child(_credits_button)
	vbox.move_child(_credits_button, vbox.get_child_count() - 2)

	_status_label = Label.new()
	_status_label.name = "SaveStatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_status_label, SRPGTheme.PAPER_MUTED, 14)
	vbox.add_child(_status_label)

	# UI-P0-04: 底部按键提示条
	_hint_bar = HintBarScript.new()
	_hint_bar.name = "HintBar"
	add_child(_hint_bar)

	_build_credits_overlay()
	_refresh_locale_text()

func _refresh_locale_text() -> void:
	if _eyebrow_label != null:
		_eyebrow_label.text = _tr("main.eyebrow")
	if _title_label != null:
		_title_label.text = _tr("game.title")
	if _subtitle_label != null:
		_subtitle_label.text = _tr("main.subtitle")
	if _seal_label != null:
		_seal_label.text = _tr("main.seal")
	start_button.text = _tr("main.start_ch1")
	continue_button.text = _tr("main.continue")
	base_button.text = _tr("main.base")
	if _language_button != null:
		_language_button.text = _tr("main.language") % SRPGLocalizationScript.locale_label()
	if _credits_button != null:
		_credits_button.text = _tr("main.credits")
	settings_button.text = _tr("main.settings")
	quit_button.text = _tr("main.quit")
	if _chapter2_button != null:
		_chapter2_button.text = _tr("main.start_ch2")
	if _chapter3_button != null:
		_chapter3_button.text = _tr("main.start_ch3")
	if _hint_bar != null and _hint_bar.has_method("set_hints"):
		_hint_bar.set_hints([
			{"key": "↑↓",    "action": _tr("main.hint.select")},
			{"key": "Enter",  "action": _tr("main.hint.confirm")},
			{"key": "Esc",    "action": _tr("main.hint.exit")},
			{"key": "手柄A",  "action": _tr("main.hint.confirm")},
			{"key": "手柄B",  "action": _tr("main.hint.back")},
		])
	if _credits_title_label != null:
		_credits_title_label.text = _tr("credits.title")
	if _credits_body_label != null:
		_credits_body_label.text = get_credits_text()
	if _credits_close_button != null:
		_credits_close_button.text = _tr("credits.close")
	_refresh_status_label()

func _build_credits_overlay() -> void:
	_credits_layer = CanvasLayer.new()
	_credits_layer.name = "CreditsLayer"
	_credits_layer.layer = 30
	add_child(_credits_layer)

	var blocker := ColorRect.new()
	blocker.name = "CreditsBlocker"
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	_credits_layer.add_child(blocker)

	var panel := Panel.new()
	panel.name = "CreditsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 460)
	panel.position = Vector2(-320, -230)
	SRPGTheme.apply_panel(panel, Color(0.078, 0.068, 0.063, 0.98), SRPGTheme.GOLD)
	_credits_layer.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 18
	content.offset_top = 18
	content.offset_right = -18
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	_credits_title_label = Label.new()
	_credits_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label(_credits_title_label, SRPGTheme.WHITE, 26, true)
	content.add_child(_credits_title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	_credits_body_label = Label.new()
	_credits_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SRPGTheme.apply_label(_credits_body_label, SRPGTheme.PAPER, 15)
	scroll.add_child(_credits_body_label)

	_credits_close_button = Button.new()
	_credits_close_button.name = "CreditsCloseButton"
	_credits_close_button.pressed.connect(func() -> void:
		_set_credits_visible(false)
	)
	SRPGTheme.apply_button(_credits_close_button, false, true, true)
	content.add_child(_credits_close_button)
	_set_credits_visible(false)

func _set_credits_visible(is_visible: bool) -> void:
	if _credits_layer != null:
		_credits_layer.visible = is_visible
		if is_visible and _credits_close_button != null:
			_credits_close_button.grab_focus()

func get_credits_text() -> String:
	return "%s\n\n%s\n%s\n\n%s\n%s\n\n%s" % [
		_tr("credits.studio"),
		_tr("credits.music_heading"),
		_tr("credits.required_music"),
		_tr("credits.font_heading"),
		_tr("credits.fonts"),
		_tr("credits.special_thanks"),
	]

func _tr(key: String) -> String:
	return SRPGLocalizationScript.translate(key)

func _refresh_status_label() -> void:
	if _status_label == null:
		return
	if continue_button.disabled:
		_status_label.text = _tr("main.no_save")
		return
	var save_data: SaveData = SaveManager.peek_save(1)
	if save_data == null:
		_status_label.text = _tr("main.no_save")
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
		_status_label.text = _tr("main.save_status") % [chapter, save_time]
	else:
		_status_label.text = _tr("main.save_status_battle") % [chapter, battle_id, save_time]

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
	_smoke_defeat_current_enemies(battle)
	if not _smoke_has_bond_growth(battle):
		return {"success": false, "reason": "bond_growth_missing", "story": battle.get_story_progress()}
	if not SaveManager.save_game(6):
		return {"success": false, "reason": "pre_base_save_failed"}
	battle.queue_free()
	battle = null
	var base_result := _smoke_run_base_enhancement()
	if not bool(base_result.get("success", false)):
		return base_result
	if not SaveManager.load_game(6):
		return {"success": false, "reason": "post_base_load_failed"}
	battle = scene.instantiate()
	add_child(battle)
	if battle.get_battle_id() != "chapter_01_crossroads":
		return {"success": false, "reason": "failed_to_reach_crossroads_from_base", "battle": battle.get_battle_id()}
	if not _smoke_clear_and_advance(battle, "chapter_01_finale"):
		return {"success": false, "reason": "failed_to_reach_crossroads", "battle": battle.get_battle_id()}
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
		"bond_growth_present": _smoke_has_bond_growth(restored),
		"base_enhanced_level": int(base_result.get("enhancement_level", 0)),
	}
	restored.queue_free()
	if not restored_ok:
		_smoke_cleanup_save()
		return report
	var chapter3_result := _smoke_run_chapter_three_smoke(scene)
	for key in chapter3_result:
		report[key] = chapter3_result[key]
	report["success"] = restored_ok and bool(chapter3_result.get("success", false))
	_smoke_cleanup_save()
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

func _smoke_has_bond_growth(battle) -> bool:
	if battle == null:
		return false
	var progress: Dictionary = battle.get_story_progress()
	var bond_levels: Dictionary = progress.get("bond_levels", {})
	if bond_levels.is_empty():
		return false
	for pair_key in bond_levels:
		var pair: Dictionary = bond_levels[pair_key]
		if int(pair.get("affinity", 0)) > 0:
			return true
	return false

func _smoke_run_chapter_three_smoke(scene: PackedScene) -> Dictionary:
	var ch3: VSBattle = _smoke_start_battle_from_definition(scene, "res://src/ui/combat/battle_definitions/chapter_03_act_a.json", {
		"chapter": 3,
		"current_battle": "chapter_03_act_a",
		"chapter_03_intro_routed": true,
	})
	if ch3 == null:
		return {"success": false, "reason": "chapter3_instantiate_failed"}
	if ch3.get_battle_id() != "chapter_03_act_a":
		var wrong_battle: String = ch3.get_battle_id()
		ch3.queue_free()
		return {"success": false, "reason": "chapter3_wrong_battle", "chapter3_battle": wrong_battle}
	_smoke_defeat_current_enemies(ch3)
	if not SaveManager.save_game(6):
		ch3.queue_free()
		return {"success": false, "reason": "chapter3_victory_save_failed"}
	ch3.queue_free()
	var base_result := _smoke_run_chapter_three_base_loop()
	if not bool(base_result.get("success", false)):
		return base_result
	var saved_after_base := SaveManager.peek_save(6)
	if saved_after_base == null:
		return {"success": false, "reason": "chapter3_post_base_save_missing"}
	var act_b: VSBattle = _smoke_start_battle_from_definition(
		scene,
		"res://src/ui/combat/battle_definitions/chapter_03_act_b.json",
		saved_after_base.story_progress
	)
	if act_b == null or act_b.get_battle_id() != "chapter_03_act_b":
		var actual_battle := act_b.get_battle_id() if act_b != null else ""
		if act_b != null:
			act_b.queue_free()
		return {"success": false, "reason": "chapter3_act_b_start_failed", "battle": actual_battle}
	_smoke_defeat_current_enemies(act_b)
	var b3_gate: Dictionary = act_b.get_story_progress().get("b3_gate", {})
	if String(b3_gate.get("dominant_route", "")) == "":
		act_b.queue_free()
		return {"success": false, "reason": "chapter3_b3_gate_missing"}
	if not act_b.advance_to_next_battle():
		act_b.queue_free()
		return {"success": false, "reason": "chapter3_finale_advance_failed"}
	if act_b.get_battle_id() != "chapter_03_finale":
		var wrong_finale := act_b.get_battle_id()
		act_b.queue_free()
		return {"success": false, "reason": "chapter3_finale_wrong_battle", "battle": wrong_finale}
	var boss_phase_result := _smoke_trigger_finale_boss_phases(act_b)
	if not bool(boss_phase_result.get("success", false)):
		act_b.queue_free()
		return boss_phase_result
	_smoke_defeat_current_enemies(act_b)
	var final_progress: Dictionary = act_b.get_story_progress()
	var finale_variant: Dictionary = act_b.get_chapter3_finale_variant_state()
	act_b.queue_free()
	return {
		"success": true,
		"chapter3_battle": "chapter_03_act_a",
		"chapter3_victory": true,
		"chapter3_act_b": true,
		"b3_gate_route": String(b3_gate.get("dominant_route", "")),
		"chapter3_finale": true,
		"finale_variant": String(finale_variant.get("variant_id", "")),
		"finale_boss_phase": int(boss_phase_result.get("boss_phase", 0)),
		"chapter3_complete": bool(final_progress.get("chapter_03_complete", false)),
		"tavern_affinity": int(base_result.get("tavern_affinity", 0)),
		"chapter3_base_level": int(base_result.get("base_level", 0)),
		"risk_enhanced_level": int(base_result.get("risk_enhanced_level", 0)),
		"decompose_materials": int(base_result.get("decompose_materials", 0)),
		"reroll_preserved_level": int(base_result.get("reroll_preserved_level", 0)),
	}

func _smoke_start_battle_from_definition(scene: PackedScene, path: String, story_progress: Dictionary) -> VSBattle:
	SaveManager.clear_pending_loaded_data()
	var sd := SaveData.new()
	sd.battle_state = {
		"battle_definition_path": path,
	}
	sd.story_progress = story_progress.duplicate(true)
	SaveManager._pending_loaded_data = sd
	var battle := scene.instantiate() as VSBattle
	add_child(battle)
	return battle

func _smoke_run_chapter_three_base_loop() -> Dictionary:
	var base_scene: PackedScene = load(BASE_SCENE_PATH)
	if base_scene == null:
		return {"success": false, "reason": "missing_base_scene"}
	var base = base_scene.instantiate()
	add_child(base)
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 10000)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 1000)
	Inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 5)
	var upgrade_result: Dictionary = base.upgrade_base()
	if not bool(upgrade_result.get("success", false)):
		base.queue_free()
		return {"success": false, "reason": "chapter3_base_upgrade_failed", "upgrade": upgrade_result}
	var tavern_result: Dictionary = base.trigger_tavern_conversation("P1_P2_ch3_tavern_001")
	if not bool(tavern_result.get("success", false)):
		base.queue_free()
		return {"success": false, "reason": "chapter3_tavern_failed", "tavern": tavern_result}
	var risk_result := _smoke_run_risk_enhancement_to_plus_seven(base)
	if not bool(risk_result.get("success", false)):
		base.queue_free()
		return risk_result
	var decomp_reroll_result := _smoke_run_decomp_reroll(base)
	if not bool(decomp_reroll_result.get("success", false)):
		base.queue_free()
		return decomp_reroll_result
	if not SaveManager.save_game(6):
		base.queue_free()
		return {"success": false, "reason": "chapter3_base_save_failed"}
	base.queue_free()
	return {
		"success": true,
		"base_level": 2,
		"tavern_affinity": int(tavern_result.get("new_affinity", 20)),
		"risk_enhanced_level": int(risk_result.get("risk_enhanced_level", 0)),
		"decompose_materials": int(decomp_reroll_result.get("decompose_materials", 0)),
		"reroll_preserved_level": int(decomp_reroll_result.get("reroll_preserved_level", 0)),
	}

func _smoke_run_decomp_reroll(base) -> Dictionary:
	var character_screen = base._character_screen
	var roster: CharacterRoster = base._roster
	if character_screen == null or roster == null or roster.get_party().is_empty():
		return {"success": false, "reason": "chapter3_decomp_reroll_management_missing"}
	var unit: Unit = roster.get_character(StringName(roster.get_party()[0]))
	if unit == null:
		return {"success": false, "reason": "chapter3_decomp_reroll_unit_missing"}
	var item := _smoke_first_equipped_item(unit)
	if item == null:
		return {"success": false, "reason": "chapter3_reroll_item_missing"}
	var starting_level := item.enhancement_level
	character_screen._reroll_rng_seed = 202608
	character_screen.call("_on_roster_item_selected", unit.unit_id)
	character_screen.call("_on_reroll_item_pressed", unit.unit_id, item.item_id, item.slot)
	if item.enhancement_level != starting_level:
		return {"success": false, "reason": "chapter3_reroll_changed_enhancement", "level": item.enhancement_level}
	var spare := EquipmentItem.new({
		"item_id": "smoke_spare_decompose",
		"name": "Smoke Spare Blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"affixes": [EquipmentAffixGenerator.generate_affix(EquipmentDefinitions.Quality.BLUE, EquipmentDefinitions.AffixType.STR, 19)],
	})
	unit.equipment_component.add_item(spare)
	var before_materials := Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	character_screen._decompose_rng_seed = 1
	character_screen.call("_on_decompose_item_pressed", unit.unit_id, spare.item_id, spare.slot)
	if unit.equipment_component.get_item(spare.item_id) != null:
		return {"success": false, "reason": "chapter3_decompose_item_remaining"}
	var material_gain := Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL) - before_materials
	if material_gain <= 0:
		return {"success": false, "reason": "chapter3_decompose_no_material_gain"}
	return {"success": true, "decompose_materials": material_gain, "reroll_preserved_level": item.enhancement_level}

func _smoke_run_risk_enhancement_to_plus_seven(base) -> Dictionary:
	var character_screen = base._character_screen
	var roster: CharacterRoster = base._roster
	if character_screen == null or roster == null or roster.get_party().is_empty():
		return {"success": false, "reason": "chapter3_management_missing"}
	var unit: Unit = roster.get_character(StringName(roster.get_party()[0]))
	var item := _smoke_first_equipped_item(unit)
	if unit == null or item == null:
		return {"success": false, "reason": "chapter3_risk_item_missing"}
	while item.enhancement_level < 7:
		var seed := _smoke_find_seed_for_enhancement_result(unit, item, "success", true)
		if seed <= 0:
			return {"success": false, "reason": "chapter3_risk_seed_missing", "level": item.enhancement_level}
		character_screen._enhancement_rng_seed = seed
		character_screen.call("_on_roster_item_selected", unit.unit_id)
		var enhance_btn := _smoke_find_enhance_button(character_screen)
		if enhance_btn == null or enhance_btn.disabled:
			return {"success": false, "reason": "chapter3_risk_button_unavailable", "level": item.enhancement_level}
		enhance_btn.pressed.emit()
		item = _smoke_first_equipped_item(unit)
		if item == null:
			return {"success": false, "reason": "chapter3_risk_item_lost"}
	return {"success": true, "risk_enhanced_level": item.enhancement_level}

func _smoke_find_seed_for_enhancement_result(unit: Unit, item: EquipmentItem, expected_result: String, use_protection: bool) -> int:
	var starting_level := item.enhancement_level
	var inventory_snapshot := Inventory.serialize()
	for seed in range(1, 500):
		item.enhancement_level = starting_level
		Inventory.deserialize(inventory_snapshot)
		var result: Dictionary = unit.equipment_component.attempt_enhancement(item.item_id, Inventory, use_protection, seed)
		if String(result.get("result", "")) == expected_result:
			item.enhancement_level = starting_level
			Inventory.deserialize(inventory_snapshot)
			return seed
	item.enhancement_level = starting_level
	Inventory.deserialize(inventory_snapshot)
	return -1

func _smoke_trigger_finale_boss_phases(battle: VSBattle) -> Dictionary:
	var boss := _smoke_find_unit(battle, "BOSS_YAN")
	var actor: Unit = battle._combat.get_current_actor()
	if boss == null or actor == null:
		return {"success": false, "reason": "chapter3_finale_boss_missing"}
	battle._combat.apply_damage(boss, 80, actor)
	if int(battle.get_boss_state().get("phase", 0)) < 2:
		return {"success": false, "reason": "chapter3_finale_phase2_missing", "state": battle.get_boss_state()}
	battle._combat.apply_damage(boss, 40, actor)
	var phase := int(battle.get_boss_state().get("phase", 0))
	if phase < 3:
		return {"success": false, "reason": "chapter3_finale_phase3_missing", "state": battle.get_boss_state()}
	return {"success": true, "boss_phase": phase}

func _smoke_find_unit(battle: VSBattle, unit_id: String) -> Unit:
	for unit in battle._unit_cells.keys():
		if String(unit.unit_id) == unit_id:
			return unit
	return null

func _smoke_cleanup_save() -> void:
	var save_path := "user://saves/save_6.tres"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func _smoke_run_base_enhancement() -> Dictionary:
	var base_scene: PackedScene = load(BASE_SCENE_PATH)
	if base_scene == null:
		return {"success": false, "reason": "missing_base_scene"}
	var base = base_scene.instantiate()
	add_child(base)
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	var character_screen = base._character_screen
	if character_screen == null:
		base.queue_free()
		return {"success": false, "reason": "base_character_screen_missing"}
	var roster: CharacterRoster = base._roster
	if roster == null or roster.get_party().is_empty():
		base.queue_free()
		return {"success": false, "reason": "base_roster_missing"}
	var unit: Unit = roster.get_character(StringName(roster.get_party()[0]))
	var item := _smoke_first_equipped_item(unit)
	if unit == null or item == null:
		base.queue_free()
		return {"success": false, "reason": "base_equipped_item_missing"}
	for _i in range(5):
		character_screen.call("_on_roster_item_selected", unit.unit_id)
		var enhance_btn := _smoke_find_enhance_button(character_screen)
		if enhance_btn == null or enhance_btn.disabled:
			base.queue_free()
			return {
				"success": false,
				"reason": "base_enhance_button_unavailable",
				"level": item.enhancement_level,
			}
		enhance_btn.pressed.emit()
	item = _smoke_first_equipped_item(unit)
	if item == null or item.enhancement_level != 5:
		base.queue_free()
		return {"success": false, "reason": "base_enhance_not_plus_five", "level": item.enhancement_level if item != null else -1}
	base._advance_after_base_requested = true
	if not SaveManager.save_game(6):
		base.queue_free()
		return {"success": false, "reason": "base_save_failed"}
	base.queue_free()
	return {"success": true, "enhancement_level": item.enhancement_level}

func _smoke_first_equipped_item(unit: Unit) -> EquipmentItem:
	if unit == null or unit.equipment_component == null:
		return null
	for slot in unit.equipment_component.get_loadout():
		var item: EquipmentItem = unit.equipment_component.get_equipped_item(slot)
		if item != null:
			return item
	return null

func _smoke_find_enhance_button(node: Node) -> Button:
	if node is Button and (node as Button).text == _tr("management.enhance"):
		return node as Button
	for child in node.get_children():
		var found := _smoke_find_enhance_button(child)
		if found != null:
			return found
	return null
