## CultivationScreen — 修炼屏 (S11-009).
##
## Layout zones per cultivation-screen UX spec:
##   HERO ZONE (top-left): portrait + idle_sheet + stance icon + level/realm
##   DECISION ZONE (top-right): 4 expandable resource rows + stance switch
##   ACTION ZONE (bottom-left): manual cultivate button + condense params
##   INSPECTION ZONE (bottom-right): simulation panel
##
## Follows BaseScreen lifecycle. Reads data via host getters, writes via commands.
class_name CultivationScreen
extends BaseScreen

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

# ---------------------------------------------------------------------------
# HERO ZONE
# ---------------------------------------------------------------------------
@onready var portrait_rect: TextureRect = %PortraitRect
@onready var stance_icon: TextureRect = %StanceIcon
@onready var level_realm_label: Label = %LevelRealmLabel
@onready var hero_zone: PanelContainer = %HeroZone

# ---------------------------------------------------------------------------
# DECISION ZONE — 4 expandable resource rows
# ---------------------------------------------------------------------------
@onready var lingqi_row: ResourceProductionRow = %LingqiRow
@onready var xiuwei_row: ResourceProductionRow = %XiuweiRow
@onready var lingshi_row: ResourceProductionRow = %LingshiRow
@onready var herb_row: ResourceProductionRow = %HerbRow
@onready var stance_switch_btn: Button = %StanceSwitchBtn
@onready var decision_zone: PanelContainer = %DecisionZone

# ---------------------------------------------------------------------------
# ACTION ZONE
# ---------------------------------------------------------------------------
@onready var manual_btn: Button = %ManualBtn
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var condense_cost_label: Label = %CondenseCostLabel
@onready var condense_rate_label: Label = %CondenseRateLabel
@onready var shortage_chip: PanelContainer = %ShortageChip
@onready var action_zone: PanelContainer = %ActionZone

# ---------------------------------------------------------------------------
# INSPECTION ZONE — simulation panel
# ---------------------------------------------------------------------------
@onready var inspection_zone: PanelContainer = %InspectionZone
@onready var sim_header_label: Label = %SimHeaderLabel
@onready var sim_duration_label: Label = %SimDurationLabel
@onready var sim_duration_slider: HSlider = %SimDurationSlider
@onready var sim_stance_option: OptionButton = %SimStanceOption
@onready var sim_result_label: RichTextLabel = %SimResultLabel
@onready var sim_apply_btn: Button = %SimApplyBtn

var _oms_service: RefCounted = null
var _resource_service: RefCounted = null
var _storage_service: RefCounted = null
var _cultivation_service: RefCounted = null
var _cooldown_remaining: float = 0.0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	_resolve_services()
	_apply_visual_style()
	_setup_stance_option()
	_connect_buttons()
	_refresh_all()
	_start_ftue_breathing_glow()


func on_activated() -> void:
	_subscribe("resource.lingqi.changed", _on_resource_changed)
	_subscribe("resource.xiuwei.changed", _on_resource_changed)
	_subscribe("resource.lingshi.changed", _on_resource_changed)
	_subscribe("resource.herb.changed", _on_resource_changed)
	_subscribe("cultivation.stance_changed", _on_stance_changed)
	_subscribe("level.changed", _refresh_level_realm)
	_subscribe("realm.advanced", _refresh_level_realm)
	_subscribe("hud.realm_ceremony", _on_realm_ceremony)
	_refresh_all()


func on_deactivated() -> void:
	_unsubscribe("resource.lingqi.changed", _on_resource_changed)
	_unsubscribe("resource.xiuwei.changed", _on_resource_changed)
	_unsubscribe("resource.lingshi.changed", _on_resource_changed)
	_unsubscribe("resource.herb.changed", _on_resource_changed)
	_unsubscribe("cultivation.stance_changed", _on_stance_changed)
	_unsubscribe("level.changed", _refresh_level_realm)
	_unsubscribe("realm.advanced", _refresh_level_realm)
	_unsubscribe("hud.realm_ceremony", _on_realm_ceremony)


# ---------------------------------------------------------------------------
# Service resolution
# ---------------------------------------------------------------------------
func _resolve_services() -> void:
	var oms_host := OutputMultiplierSystemHost.get_instance()
	if oms_host != null:
		_oms_service = oms_host.get_service()
	var res_host := ResourceSystemHost.get_instance()
	if res_host != null:
		_resource_service = res_host.get_service()
	var storage_host := StorageLimitSystemHost.get_instance()
	if storage_host != null:
		_storage_service = storage_host.get_service()
	var cult_host := CultivationSystemHost.get_instance()
	if cult_host != null:
		_cultivation_service = cult_host.get_service()


