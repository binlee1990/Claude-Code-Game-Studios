## TOP STRIP — 64px top resource bar.
##
## Shows 5 resource compact rows, level/realm badge, zone context label,
## and a settings gear button. Subscribes to EventBus for real-time updates
## with coalesced refresh at 10Hz.
class_name TopStripControl
extends PanelContainer

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

const RESOURCE_IDS := ["lingqi", "xiuwei", "lingshi", "herb", "exp"]
const RESOURCE_LABELS: Dictionary = {
	"lingqi": "灵气",
	"xiuwei": "修为",
	"lingshi": "灵石",
	"herb": "药材",
	"exp": "经验",
}
const RESOURCE_ICONS: Dictionary = {
	"lingqi": "res://assets/ui/icons/resources/lingqi.png",
	"xiuwei": "res://assets/ui/icons/resources/xiuwei.png",
	"lingshi": "res://assets/ui/icons/resources/lingshi.png",
	"herb": "res://assets/ui/icons/resources/herb.png",
	"exp": "res://assets/ui/icons/resources/exp.png",
}
const REFRESH_INTERVAL: float = 0.1

var _resource_labels: Dictionary = {}    # resource_id -> Label
var _realm_icon: TextureRect = null
var _level_label: Label = null
var _zone_label: Label = null
var _status_icons: Dictionary = {}
var _offline_button: Button = null
var _dirty_resources: Array[String] = []
var _refresh_timer: float = 0.0


func _ready() -> void:
	_build_content()
	_subscribe_events()
	_refresh_all()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL and not _dirty_resources.is_empty():
		_apply_refresh()
		_refresh_timer = 0.0


## Build the TOP STRIP content inside the PanelContainer.
func _build_content() -> void:
	# Find or create the content HBoxContainer.
	var hbox := _get_content_hbox()
	if hbox == null:
		return
	# Clear placeholder.
	for child in hbox.get_children():
		child.queue_free()

	# Resource rows (compact: icon + value)
	for resource_id in RESOURCE_IDS:
		var row := HBoxContainer.new()
		row.name = "Res_%s" % resource_id
		row.add_theme_constant_override("separation", 4)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.RESOURCE_ICONS, resource_id)
		row.add_child(icon)

		var value_label := Label.new()
		value_label.name = "Value"
		value_label.add_theme_font_size_override("font_size", 16)
		value_label.add_theme_color_override("font_color", Color(1.0, 0.624, 0.039))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_resource_labels[resource_id] = value_label

		hbox.add_child(row)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Realm badge + level text
	_realm_icon = TextureRect.new()
	_realm_icon.name = "RealmIcon"
	_realm_icon.custom_minimum_size = Vector2(28, 28)
	_realm_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_realm_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(_realm_icon)

	_level_label = Label.new()
	_level_label.name = "LevelBadge"
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", Color(0.890, 0.878, 0.839))
	hbox.add_child(_level_label)

	# Separator
	hbox.add_child(_make_separator())

	var status_row := HBoxContainer.new()
	status_row.name = "StatusIcons"
	status_row.add_theme_constant_override("separation", 6)
	for status_id in ["combat_active", "combat_failed", "level_up", "overflow_warn"]:
		var status_icon := TextureRect.new()
		status_icon.name = status_id
		status_icon.custom_minimum_size = Vector2(22, 22)
		status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		status_icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STATUS_ICONS, status_id)
		status_icon.visible = status_id in ["combat_active"]
		status_row.add_child(status_icon)
		_status_icons[status_id] = status_icon
	hbox.add_child(status_row)

	_offline_button = Button.new()
	_offline_button.name = "OfflineButton"
	_offline_button.text = tr("离线")
	_offline_button.icon = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STATUS_ICONS, "offline_pending")
	_offline_button.flat = false
	_offline_button.focus_mode = Control.FOCUS_ALL
	_style_top_button(_offline_button, Color(1.0, 0.624, 0.039))
	_offline_button.pressed.connect(_on_offline_pressed)
	hbox.add_child(_offline_button)

	hbox.add_child(_make_separator())

	# Zone context label
	_zone_label = Label.new()
	_zone_label.name = "ZoneLabel"
	_zone_label.add_theme_font_size_override("font_size", 16)
	_zone_label.add_theme_color_override("font_color", Color(0.604, 0.580, 0.533))
	hbox.add_child(_zone_label)

	# Settings button
	var settings_btn := Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "  " + tr("设置") + "  "
	settings_btn.flat = false
	settings_btn.focus_mode = Control.FOCUS_ALL
	_style_top_button(settings_btn, Color(0.118, 0.569, 0.925))
	settings_btn.pressed.connect(_on_settings_pressed)
	hbox.add_child(settings_btn)


