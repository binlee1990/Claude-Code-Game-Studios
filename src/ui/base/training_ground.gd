class_name TrainingGround
extends Control

## Training Ground MVP - displays character skill proficiency
## BASE-002: Players can view character skill proficiency

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")

signal closed()

var _roster_data: Array = []
var _selected_unit_index: int = -1

# UI references
var _character_list: VBoxContainer
var _skill_detail_container: VBoxContainer
var _detail_name_label: Label
var _detail_class_label: Label
var _skill_list: VBoxContainer
var _hint_bar: Control

func _ready() -> void:
	_build_ui()
	_load_data()
	_refresh()

func _build_ui() -> void:
	# Main layout: left panel (character list) + right panel (skill detail)
	var hbox := HBoxContainer.new()
	hbox.name = "MainHBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	add_child(hbox)

	# Left panel: character list (scrollable)
	var left_panel := _create_character_panel(hbox)
	hbox.add_child(left_panel)

	# Right panel: skill detail
	var right_panel := _create_skill_detail_panel(hbox)
	hbox.add_child(right_panel)

	# Bottom hint bar
	_build_hint_bar()

func _create_character_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.name = "CharacterPanel"
	panel.custom_minimum_size = Vector2(320.0, 0.0)
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_top = 12
	vbox.offset_right = -12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "角色列表"
	SRPGTheme.apply_label(title, SRPGTheme.GOLD, 18, true)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300.0, 400.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_character_list = VBoxContainer.new()
	_character_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_character_list)

	return panel

func _create_skill_detail_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.name = "SkillDetailPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.GOLD)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_top = 12
	vbox.offset_right = -12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "技能熟练度"
	SRPGTheme.apply_label(title, SRPGTheme.GOLD, 18, true)
	vbox.add_child(title)

	# Character info row
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	vbox.add_child(info_row)

	_detail_name_label = Label.new()
	_detail_name_label.text = "选择角色"
	SRPGTheme.apply_label(_detail_name_label, SRPGTheme.WHITE, 18, true)
	info_row.add_child(_detail_name_label)

	_detail_class_label = Label.new()
	_detail_class_label.text = ""
	SRPGTheme.apply_label(_detail_class_label, SRPGTheme.GOLD, 14)
	info_row.add_child(_detail_class_label)

	# Skill list
	_skill_detail_container = vbox
	_skill_list = VBoxContainer.new()
	_skill_list.add_theme_constant_override("separation", 8)
	vbox.add_child(_skill_list)

	# Empty state placeholder
	var empty_label := Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.text = "点击左侧角色查看技能熟练度"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label(empty_label, SRPGTheme.PAPER_MUTED, 14)
	_skill_list.add_child(empty_label)

	return panel

func _build_hint_bar() -> void:
	var bar := Panel.new()
	bar.name = "HintBar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = 510
	bar.custom_minimum_size = Vector2(960, 30)
	SRPGTheme.apply_panel(bar, Color(0.04, 0.04, 0.04, 0.95), SRPGTheme.GOLD)
	add_child(bar)

	var hint_label := Label.new()
	hint_label.text = "点击角色查看其技能熟练度 | Esc 返回"
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label(hint_label, SRPGTheme.PAPER_MUTED, 12)
	bar.add_child(hint_label)

func _load_data() -> void:
	_roster_data.clear()
	var save_data: SaveData = SaveManager.peek_save(1)
	if save_data == null:
		return
	for unit_data in save_data.party_units:
		_roster_data.append(unit_data)

func _refresh() -> void:
	_refresh_character_list()
	_refresh_skill_detail()

func _refresh_character_list() -> void:
	for child in _character_list.get_children():
		child.queue_free()

	for i in range(_roster_data.size()):
		var unit_data: Dictionary = _roster_data[i]
		var btn := _create_character_button(unit_data, i)
		_character_list.add_child(btn)

