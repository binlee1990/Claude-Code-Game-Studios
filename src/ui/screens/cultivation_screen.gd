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


# ---------------------------------------------------------------------------
# HERO ZONE
# ---------------------------------------------------------------------------
@onready var portrait_rect: TextureRect = %PortraitRect
@onready var stance_icon: TextureRect = %StanceIcon
@onready var level_realm_label: Label = %LevelRealmLabel

# ---------------------------------------------------------------------------
# DECISION ZONE — 4 expandable resource rows
# ---------------------------------------------------------------------------
@onready var lingqi_row: ResourceProductionRow = %LingqiRow
@onready var xiuwei_row: ResourceProductionRow = %XiuweiRow
@onready var lingshi_row: ResourceProductionRow = %LingshiRow
@onready var herb_row: ResourceProductionRow = %HerbRow
@onready var stance_switch_btn: Button = %StanceSwitchBtn

# ---------------------------------------------------------------------------
# ACTION ZONE
# ---------------------------------------------------------------------------
@onready var manual_btn: Button = %ManualBtn
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var condense_cost_label: Label = %CondenseCostLabel
@onready var condense_rate_label: Label = %CondenseRateLabel
@onready var shortage_chip: PanelContainer = %ShortageChip

# ---------------------------------------------------------------------------
# INSPECTION ZONE — simulation panel
# ---------------------------------------------------------------------------
@onready var sim_duration_slider: HSlider = %SimDurationSlider
@onready var sim_stance_option: OptionButton = %SimStanceOption
@onready var sim_result_label: RichTextLabel = %SimResultLabel
@onready var sim_apply_btn: Button = %SimApplyBtn

var _oms_service: RefCounted = null
var _cultivation_service: RefCounted = null
var _cooldown_remaining: float = 0.0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	_resolve_services()
	_setup_stance_option()
	_connect_buttons()
	_refresh_all()


func on_activated() -> void:
	_subscribe("resource.lingqi.changed", _on_resource_changed)
	_subscribe("resource.xiuwei.changed", _on_resource_changed)
	_subscribe("resource.lingshi.changed", _on_resource_changed)
	_subscribe("resource.herb.changed", _on_resource_changed)
	_subscribe("cultivation.stance_changed", _on_stance_changed)
	_subscribe("level.changed", _refresh_level_realm)
	_subscribe("realm.advanced", _refresh_level_realm)
	_refresh_all()


func on_deactivated() -> void:
	_unsubscribe("resource.lingqi.changed", _on_resource_changed)
	_unsubscribe("resource.xiuwei.changed", _on_resource_changed)
	_unsubscribe("resource.lingshi.changed", _on_resource_changed)
	_unsubscribe("resource.herb.changed", _on_resource_changed)
	_unsubscribe("cultivation.stance_changed", _on_stance_changed)
	_unsubscribe("level.changed", _refresh_level_realm)
	_unsubscribe("realm.advanced", _refresh_level_realm)


# ---------------------------------------------------------------------------
# Service resolution
# ---------------------------------------------------------------------------
func _resolve_services() -> void:
	var oms_host := OutputMultiplierSystemHost.get_instance()
	if oms_host != null:
		_oms_service = oms_host.get_service()
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


func _setup_stance_option() -> void:
	if sim_stance_option == null:
		return
	sim_stance_option.clear()
	sim_stance_option.add_item(tr("打坐"), 0)
	sim_stance_option.add_item(tr("凝练"), 1)


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
		var tex := _try_load_texture("res://assets/ui/player/portrait.png")
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
	var path := "res://assets/ui/icons/stances/%s.png" % stance
	if ResourceLoader.exists(path):
		stance_icon.texture = load(path) as Texture2D


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
	var rate: float = 0.0
	if _oms_service != null and _oms_service.has_method("get_production_rate"):
		rate = _oms_service.get_production_rate(resource_id)
	row.set_rate(rate)
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
	var is_condense := stance == "condense"
	if condense_cost_label != null:
		condense_cost_label.visible = is_condense
	if condense_rate_label != null:
		condense_rate_label.visible = is_condense
	# Condense params
	if is_condense:
		if _cultivation_service.has_method("get_condense_cost"):
			var cost := _cultivation_service.get_condense_cost()
			if condense_cost_label != null:
				condense_cost_label.text = "%s: %s" % [tr("凝练消耗"), NumberFormatter.format(cost)]
		if _cultivation_service.has_method("get_condense_rate"):
			var rate: float = _cultivation_service.get_condense_rate()
			if condense_rate_label != null:
				condense_rate_label.text = "%s: %.0f%%" % [tr("凝练效率"), rate * 100.0]
	# Shortage chip
	if shortage_chip != null and _cultivation_service.has_method("get_hud_state"):
		var state: Dictionary = _cultivation_service.get_hud_state()
		shortage_chip.visible = bool(state.get("shortage", false))
	elif shortage_chip != null:
		shortage_chip.visible = false


func _refresh_simulation() -> void:
	if sim_result_label == null:
		return
	sim_result_label.text = tr("拖动滑块查看试算结果")


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_resource_changed(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	_refresh_single_row(resource_id)


func _on_stance_changed(payload: Dictionary) -> void:
	_refresh_hero()
	_refresh_action_zone()
	_refresh_resource_rows()


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
		_cultivation_service.manual_cultivate()
	_cooldown_remaining = 0.5
	if cooldown_bar != null:
		cooldown_bar.max_value = 0.5
		cooldown_bar.value = 0.5


func _on_sim_apply_pressed() -> void:
	if _cultivation_service == null or sim_stance_option == null:
		return
	var stance_names := ["meditate", "condense"]
	var idx := sim_stance_option.selected
	if idx < 0 or idx >= stance_names.size():
		return
	var target_stance := stance_names[idx]
	if _cultivation_service.has_method("set_stance"):
		_cultivation_service.set_stance(target_stance)


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