# ---------------------------------------------------------------------------
# Button connections
# ---------------------------------------------------------------------------
func _connect_buttons() -> void:
	if stance_switch_btn != null:
		stance_switch_btn.pressed.connect(_on_stance_switch_pressed)
	if manual_btn != null:
		manual_btn.pressed.connect(_on_manual_cultivate_pressed)
	if sim_apply_btn != null:
		sim_apply_btn.pressed.connect(_on_sim_apply_pressed)
	if sim_duration_slider != null:
		sim_duration_slider.value_changed.connect(_on_simulation_value_changed)
	if sim_stance_option != null:
		sim_stance_option.item_selected.connect(_on_simulation_option_selected)


func _setup_stance_option() -> void:
	if sim_stance_option == null:
		return
	sim_stance_option.clear()
	sim_stance_option.add_item(tr("打坐：积累灵气"), 0)
	sim_stance_option.add_item(tr("凝练：转化修为"), 1)
	if sim_stance_option.item_count > 0:
		sim_stance_option.selected = 0


func _apply_visual_style() -> void:
	var panels: Array[PanelContainer] = [hero_zone, decision_zone, action_zone, inspection_zone]
	for panel in panels:
		if panel == null:
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.130, 0.130, 0.136, 0.96)
		style.border_color = Color(0.245, 0.245, 0.255, 1.0)
		style.set_border_width_all(1)
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		panel.add_theme_stylebox_override("panel", style)
	if sim_header_label != null:
		sim_header_label.text = tr("姿态收益预览")
		sim_header_label.add_theme_color_override("font_color", Color(0.96, 0.74, 0.18))
	if sim_result_label != null:
		sim_result_label.add_theme_font_size_override("normal_font_size", 18)
	if sim_duration_slider != null:
		sim_duration_slider.step = 10.0


# ---------------------------------------------------------------------------
# Refresh
# ---------------------------------------------------------------------------
func _refresh_all() -> void:
	_refresh_hero()
	_refresh_resource_rows()
	_refresh_action_zone()
	_refresh_simulation()


func _refresh_hero() -> void:
	# Portrait
	if portrait_rect != null:
		var tex := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.PLAYER, "portrait")
		if tex != null:
			portrait_rect.texture = tex
	# Stance icon
	_refresh_stance_icon()
	# Level + realm
	_refresh_level_realm({})


func _refresh_stance_icon() -> void:
	if stance_icon == null or _cultivation_service == null:
		return
	var stance: String = "meditate"
	if _cultivation_service.has_method("get_stance"):
		stance = _cultivation_service.get_stance()
	elif _cultivation_service.has_method("get_hud_state"):
		var state: Dictionary = _cultivation_service.get_hud_state()
		stance = str(state.get("stance", stance))
	stance_icon.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STANCE_ICONS, stance)


func _refresh_level_realm(_payload: Dictionary) -> void:
	if level_realm_label == null:
		return
	var host := LevelSystemHost.get_instance()
	if host == null or host.get_service() == null:
		level_realm_label.text = "Lv.1 凡人"
		return
	var svc := host.get_service()
	var lv := svc.get_level("player") if svc.has_method("get_level") else 1
	var realm := svc.get_realm("player") if svc.has_method("get_realm") else "凡人"
	level_realm_label.text = "Lv.%d %s" % [lv, tr(realm)]


func _refresh_resource_rows() -> void:
	if _oms_service == null:
		return
	for res_id in ["lingqi", "xiuwei", "lingshi", "herb"]:
		_refresh_single_row(res_id)


func _refresh_single_row(resource_id: String) -> void:
	var row: ResourceProductionRow = _get_row_for(resource_id)
	if row == null:
		return
	row.configure(resource_id, _label_for_resource(resource_id), str(Sprint11AssetCatalog.RESOURCE_ICONS.get(resource_id, "")))
	var rate: float = 0.0
	if _oms_service != null and _oms_service.has_method("get_production_rate"):
		rate = _oms_service.get_production_rate(resource_id)
	row.set_rate(rate)
	if _resource_service != null and _resource_service.has_method("get_value"):
		row.set_value(_resource_service.get_value(resource_id))
	if _storage_service != null and _storage_service.has_method("get_capacity_state"):
		row.set_capacity_state(_storage_service.get_capacity_state(resource_id))
	if _oms_service != null and _oms_service.has_method("get_breakdown"):
		var breakdown: Dictionary = _oms_service.get_breakdown(resource_id)
		row.set_breakdown(breakdown)