func _create_character_button(unit_data: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280.0, 56.0)
	btn.focus_mode = Control.FOCUS_ALL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = unit_data.get("display_name", "Unknown")
	name_lbl.custom_minimum_size = Vector2(90.0, 0.0)
	SRPGTheme.apply_label(name_lbl, SRPGTheme.PAPER, 14)
	hbox.add_child(name_lbl)

	var class_id: int = -1
	if "class" in unit_data:
		class_id = unit_data["class"].get("class_id", -1)
	var class_name_str: String = ClassNames.ClassID.keys()[class_id] if class_id >= 0 else "Unknown"
	var class_lbl := Label.new()
	class_lbl.text = class_name_str
	SRPGTheme.apply_label(class_lbl, SRPGTheme.GOLD, 12)
	hbox.add_child(class_lbl)

	btn.pressed.connect(_on_character_selected.bind(index))
	return btn

func _refresh_skill_detail() -> void:
	for child in _skill_list.get_children():
		child.queue_free()

	if _selected_unit_index < 0 or _selected_unit_index >= _roster_data.size():
		var empty_label := Label.new()
		empty_label.text = "点击左侧角色查看技能熟练度"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		SRPGTheme.apply_label(empty_label, SRPGTheme.PAPER_MUTED, 14)
		_skill_list.add_child(empty_label)
		return

	var unit_data: Dictionary = _roster_data[_selected_unit_index]
	_detail_name_label.text = unit_data.get("display_name", "Unknown")

	var class_id: int = -1
	if "class" in unit_data:
		class_id = unit_data["class"].get("class_id", -1)
	_detail_class_label.text = ClassNames.ClassID.keys()[class_id] if class_id >= 0 else ""

	var skills_data: Dictionary = unit_data.get("skills", {})
	for skill_id_str in skills_data:
		var skill_entry: Dictionary = skills_data[skill_id_str]
		_add_skill_row(skill_entry)

func _add_skill_row(skill_data: Dictionary) -> void:
	var skill_name: String = skill_data.get("name", "Unknown Skill")
	var level: int = skill_data.get("level", 1)
	var proficiency: int = skill_data.get("proficiency", 0)
	var max_proficiency: int = skill_data.get("max_proficiency", 100)
	var rank: int = skill_data.get("rank", 0)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	_skill_list.add_child(container)

	# Skill name + level row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	container.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = skill_name
	SRPGTheme.apply_label(name_lbl, SRPGTheme.WHITE, 14, true)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var level_lbl := Label.new()
	level_lbl.text = "Lv.%d" % level
	SRPGTheme.apply_label(level_lbl, SRPGTheme.JADE, 14)
	name_row.add_child(level_lbl)

	# Proficiency bar
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	container.add_child(bar_row)

	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(400.0, 16.0)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(bar_bg, Color(0.15, 0.15, 0.15, 0.8), SRPGTheme.PAPER_MUTED)
	bar_row.add_child(bar_bg)

	var fill_ratio: float = clampf(float(proficiency) / float(max_proficiency) if max_proficiency > 0 else 0.0, 0.0, 1.0)
	var bar_fill := ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(400.0 * fill_ratio, 14.0)
	bar_fill.color = SRPGTheme.JADE
	bar_fill.anchor_right = 1.0
	bar_fill.offset_right = -2.0
	bar_fill.offset_top = 1.0
	bar_fill.offset_bottom = -1.0
	bar_bg.add_child(bar_fill)

	var prof_lbl := Label.new()
	prof_lbl.text = "%d / %d" % [proficiency, max_proficiency]
	SRPGTheme.apply_label(prof_lbl, SRPGTheme.PAPER_MUTED, 12)
	bar_lbl_container_add(bar_row, prof_lbl)

	# Rank info
	var rank_lbl := Label.new()
	var rank_str: String = SkillDefinitions.Rank.keys()[rank] if rank < SkillDefinitions.Rank.size() else "UNKNOWN"
	rank_lbl.text = "Rank: %s" % rank_str
	SRPGTheme.apply_label(rank_lbl, SRPGTheme.GOLD, 12)
	container.add_child(rank_lbl)

func bar_lbl_container_add(bar_row: HBoxContainer, lbl: Label) -> void:
	bar_row.add_child(lbl)

func _on_character_selected(index: int) -> void:
	_selected_unit_index = index
	_refresh_skill_detail()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			closed.emit()
			get_viewport().set_input_as_handled()
