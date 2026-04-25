class_name HintBar
extends Control
## UI-P0-04: 全局按键提示条（屏幕底部 24px 固定高度）。
## 调用 set_hints() 更新当前屏幕的可用键位提示。
##
## 用法示例：
##   hint_bar.set_hints([
##     {"key": "Tab",   "action": "切换"},
##     {"key": "Enter", "action": "确认"},
##     {"key": "Esc",   "action": "返回"},
##   ])

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")

const BAR_HEIGHT := 24
const KEY_COLOR    := Color(0.890, 0.690, 0.330, 1.0)   # SRPGTheme.GOLD
const ACTION_COLOR := Color(0.670, 0.610, 0.490, 1.0)   # SRPGTheme.PAPER_MUTED
const FONT_SIZE    := 13
const ITEM_GAP     := 20  # 每条提示之间的水平间距（像素）

var _bar_bg: Panel
var _hint_row: HBoxContainer

func _ready() -> void:
	# 锚定到父节点底部，全宽 24px 高
	anchor_left   = 0.0
	anchor_top    = 1.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_top    = -BAR_HEIGHT
	offset_bottom = 0.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE

	_bar_bg = Panel.new()
	_bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.045, 0.040, 0.038, 0.92)
	bg_style.border_color = Color(SRPGTheme.GOLD.r, SRPGTheme.GOLD.g, SRPGTheme.GOLD.b, 0.35)
	bg_style.border_width_top = 1
	_bar_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(_bar_bg)

	_hint_row = HBoxContainer.new()
	_hint_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint_row.add_theme_constant_override("separation", ITEM_GAP)
	_hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_row)

## 更新按键提示列表。
## hint_list 每项格式：{"key": "Tab", "action": "切换"}
func set_hints(hint_list: Array) -> void:
	for child in _hint_row.get_children():
		child.queue_free()
	for item in hint_list:
		var key_str:    String = str(item.get("key",    ""))
		var action_str: String = str(item.get("action", ""))
		if key_str.is_empty():
			continue
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 4)
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % key_str
		key_lbl.add_theme_color_override("font_color", KEY_COLOR)
		key_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(key_lbl)
		if not action_str.is_empty():
			var action_lbl := Label.new()
			action_lbl.text = action_str
			action_lbl.add_theme_color_override("font_color", ACTION_COLOR)
			action_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
			action_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pair.add_child(action_lbl)
		_hint_row.add_child(pair)
