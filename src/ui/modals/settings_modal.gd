class_name SettingsModal
extends BaseModal

var _ui_scale_value_label: Label = null
var _ui_scale_slider: HSlider = null
var _resolution_option: OptionButton = null
var _pending_resolution_index := 1
var _pending_ui_scale := UIScaleSettings.DEFAULT_UI_SCALE


func _ready() -> void:
	super._ready()
	_build_content()


func _build_content() -> void:
	var vbox := _content_vbox()
	if vbox == null:
		return
	for child in vbox.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = tr("设置")
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_pending_resolution_index = _current_resolution_index()
	_pending_ui_scale = _current_ui_scale()

	vbox.add_child(_make_slider_row(tr("主音量"), 0.8))
	vbox.add_child(_make_resolution_row())
	vbox.add_child(_make_ui_scale_row())
	vbox.add_child(_make_options_row(tr("语言"), ["简体中文"], 0))
	vbox.add_child(_make_options_row(tr("数字格式"), [tr("中文单位"), tr("科学计数"), tr("完整数字")], 0))
	vbox.add_child(_make_check_row(tr("Reduce motion"), false))
	vbox.add_child(_make_check_row(tr("离线收益弹窗确认"), true))

	vbox.add_child(_make_action_row())


func _make_slider_row(label_text: String, value: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return row


func _make_resolution_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = tr("分辨率")
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	_resolution_option = OptionButton.new()
	_resolution_option.name = "ResolutionOption"
	_resolution_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(UIScaleSettings.SUPPORTED_RESOLUTIONS.size()):
		var resolution: Vector2i = UIScaleSettings.SUPPORTED_RESOLUTIONS[i]
		_resolution_option.add_item("%d×%d" % [resolution.x, resolution.y], i)
	_resolution_option.select(_pending_resolution_index)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	row.add_child(_resolution_option)
	return row


func _make_ui_scale_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = tr("UI 缩放")
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	_ui_scale_slider = HSlider.new()
	_ui_scale_slider.name = "UIScaleSlider"
	_ui_scale_slider.min_value = UIScaleSettings.MIN_UI_SCALE
	_ui_scale_slider.max_value = UIScaleSettings.MAX_UI_SCALE
	_ui_scale_slider.step = UIScaleSettings.UI_SCALE_STEP
	_ui_scale_slider.value = _pending_ui_scale
	_ui_scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	row.add_child(_ui_scale_slider)

	_ui_scale_value_label = Label.new()
	_ui_scale_value_label.name = "UIScaleValueLabel"
	_ui_scale_value_label.custom_minimum_size = Vector2(56, 0)
	_ui_scale_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_ui_scale_value_label)

	_update_ui_scale_value_label(_ui_scale_slider.value)
	return row


func _make_options_row(label_text: String, options: Array, selected: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(options.size()):
		option.add_item(str(options[i]), i)
	option.selected = selected
	row.add_child(option)
	return row


func _make_check_row(label_text: String, pressed: bool) -> Control:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = pressed
	return check


func _make_action_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var apply_btn := Button.new()
	apply_btn.name = "ApplySettingsButton"
	apply_btn.text = tr("应用")
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.pressed.connect(_apply_pending_settings)
	row.add_child(apply_btn)

	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmSettingsButton"
	confirm_btn.text = tr("确认")
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.pressed.connect(_confirm_settings)
	row.add_child(confirm_btn)

	var close_btn := Button.new()
	close_btn.name = "CloseSettingsButton"
	close_btn.text = tr("关闭")
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(_close_modal)
	row.add_child(close_btn)
	return row


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= UIScaleSettings.SUPPORTED_RESOLUTIONS.size():
		return
	_pending_resolution_index = index
	if _resolution_option != null:
		_resolution_option.select(_pending_resolution_index)


func _on_ui_scale_changed(value: float) -> void:
	_pending_ui_scale = _normalize_ui_scale(value)
	_update_ui_scale_value_label(_pending_ui_scale)


func _current_ui_scale() -> float:
	var settings := UIScaleSettings.get_instance()
	if settings == null:
		return UIScaleSettings.DEFAULT_UI_SCALE
	return settings.get_ui_scale_multiplier()


func _current_resolution_index() -> int:
	var settings := UIScaleSettings.get_instance()
	if settings == null:
		return 1
	return settings.get_resolution_index()


func _apply_pending_settings() -> void:
	var settings := UIScaleSettings.get_instance()
	if settings == null:
		return
	_sync_pending_from_controls()
	if _pending_resolution_index < 0 or _pending_resolution_index >= UIScaleSettings.SUPPORTED_RESOLUTIONS.size():
		_pending_resolution_index = settings.get_resolution_index()
	var resolution: Vector2i = UIScaleSettings.SUPPORTED_RESOLUTIONS[_pending_resolution_index]
	settings.set_window_size(resolution)
	settings.set_ui_scale_multiplier(_pending_ui_scale)
	_pending_resolution_index = settings.get_resolution_index()
	_pending_ui_scale = settings.get_ui_scale_multiplier()
	if _resolution_option != null:
		_resolution_option.select(_pending_resolution_index)
	if _ui_scale_slider != null:
		_ui_scale_slider.set_value_no_signal(_pending_ui_scale)
	_update_ui_scale_value_label(_pending_ui_scale)


func _confirm_settings() -> void:
	_apply_pending_settings()
	_close_modal()


func _sync_pending_from_controls() -> void:
	if _resolution_option != null:
		_pending_resolution_index = _resolution_option.selected
	if _ui_scale_slider != null:
		_pending_ui_scale = _normalize_ui_scale(_ui_scale_slider.value)


func _normalize_ui_scale(value: float) -> float:
	var clamped := clampf(value, UIScaleSettings.MIN_UI_SCALE, UIScaleSettings.MAX_UI_SCALE)
	return snappedf(clamped, UIScaleSettings.UI_SCALE_STEP)


func _update_ui_scale_value_label(value: float) -> void:
	if _ui_scale_value_label == null:
		return
	_ui_scale_value_label.text = "%d%%" % int(round(value * 100.0))


func _content_vbox() -> VBoxContainer:
	for child in get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null
