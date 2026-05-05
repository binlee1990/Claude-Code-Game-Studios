## OfflineDrawer — P-NAV-04 quick offline settlement drawer.
##
## The detailed settlement screen remains a full MVP screen. This drawer is
## the right-side quick view triggered by offline.settled and the TOP STRIP
## pending badge.
class_name OfflineDrawer
extends PanelContainer

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

const DRAWER_WIDTH := 480.0
const RESOURCE_ORDER := ["lingqi", "xiuwei", "lingshi", "herb", "exp"]
const RESOURCE_NAMES := {
	"lingqi": "灵气",
	"xiuwei": "修为",
	"lingshi": "灵石",
	"herb": "药材",
	"exp": "经验",
}

var _summary: Dictionary = {}
var _content: VBoxContainer = null
var _pending_label: Label = null
var _tween: Tween = null


func _ready() -> void:
	custom_minimum_size = Vector2(DRAWER_WIDTH, 0)
	_apply_panel_style()
	_build_content()
	apply_summary(_demo_summary())
	hide_drawer(true)


func _apply_panel_style() -> void:
	var texture := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.OVERLAYS, "offline_paper")
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 32
	style.texture_margin_top = 32
	style.texture_margin_right = 32
	style.texture_margin_bottom = 32
	add_theme_stylebox_override("panel", style)


func _build_content() -> void:
	for child in get_children():
		child.queue_free()

	_content = VBoxContainer.new()
	_content.name = "OfflineDrawerContent"
	_content.add_theme_constant_override("separation", 12)
	add_child(_content)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 8)
	_content.add_child(header)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STATUS_ICONS, "offline_pending")
	header.add_child(icon)

	var title := Label.new()
	title.text = tr("离线收益速览")
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(hide_drawer)
	header.add_child(close_btn)

	_pending_label = Label.new()
	_pending_label.text = tr("暂无待查看离线收益")
	_pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pending_label.add_theme_font_size_override("font_size", 16)
	_content.add_child(_pending_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_content.add_child(actions)

	var detail_btn := Button.new()
	detail_btn.text = tr("查看详情")
	detail_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_btn.pressed.connect(_open_detail_screen)
	actions.add_child(detail_btn)

	var defer_btn := Button.new()
	defer_btn.text = tr("稍后")
	defer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defer_btn.pressed.connect(hide_drawer)
	actions.add_child(defer_btn)


func apply_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	if _content == null:
		return
	_clear_dynamic_rows()
	var duration := float(_summary.get("duration", 0.0))
	var title := tr("离线 %s，已结算以下收益：") % _format_duration(duration)
	if _pending_label != null:
		_pending_label.text = title

	var resources: Dictionary = _summary.get("resources", {})
	if resources.is_empty():
		resources = _resources_from_settlement_payload(_summary)

	for resource_id in RESOURCE_ORDER:
		var data: Dictionary = resources.get(resource_id, {})
		if data.is_empty():
			continue
		_content.add_child(_make_resource_row(resource_id, data))

	var warnings: Array = _summary.get("warnings", [])
	if not warnings.is_empty():
		var warning := Label.new()
		warning.name = "DynamicRow"
		warning.text = "%s: %s" % [tr("提醒"), ", ".join(warnings)]
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_font_size_override("font_size", 14)
		warning.add_theme_color_override("font_color", Color(0.8, 0.133, 0.133))
		_content.add_child(warning)


func _clear_dynamic_rows() -> void:
	for child in _content.get_children():
		if child.name == "DynamicRow":
			child.queue_free()


func _make_resource_row(resource_id: String, data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "DynamicRow"
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.RESOURCE_ICONS, resource_id)
	row.add_child(icon)

	var label := Label.new()
	label.text = tr(RESOURCE_NAMES.get(resource_id, resource_id))
	label.add_theme_font_size_override("font_size", 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var claimed := _to_big_number(data.get("claimed", data.get("amount", 0)))
	var lost := _to_big_number(data.get("lost", 0))
	var amount := Label.new()
	amount.text = "+%s" % NumberFormatter.format(claimed)
	amount.add_theme_font_size_override("font_size", 18)
	row.add_child(amount)

	if not lost.is_zero():
		var loss := Label.new()
		loss.text = "-%s" % NumberFormatter.format(lost)
		loss.add_theme_font_size_override("font_size", 14)
		loss.add_theme_color_override("font_color", Color(0.690, 0.251, 0.251))
		row.add_child(loss)

	return row


func show_drawer() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween != null:
		_tween.kill()
	_set_closed_offsets()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_left", -DRAWER_WIDTH, 0.18).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "offset_right", 0.0, 0.18).set_ease(Tween.EASE_OUT)


func hide_drawer(immediate: bool = false) -> void:
	if immediate:
		_set_closed_offsets()
		visible = false
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_left", 0.0, 0.15).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "offset_right", DRAWER_WIDTH, 0.15).set_ease(Tween.EASE_IN)
	_tween.finished.connect(hide)


func toggle_drawer() -> void:
	if visible:
		hide_drawer()
	else:
		show_drawer()


func _set_closed_offsets() -> void:
	offset_left = 0.0
	offset_right = DRAWER_WIDTH


func _open_detail_screen() -> void:
	hide_drawer(true)
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_screen("offline_settlement")


func _resources_from_settlement_payload(payload: Dictionary) -> Dictionary:
	var result := {}
	var claimed: Dictionary = payload.get("claimed", {})
	var lost: Dictionary = payload.get("lost", {})
	for resource_id in RESOURCE_ORDER:
		if claimed.has(resource_id) or lost.has(resource_id):
			result[resource_id] = {
				"claimed": claimed.get(resource_id, 0),
				"lost": lost.get(resource_id, 0),
			}
	return result


func _demo_summary() -> Dictionary:
	return {
		"duration": 7200.0,
		"resources": {
			"lingqi": {"claimed": BigNumber.from_int(420), "lost": BigNumber.zero()},
			"xiuwei": {"claimed": BigNumber.from_int(260), "lost": BigNumber.zero()},
			"lingshi": {"claimed": BigNumber.from_int(48), "lost": BigNumber.zero()},
			"herb": {"claimed": BigNumber.from_int(30), "lost": BigNumber.from_int(4)},
			"exp": {"claimed": BigNumber.from_int(110), "lost": BigNumber.zero()},
		},
		"warnings": [tr("药材接近满仓")],
	}


func _to_big_number(value: Variant) -> BigNumber:
	if value is BigNumber:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		return BigNumber.from_dict(value)
	if typeof(value) == TYPE_INT:
		return BigNumber.from_int(value)
	if typeof(value) == TYPE_FLOAT:
		return BigNumber.from_float(value)
	return BigNumber.from_string(str(value))


func _format_duration(seconds: float) -> String:
	var total := int(seconds)
	var h := total / 3600
	var m := (total % 3600) / 60
	if h > 0:
		return "%d%s%d%s" % [h, tr("小时"), m, tr("分钟")]
	return "%d%s" % [m, tr("分钟")]