func _get_row_for(resource_id: String) -> ResourceProductionRow:
	match resource_id:
		"lingqi": return lingqi_row
		"xiuwei": return xiuwei_row
		"lingshi": return lingshi_row
		"herb": return herb_row
	return null


func _refresh_action_zone() -> void:
	if _cultivation_service == null:
		return
	var stance: String = "meditate"
	if _cultivation_service.has_method("get_stance"):
		stance = _cultivation_service.get_stance()
	elif _cultivation_service.has_method("get_hud_state"):
		var state: Dictionary = _cultivation_service.get_hud_state()
		stance = str(state.get("stance", stance))
	var is_condense := stance == "condense"
	if condense_cost_label != null:
		condense_cost_label.visible = is_condense
	if condense_rate_label != null:
		condense_rate_label.visible = is_condense
	# Condense params
	if is_condense:
		if _cultivation_service.has_method("get_condense_cost"):
			var cost: BigNumber = _cultivation_service.get_condense_cost()
			if condense_cost_label != null:
				condense_cost_label.text = "%s: %s" % [tr("凝练消耗"), NumberFormatter.format(cost)]
		elif _cultivation_service.get("condense_cost") != null and condense_cost_label != null:
			var cost: BigNumber = _cultivation_service.get("condense_cost")
			condense_cost_label.text = "%s: %s" % [tr("凝练消耗"), NumberFormatter.format(cost)]
		if _cultivation_service.has_method("get_condense_rate"):
			var rate: float = _cultivation_service.get_condense_rate()
			if condense_rate_label != null:
				condense_rate_label.text = "%s: %.0f%%" % [tr("凝练效率"), rate * 100.0]
		elif condense_rate_label != null:
			condense_rate_label.text = "%s: %s" % [tr("凝练效率"), tr("1 灵气 -> 1 修为")]
	# Shortage chip
	if shortage_chip != null and _cultivation_service.has_method("get_hud_state"):
		var state: Dictionary = _cultivation_service.get_hud_state()
		shortage_chip.visible = bool(state.get("shortage", false))
	elif shortage_chip != null:
		shortage_chip.visible = false


func _refresh_simulation() -> void:
	if sim_result_label == null:
		return
	var seconds := _simulation_seconds()
	var target_stance := _selected_sim_stance()
	var stance_label := _stance_label(target_stance)
	if sim_duration_label != null:
		sim_duration_label.text = tr("预览时长：%s") % _format_duration(seconds)
	if sim_apply_btn != null:
		sim_apply_btn.text = tr("切换到%s") % stance_label

	var current_stance := _current_stance()
	var prefix := tr("当前：%s  →  预览：%s") % [_stance_label(current_stance), stance_label]
	if target_stance == "condense":
		sim_result_label.text = _build_condense_preview(prefix, seconds)
	else:
		sim_result_label.text = _build_meditate_preview(prefix, seconds)


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_resource_changed(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	_refresh_single_row(resource_id)
	if resource_id == "lingqi" or resource_id == "xiuwei":
		_refresh_simulation()


func _on_stance_changed(payload: Dictionary) -> void:
	_refresh_hero()
	_refresh_action_zone()
	_refresh_resource_rows()
	_refresh_simulation()


func _on_stance_switch_pressed() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_modal("stance_select")


func _on_manual_cultivate_pressed() -> void:
	if _cultivation_service == null:
		return
	if _cooldown_remaining > 0.0:
		return
	if _cultivation_service.has_method("manual_cultivate"):
		var applied := bool(_cultivation_service.manual_cultivate())
		if applied:
			_show_floating_gain(tr("+1 灵气"), manual_btn)
	_cooldown_remaining = 0.5
	if cooldown_bar != null:
		cooldown_bar.max_value = 0.5
		cooldown_bar.value = 0.5
	_stop_ftue_breathing_glow()
	_play_manual_pulse()


## Start breathing glow on manual_btn for FTUE Stage 0 (onboarding hint).
## Glow cycles once per 1.5s, stops permanently after first click.
func _start_ftue_breathing_glow() -> void:
	var ftue_host := FTUEStateMachineHost.get_instance()
	if ftue_host == null:
		return
	if ftue_host.get_service().get_stage() > 0:
		return
	if manual_btn == null:
		return
	_do_breath_cycle()


func _do_breath_cycle() -> void:
	if manual_btn == null or not is_instance_valid(manual_btn):
		return
	var ftue_host := FTUEStateMachineHost.get_instance()
	if ftue_host != null and ftue_host.get_service().get_stage() > 0:
		return
	var tween := create_tween()
	tween.tween_property(manual_btn, "modulate:a", 0.5, 0.75).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(manual_btn, "modulate:a", 1.0, 0.75).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_do_breath_cycle)


