class_name TrainingGround
extends Control

## Training Ground MVP - displays character skill proficiency
## BASE-002: Players can view character skill proficiency

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")

signal closed()
signal training_changed(unit_id: StringName, skill_id: StringName, result: Dictionary)

var _roster: CharacterRoster = null
var _roster_data: Array = []
var _unit_order: Array[StringName] = []
var _selected_unit_index: int = -1

# UI references
var _character_list: VBoxContainer
var _skill_detail_container: VBoxContainer
var _detail_name_label: Label
var _detail_class_label: Label
var _skill_list: VBoxContainer
var _hint_bar: Control
var _ui_scale: float = 1.0

func _ready() -> void:
	_build_ui()
	_load_data()
	_refresh()

func initialize(roster: CharacterRoster) -> void:
	_roster = roster
	_roster_data.clear()
	_selected_unit_index = -1
	if _character_list != null:
		_refresh()

func set_ui_scale(scale: float) -> void:
	_ui_scale = clampf(scale, 1.0, 1.3)
	if _character_list != null:
		_rebuild_ui()

func _scaled(value: float) -> float:
	return SRPGTheme.scale_size(value, _ui_scale)

func _scaled_vec2(width: float, height: float) -> Vector2:
	return Vector2(_scaled(width), _scaled(height))

func _rebuild_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_character_list = null
	_skill_detail_container = null
	_detail_name_label = null
	_detail_class_label = null
	_skill_list = null
	_hint_bar = null
	_build_ui()
	_refresh()

func _build_ui() -> void:
	# Main layout: left panel (character list) + right panel (skill detail)
	var hbox := HBoxContainer.new()
	hbox.name = "MainHBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_bottom = -_scaled(38.0)
	hbox.add_theme_constant_override("separation", int(_scaled(16.0)))
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
	panel.custom_minimum_size = Vector2(_scaled(380.0), 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.25
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.JADE)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(12.0)
	vbox.offset_top = _scaled(12.0)
	vbox.offset_right = -_scaled(12.0)
	vbox.offset_bottom = -_scaled(12.0)
	vbox.add_theme_constant_override("separation", int(_scaled(8.0)))
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "角色列表"
	SRPGTheme.apply_label_scaled(title, _ui_scale, SRPGTheme.GOLD, 18, true)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = _scaled_vec2(340.0, 400.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_character_list = VBoxContainer.new()
	_character_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_character_list)

	return panel