func _style_top_button(button: Button, accent: Color) -> void:
	button.custom_minimum_size = Vector2(76, 40)
	button.add_theme_color_override("font_color", Color(0.89, 0.88, 0.84))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.155, 0.155, 0.165), Color(0.215, 0.215, 0.225)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.200, 0.200, 0.210), accent))
	button.add_theme_stylebox_override("pressed", _make_button_style(accent.darkened(0.10), accent))


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _make_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 16
	return sep


func _get_content_hbox() -> HBoxContainer:
	for child in get_children():
		if child is HBoxContainer:
			return child as HBoxContainer
	return null


func _subscribe_events() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	for resource_id in RESOURCE_IDS:
		bus.subscribe("resource.%s.changed" % resource_id, _on_resource_changed)
		bus.subscribe("resource.%s.overflow" % resource_id, _on_resource_overflow)
	bus.subscribe("level.changed", _on_level_changed)
	bus.subscribe("realm.advanced", _on_level_changed)
	bus.subscribe("zone.changed", _on_zone_changed)
	bus.subscribe("combat.finished", _on_combat_finished)
	bus.subscribe("offline.settled", _on_offline_settled)


func _refresh_all() -> void:
	for resource_id in RESOURCE_IDS:
		_refresh_resource_display(resource_id)
	_refresh_level_display()
	_refresh_zone_display()


func _refresh_resource_display(resource_id: String) -> void:
	var label: Label = _resource_labels.get(resource_id)
	if label == null:
		return
	var resource_host := ResourceSystemHost.get_instance()
	if resource_host == null:
		label.text = "..."
		return
	var service := resource_host.get_service()
	if service == null:
		label.text = "..."
		return
	var value := service.get_value(resource_id)
	var text := NumberFormatter.format(value)
	label.text = "%s %s" % [tr(RESOURCE_LABELS.get(resource_id, resource_id)), text]


func _refresh_level_display() -> void:
	if _level_label == null:
		return
	var level_host := LevelSystemHost.get_instance()
	if level_host == null or level_host.get_service() == null:
		_level_label.text = "Lv.? --"
		return
	var service := level_host.get_service()
	var realm := service.get_realm("player")
	_level_label.text = "Lv.%d %s" % [service.get_level("player"), tr(realm)]
	if _realm_icon != null:
		_realm_icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.REALM_ICONS, realm)


func _refresh_zone_display() -> void:
	if _zone_label == null:
		return
	var zone_host := ZoneSystemHost.get_instance()
	if zone_host == null or zone_host.get_service() == null:
		_zone_label.text = tr("未选择区域")
		return
	# ZoneSystem.get_current_zone() or similar — try common API.
	var service := zone_host.get_service()
	var zone_name := ""
	if service.has_method("get_current_zone_name"):
		zone_name = service.get_current_zone_name()
	elif service.get("current_zone_id") != null and service.has_method("get_zone"):
		var zone_id := str(service.get("current_zone_id"))
		var zone: Dictionary = service.get_zone(zone_id)
		zone_name = str(zone.get("name", zone_id))
	elif service.has_method("get_hud_state"):
		var state: Dictionary = service.get_hud_state()
		zone_name = str(state.get("current_zone_name", ""))
	_zone_label.text = zone_name if not zone_name.is_empty() else tr("未知区域")


## EventBus: resource changed → mark dirty for coalesced refresh.
func _on_resource_changed(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	if resource_id.is_empty():
		return
	if resource_id not in _dirty_resources:
		_dirty_resources.append(resource_id)


func _on_level_changed(_payload: Dictionary) -> void:
	_refresh_level_display()
	_show_status("level_up")


func _on_zone_changed(_payload: Dictionary) -> void:
	_refresh_zone_display()


func _on_resource_overflow(_payload: Dictionary) -> void:
	_show_status("overflow_warn")


func _on_combat_finished(payload: Dictionary) -> void:
	_show_status("combat_active" if bool(payload.get("victory", false)) else "combat_failed")


func _on_offline_settled(_payload: Dictionary) -> void:
	if _offline_button != null:
		_offline_button.text = tr("离线 *")


func _show_status(status_id: String) -> void:
	var icon: TextureRect = _status_icons.get(status_id)
	if icon != null:
		icon.visible = true


## Apply coalesced refresh for dirty resources.
func _apply_refresh() -> void:
	for resource_id in _dirty_resources:
		_refresh_resource_display(resource_id)
	_dirty_resources.clear()


func _on_settings_pressed() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_modal("settings")


func _on_offline_pressed() -> void:
	var rv := UIManagerHost.find_root_viewport()
	if rv != null and rv.has_method("toggle_offline_drawer"):
		rv.toggle_offline_drawer()
	if _offline_button != null:
		_offline_button.text = tr("离线")
