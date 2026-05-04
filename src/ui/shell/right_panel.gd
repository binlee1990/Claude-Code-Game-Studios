## RIGHT PANEL — 320px battle log + status chips.
##
## Contains a RichTextLabel-based battle log (P-FBK-03) with
## brief/detailed toggle and a status chip stack (P-FBK-02).
## Max 200 log lines. Auto-scrolls to latest unless user scrolls up.
class_name RightPanelControl
extends PanelContainer


const MAX_LOG_LINES := 200
const VISIBLE_LINES := 8

var _log_rich_label: RichTextLabel = null
var _log_lines: Array[Dictionary] = []  # [{text, color, timestamp}]
var _detailed_mode: bool = false
var _auto_scroll: bool = true
var _chip_container: VBoxContainer = null


func _ready() -> void:
	_build_content()
	_subscribe_events()


func _build_content() -> void:
	# Clear placeholder children.
	var vbox := _get_content_vbox()
	if vbox == null:
		return
	for child in vbox.get_children():
		child.queue_free()

	# Toggle row: "简略/详细" + collapse button
	var toggle_row := HBoxContainer.new()
	toggle_row.name = "ToggleRow"
	toggle_row.theme_override_constants_separation = 8

	var toggle_label := Label.new()
	toggle_label.text = "   " + tr("战斗日志")
	toggle_label.add_theme_font_size_override("font_size", 14)
	toggle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle_row.add_child(toggle_label)

	var brief_btn := Button.new()
	brief_btn.name = "BriefBtn"
	brief_btn.text = tr("简")
	brief_btn.flat = true
	brief_btn.focus_mode = Control.FOCUS_ALL
	brief_btn.pressed.connect(_on_toggle_brief)
	toggle_row.add_child(brief_btn)

	var detail_btn := Button.new()
	detail_btn.name = "DetailBtn"
	detail_btn.text = tr("详")
	detail_btn.flat = true
	detail_btn.focus_mode = Control.FOCUS_ALL
	detail_btn.pressed.connect(_on_toggle_detailed)
	toggle_row.add_child(detail_btn)

	vbox.add_child(toggle_row)

	# Battle log RichTextLabel
	_log_rich_label = RichTextLabel.new()
	_log_rich_label.name = "BattleLog"
	_log_rich_label.bbcode_enabled = true
	_log_rich_label.scroll_following = true
	_log_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_rich_label.custom_minimum_size = Vector2(0, 200)
	_log_rich_label.add_theme_font_size_override("font_size", 12)
	_log_rich_label.gui_input.connect(_on_log_scroll_input)
	vbox.add_child(_log_rich_label)

	# Status chip stack
	_chip_container = VBoxContainer.new()
	_chip_container.name = "ChipStack"
	_chip_container.theme_override_constants_separation = 4
	vbox.add_child(_chip_container)

	# Initialize with a placeholder.
	_append_log(tr("战斗日志就绪 — 等待战斗事件..."), Color(0.604, 0.580, 0.533))
	_rebuild_bbcode()


func _get_content_vbox() -> VBoxContainer:
	for child in get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


func _subscribe_events() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.subscribe("combat.finished", _on_combat_finished)
	bus.subscribe("resource.lingqi.overflow", _on_resource_warning)
	bus.subscribe("resource.xiuwei.overflow", _on_resource_warning)
	bus.subscribe("resource.lingshi.overflow", _on_resource_warning)
	bus.subscribe("resource.herb.overflow", _on_resource_warning)


## Append a log entry. Color-coded per combat event type.
func append_log(text: String, color: Color = Color(0.604, 0.580, 0.533)) -> void:
	_append_log(text, color)
	_rebuild_bbcode()


func _append_log(text: String, color: Color) -> void:
	_log_lines.append({
		"text": text,
		"color": color,
		"timestamp": Time.get_ticks_msec(),
	})
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()


func _rebuild_bbcode() -> void:
	if _log_rich_label == null:
		return
	var bbcode := ""
	for line in _log_lines:
		var col: Color = line["color"]
		var color_hex := "#%02x%02x%02x" % [col.r8, col.g8, col.b8]
		bbcode += "[color=%s]%s[/color]\n" % [color_hex, line["text"]]
	_log_rich_label.text = bbcode
	if _auto_scroll:
		_log_rich_label.scroll_to_line(_log_rich_label.get_line_count() - 1)


func _on_log_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# User manually scrolled — pause auto-scroll.
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_auto_scroll = false


func _on_toggle_brief() -> void:
	_detailed_mode = false
	# Future: store brief/detailed versions of each line.


func _on_toggle_detailed() -> void:
	_detailed_mode = true


## EventBus callbacks.

func _on_combat_finished(payload: Dictionary) -> void:
	var victory := bool(payload.get("victory", false))
	var enemy_id := str(payload.get("enemy_id", "?"))
	var zone_id := str(payload.get("zone_id", "?"))
	var text: String
	var color: Color
	if victory:
		text = "%s: %s @ %s" % [tr("胜利"), tr(enemy_id), tr(zone_id)]
		color = Color(0.961, 0.784, 0.259)  # burst_gold
	else:
		text = "%s: %s @ %s" % [tr("失败"), tr(enemy_id), tr(zone_id)]
		color = Color(0.8, 0.133, 0.133)  # failure_red
	_append_log(text, color)
	_rebuild_bbcode()


func _on_resource_warning(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	var lost: BigNumber = payload.get("lost")
	if lost == null:
		return
	var text := "%s %s %s" % [tr("溢出"), tr(resource_id), NumberFormatter.format(lost)]
	_append_log(text, Color(0.690, 0.251, 0.251))  # bottleneck_red
	_rebuild_bbcode()
	_add_warning_chip(resource_id, lost)


## Add a warning chip to the chip stack.
func _add_warning_chip(resource_id: String, amount: BigNumber) -> void:
	if _chip_container == null:
		return
	# Limit to 5 chips max.
	if _chip_container.get_child_count() >= 5:
		_chip_container.get_child(0).queue_free()

	var chip := PanelContainer.new()
	chip.name = "WarningChip_%s" % resource_id

	var label := Label.new()
	label.text = "%s %s" % [tr(resource_id), NumberFormatter.format(amount)]
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.690, 0.251, 0.251))  # bottleneck_red
	chip.add_child(label)

	_chip_container.add_child(chip)


## Clear all status chips.
func clear_chips() -> void:
	if _chip_container == null:
		return
	for child in _chip_container.get_children():
		child.queue_free()