func _create_skill_detail_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.name = "SkillDetailPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.75
	SRPGTheme.apply_panel(panel, SRPGTheme.INK_PANEL, SRPGTheme.GOLD)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _scaled(12.0)
	vbox.offset_top = _scaled(12.0)
	vbox.offset_right = -_scaled(12.0)
	vbox.offset_bottom = -_scaled(12.0)
	vbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "技能熟练度"
	SRPGTheme.apply_label_scaled(title, _ui_scale, SRPGTheme.GOLD, 18, true)
	vbox.add_child(title)

	# Character info row
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", int(_scaled(16.0)))
	vbox.add_child(info_row)

	_detail_name_label = Label.new()
	_detail_name_label.text = "选择角色"
	SRPGTheme.apply_label_scaled(_detail_name_label, _ui_scale, SRPGTheme.WHITE, 18, true)
	info_row.add_child(_detail_name_label)

	_detail_class_label = Label.new()
	_detail_class_label.text = ""
	SRPGTheme.apply_label_scaled(_detail_class_label, _ui_scale, SRPGTheme.GOLD, 14)
	info_row.add_child(_detail_class_label)

	# Skill list
	_skill_detail_container = vbox
	_skill_list = VBoxContainer.new()
	_skill_list.add_theme_constant_override("separation", int(_scaled(8.0)))
	_skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_skill_list)

	# Empty state placeholder
	var empty_label := Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.text = "点击左侧角色查看技能熟练度"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_label_scaled(empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
	_skill_list.add_child(empty_label)

	return panel

func _build_hint_bar() -> void:
	var bar := Panel.new()
	bar.name = "HintBar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -_scaled(30.0)
	bar.offset_bottom = 0
	bar.custom_minimum_size = Vector2(0, _scaled(30.0))
	SRPGTheme.apply_panel(bar, Color(0.04, 0.04, 0.04, 0.95), SRPGTheme.GOLD)
	add_child(bar)

	var hint_label := Label.new()
	hint_label.text = "点击角色查看其技能熟练度 | 训练按钮提升熟练度 | Esc 返回"
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SRPGTheme.apply_label_scaled(hint_label, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
	bar.add_child(hint_label)

func _load_data() -> void:
	if _roster != null:
		return
	_roster_data.clear()
	var save_data: SaveData = SaveManager.peek_save(_get_save_slot())
	if save_data == null:
		return
	for entry in save_data.party_units:
		var unit_data: Dictionary = entry.get("unit", {})
		if unit_data.is_empty():
			continue
		_roster_data.append(unit_data)

func _refresh() -> void:
	_refresh_character_list()
	_refresh_skill_detail()

func _refresh_character_list() -> void:
	for child in _character_list.get_children():
		child.queue_free()

	if _roster != null:
		_unit_order = _get_ordered_roster_unit_ids()
		for i in range(_unit_order.size()):
			var unit: Unit = _roster.get_character(_unit_order[i])
			if unit == null:
				continue
			var btn := _create_character_button_for_unit(unit, i)
			_character_list.add_child(btn)
		return

	for i in range(_roster_data.size()):
		var unit_data: Dictionary = _roster_data[i]
		var btn := _create_character_button(unit_data, i)
		_character_list.add_child(btn)

func _get_ordered_roster_unit_ids() -> Array[StringName]:
	var ordered: Array[StringName] = []
	if _roster == null:
		return ordered

	var deployable: Array = _roster.get_deployable_ids()
	var deployable_lookup: Dictionary = {}
	for unit_id_variant in deployable:
		deployable_lookup[StringName(unit_id_variant)] = true

	for unit_id_variant in _roster.get_party():
		var unit_id := StringName(unit_id_variant)
		if deployable_lookup.has(unit_id) and not ordered.has(unit_id):
			ordered.append(unit_id)

	for unit_id_variant in deployable:
		var unit_id := StringName(unit_id_variant)
		if not ordered.has(unit_id):
			ordered.append(unit_id)

	return ordered

func _create_character_button_for_unit(unit: Unit, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = _scaled_vec2(340.0, 64.0)
	btn.focus_mode = Control.FOCUS_ALL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	btn.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = unit.display_name
	name_lbl.custom_minimum_size = Vector2(_scaled(120.0), 0.0)
	SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.PAPER, 14)
	hbox.add_child(name_lbl)

	var class_lbl := Label.new()
	class_lbl.text = _get_class_name(unit.class_component.get_class_id())
	SRPGTheme.apply_label_scaled(class_lbl, _ui_scale, SRPGTheme.GOLD, 12)
	hbox.add_child(class_lbl)

	btn.pressed.connect(_on_character_selected.bind(index))
	return btn

func _create_character_button(unit_data: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = _scaled_vec2(340.0, 64.0)
	btn.focus_mode = Control.FOCUS_ALL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(_scaled(12.0)))
	btn.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = unit_data.get("display_name", "Unknown")
	name_lbl.custom_minimum_size = Vector2(_scaled(120.0), 0.0)
	SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.PAPER, 14)
	hbox.add_child(name_lbl)

	var class_lbl := Label.new()
	class_lbl.text = _get_class_name(_get_class_id_from_unit_data(unit_data))
	SRPGTheme.apply_label_scaled(class_lbl, _ui_scale, SRPGTheme.GOLD, 12)
	hbox.add_child(class_lbl)

	btn.pressed.connect(_on_character_selected.bind(index))
	return btn

func _refresh_skill_detail() -> void:
	for child in _skill_list.get_children():
		child.queue_free()

	if _selected_unit_index < 0 or _selected_unit_index >= _roster_data.size():
		if _roster != null and _selected_unit_index >= 0 and _selected_unit_index < _unit_order.size():
			_refresh_roster_skill_detail()
			return
		var empty_label := Label.new()
		empty_label.text = "点击左侧角色查看技能熟练度"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		SRPGTheme.apply_label_scaled(empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
		_skill_list.add_child(empty_label)
		return

	var unit_data: Dictionary = _roster_data[_selected_unit_index]
	_detail_name_label.text = unit_data.get("display_name", "Unknown")

	_detail_class_label.text = _get_class_name(_get_class_id_from_unit_data(unit_data))

	var skills_data: Dictionary = unit_data.get("skills", {})
	for skill_id_str in skills_data:
		var skill_entry: Dictionary = (skills_data[skill_id_str] as Dictionary).duplicate(true)
		if not skill_entry.has("skill_id"):
			skill_entry["skill_id"] = skill_id_str
		_add_skill_row(skill_entry)

func _refresh_roster_skill_detail() -> void:
	var unit := _get_selected_unit()
	if unit == null:
		return
	_detail_name_label.text = unit.display_name
	_detail_class_label.text = _get_class_name(unit.class_component.get_class_id())

	var skills: Array = unit.skill_component.get_all_skills()
	if skills.is_empty():
		var empty_label := Label.new()
		empty_label.text = "该角色尚未学习技能"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		SRPGTheme.apply_label_scaled(empty_label, _ui_scale, SRPGTheme.PAPER_MUTED, 14)
		_skill_list.add_child(empty_label)
		return

	for skill in skills:
		if skill is SkillData:
			_add_skill_row((skill as SkillData).serialize())

func _add_skill_row(skill_data: Dictionary) -> void:
	var skill_name: String = skill_data.get("name", "Unknown Skill")
	var skill_id := StringName(skill_data.get("skill_id", ""))
	var level: int = skill_data.get("level", 1)
	var proficiency: int = skill_data.get("proficiency", 0)
	var max_proficiency: int = skill_data.get("max_proficiency", 100)
	var rank: int = skill_data.get("rank", 0)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", int(_scaled(4.0)))
	_skill_list.add_child(container)

	# Skill name + level row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", int(_scaled(8.0)))
	container.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = skill_name
	SRPGTheme.apply_label_scaled(name_lbl, _ui_scale, SRPGTheme.WHITE, 14, true)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var level_lbl := Label.new()
	level_lbl.text = "Lv.%d" % level
	SRPGTheme.apply_label_scaled(level_lbl, _ui_scale, SRPGTheme.JADE, 14)
	name_row.add_child(level_lbl)

	var train_btn := Button.new()
	train_btn.name = "TrainButton_%s" % String(skill_id)
	train_btn.text = "训练 +10"
	train_btn.disabled = _roster == null or skill_id == &""
	train_btn.focus_mode = Control.FOCUS_ALL
	train_btn.pressed.connect(_on_train_skill_pressed.bind(skill_id))
	SRPGTheme.apply_button_scaled(train_btn, _ui_scale, false, false, true)
	name_row.add_child(train_btn)

	# Proficiency bar
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", int(_scaled(8.0)))
	container.add_child(bar_row)

	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = _scaled_vec2(520.0, 16.0)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SRPGTheme.apply_panel(bar_bg, Color(0.15, 0.15, 0.15, 0.8), SRPGTheme.PAPER_MUTED)
	bar_row.add_child(bar_bg)

	var fill_ratio: float = clampf(float(proficiency) / float(max_proficiency) if max_proficiency > 0 else 0.0, 0.0, 1.0)
	var bar_fill := ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(_scaled(520.0) * fill_ratio, _scaled(14.0))
	bar_fill.color = SRPGTheme.JADE
	bar_fill.anchor_right = 1.0
	bar_fill.offset_right = -_scaled(2.0)
	bar_fill.offset_top = _scaled(1.0)
	bar_fill.offset_bottom = -_scaled(1.0)
	bar_bg.add_child(bar_fill)

	var prof_lbl := Label.new()
	prof_lbl.text = "%d / %d" % [proficiency, max_proficiency]
	SRPGTheme.apply_label_scaled(prof_lbl, _ui_scale, SRPGTheme.PAPER_MUTED, 12)
	bar_lbl_container_add(bar_row, prof_lbl)

	# Rank info
	var rank_lbl := Label.new()
	var rank_str: String = SkillDefinitions.Rank.keys()[rank] if rank < SkillDefinitions.Rank.size() else "UNKNOWN"
	rank_lbl.text = "Rank: %s" % rank_str
	SRPGTheme.apply_label_scaled(rank_lbl, _ui_scale, SRPGTheme.GOLD, 12)
	container.add_child(rank_lbl)

func bar_lbl_container_add(bar_row: HBoxContainer, lbl: Label) -> void:
	bar_row.add_child(lbl)

func _get_selected_unit() -> Unit:
	if _roster == null:
		return null
	if _selected_unit_index < 0 or _selected_unit_index >= _unit_order.size():
		return null
	return _roster.get_character(_unit_order[_selected_unit_index])

func _get_class_id_from_unit_data(unit_data: Dictionary) -> int:
	var class_data: Dictionary = unit_data.get("class", {})
	return int(class_data.get("current_class", class_data.get("class_id", -1)))

func _get_class_name(class_id: int) -> String:
	var class_names: Array = ClassNames.ClassID.keys()
	if class_id < 0 or class_id >= class_names.size():
		return "Unknown"
	return class_names[class_id]

func _get_save_slot() -> int:
	var current_slot := SaveManager.get_current_slot()
	if current_slot >= 0:
		return current_slot
	return 1

func _on_character_selected(index: int) -> void:
	_selected_unit_index = index
	_refresh_skill_detail()

func _on_train_skill_pressed(skill_id: StringName) -> void:
	var unit := _get_selected_unit()
	if unit == null or unit.skill_component == null:
		return
	var result: Dictionary = unit.skill_component.apply_battle_proficiency(skill_id, 10)
	training_changed.emit(unit.unit_id, skill_id, result)
	_refresh_skill_detail()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			closed.emit()
			get_viewport().set_input_as_handled()