func _stop_ftue_breathing_glow() -> void:
	if manual_btn != null:
		manual_btn.modulate = Color.WHITE


## Realm breakthrough ceremony: gold stamp burst + attribute celebration.
func _on_realm_ceremony(payload: Dictionary) -> void:
	var new_realm: String = payload.get("new_realm", "")
	if new_realm.is_empty():
		return
	_show_realm_burst(new_realm)


func _show_realm_burst(realm_name: String) -> void:
	var burst := TextureRect.new()
	burst.name = "RealmBurst"
	burst.texture = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.VFX, "realm_burst_gold")
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.anchor_left = 0.5
	burst.anchor_top = 0.5
	burst.offset_left = -128
	burst.offset_top = -128
	burst.custom_minimum_size = Vector2(256, 256)
	add_child(burst)

	var realm_label := Label.new()
	realm_label.name = "RealmLabel"
	realm_label.text = tr(realm_name)
	realm_label.add_theme_font_size_override("font_size", 36)
	realm_label.add_theme_color_override("font_color", Color(0.961, 0.784, 0.259))
	realm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	realm_label.anchor_left = 0.5
	realm_label.anchor_top = 0.5
	realm_label.offset_left = -150
	realm_label.offset_top = -20
	realm_label.custom_minimum_size = Vector2(300, 40)
	add_child(realm_label)

	var tween := create_tween().set_parallel(true)
	burst.scale = Vector2(0.3, 0.3)
	burst.modulate = Color(1, 1, 1, 0.0)
	realm_label.scale = Vector2(0.5, 0.5)
	realm_label.modulate = Color(1, 1, 1, 0.0)

	tween.tween_property(burst, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 0.4, 0.5)
	tween.tween_property(realm_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(realm_label, "modulate:a", 1.0, 0.5)

	tween.chain().tween_property(burst, "scale", Vector2(1.5, 1.5), 1.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(burst, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(realm_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(burst.queue_free)
	tween.chain().tween_callback(realm_label.queue_free)


func _on_sim_apply_pressed() -> void:
	if _cultivation_service == null or sim_stance_option == null:
		return
	var stance_names: Array[String] = ["meditate", "condense"]
	var idx := sim_stance_option.selected
	if idx < 0 or idx >= stance_names.size():
		return
	var target_stance: String = stance_names[idx]
	if _cultivation_service.has_method("set_stance"):
		var changed := bool(_cultivation_service.set_stance(target_stance))
		if changed:
			_show_screen_toast(tr("已切换姿态：%s") % _stance_label(target_stance))
			_show_floating_gain(tr("姿态已应用"), sim_apply_btn)
	_refresh_all()


func _on_simulation_value_changed(_value: float) -> void:
	_refresh_simulation()


func _on_simulation_option_selected(_index: int) -> void:
	_refresh_simulation()


func _simulation_seconds() -> int:
	if sim_duration_slider == null:
		return 60
	return int(round(sim_duration_slider.value / 10.0) * 10.0)


func _selected_sim_stance() -> String:
	if sim_stance_option == null:
		return "meditate"
	var stance_names: Array[String] = ["meditate", "condense"]
	var idx := sim_stance_option.selected
	if idx < 0 or idx >= stance_names.size():
		return "meditate"
	return stance_names[idx]


func _current_stance() -> String:
	if _cultivation_service == null:
		return "meditate"
	if _cultivation_service.has_method("get_stance"):
		return str(_cultivation_service.get_stance())
	if _cultivation_service.has_method("get_hud_state"):
		var state: Dictionary = _cultivation_service.get_hud_state()
		return str(state.get("stance", "meditate"))
	return "meditate"


func _build_condense_preview(prefix: String, seconds: int) -> String:
	var cost := _get_condense_cost().multiply_float(float(seconds))
	var gain := _get_condense_gain().multiply_float(float(seconds))
	var available := _get_resource_value("lingqi")
	var enough := available.greater_or_equal(cost)
	var status := tr("灵气充足，可立即执行") if enough else tr("灵气不足，先打坐积累")
	var status_color := "#48b24f" if enough else "#ff4d42"
	return "[color=#e8e0d0]%s[/color]\n[color=#9b9488]%s[/color]\n[color=#ff9f0a]-%s 灵气[/color]   [color=#48b24f]+%s 修为[/color]\n[color=%s]%s[/color]" % [
		prefix,
		tr("按当前凝练规则估算，不会提前扣资源。"),
		NumberFormatter.format(cost),
		NumberFormatter.format(gain),
		status_color,
		status,
	]


func _build_meditate_preview(prefix: String, seconds: int) -> String:
	var lingqi_rate := _production_rate("lingqi")
	var xiuwei_rate := _production_rate("xiuwei")
	var lingqi_gain := BigNumber.from_float(lingqi_rate * float(seconds))
	var xiuwei_gain := BigNumber.from_float(xiuwei_rate * float(seconds))
	var lingqi_text := NumberFormatter.format(lingqi_gain)
	var xiuwei_text := NumberFormatter.format(xiuwei_gain)
	if lingqi_gain.is_zero() and xiuwei_gain.is_zero():
		return "[color=#e8e0d0]%s[/color]\n[color=#9b9488]%s[/color]\n[color=#48b24f]+1 灵气 / 次[/color]  [color=#9b9488]%s[/color]" % [
			prefix,
			tr("打坐是默认姿态，适合先积累灵气。"),
			tr("手动修炼立即生效"),
		]
	return "[color=#e8e0d0]%s[/color]\n[color=#9b9488]%s[/color]\n[color=#48b24f]+%s 灵气[/color]   [color=#48b24f]+%s 修为[/color]" % [
		prefix,
		tr("按当前每秒产出估算，不会立即写入资源。"),
		lingqi_text,
		xiuwei_text,
	]


func _get_condense_cost() -> BigNumber:
	if _cultivation_service == null:
		return BigNumber.one()
	if _cultivation_service.has_method("get_condense_cost"):
		return _cultivation_service.get_condense_cost()
	var value: Variant = _cultivation_service.get("condense_cost")
	if value is BigNumber:
		return value
	return BigNumber.one()


func _get_condense_gain() -> BigNumber:
	if _cultivation_service == null:
		return BigNumber.one()
	if _cultivation_service.has_method("get_condense_gain"):
		return _cultivation_service.get_condense_gain()
	var value: Variant = _cultivation_service.get("condense_gain")
	if value is BigNumber:
		return value
	return BigNumber.one()


func _get_resource_value(resource_id: String) -> BigNumber:
	if _resource_service != null and _resource_service.has_method("get_value"):
		var value: Variant = _resource_service.get_value(resource_id)
		if value is BigNumber:
			return value
	return BigNumber.zero()


func _production_rate(resource_id: String) -> float:
	if _oms_service != null and _oms_service.has_method("get_production_rate"):
		return float(_oms_service.get_production_rate(resource_id))
	return 0.0


func _format_duration(seconds: int) -> String:
	if seconds >= 60:
		var minutes := int(seconds / 60)
		if seconds % 60 == 0:
			return tr("%d 分钟") % minutes
	return tr("%d 秒") % seconds


func _stance_label(stance_id: String) -> String:
	match stance_id:
		"condense": return tr("凝练")
		"meditate": return tr("打坐")
	return tr(stance_id)


func _show_screen_toast(message: String) -> void:
	var rv := UIManagerHost.find_root_viewport()
	if rv != null and rv.has_method("show_typed_toast"):
		rv.show_typed_toast("stance", message, {}, 3.0)


func _show_floating_gain(message: String, anchor: Control) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	var label := Label.new()
	label.name = "FloatingGain"
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.961, 0.659, 0.078))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	var start := anchor.get_global_rect().get_center() - get_global_rect().position
	label.position = start + Vector2(-28, -36)
	label.modulate = Color(1, 1, 1, 0)
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(label, "position:y", label.position.y - 18.0, 0.42).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.18)
	tween.tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		if cooldown_bar != null:
			cooldown_bar.value = max(0.0, _cooldown_remaining)
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not UIManagerHost.has_open_modal():
		pass  # ESC does nothing on cultivation screen — no parent to go back to


func _label_for_resource(resource_id: String) -> String:
	match resource_id:
		"lingqi": return "灵气"
		"xiuwei": return "修为"
		"lingshi": return "灵石"
		"herb": return "药材"
		"exp": return "经验"
	return resource_id


func _play_manual_pulse() -> void:
	if manual_btn == null:
		return
	var tex := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.VFX, "manual_click_pulse")
	if tex == null:
		return
	var pulse := TextureRect.new()
	pulse.texture = tex
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.custom_minimum_size = manual_btn.size
	manual_btn.add_child(pulse)
	var tween := pulse.create_tween().set_parallel(true)
	pulse.modulate = Color(1, 1, 1, 0.7)
	pulse.scale = Vector2(0.8, 0.8)
	tween.tween_property(pulse, "scale", Vector2(1.2, 1.2), 0.28)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.28)
	tween.tween_callback(pulse.queue_free)
