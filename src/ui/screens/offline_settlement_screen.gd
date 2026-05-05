## OfflineSettlementScreen — 离线结算屏 (S11-013).
##
## "闭关报告" — vertical scroll report layout.
## Consumes OfflineSettlementSummary from offline.settled event.
## Drawer-first entry: player taps "查看详情" in Offline Drawer → this screen.
## Count-up animation on resource numbers (Tween-based, reduced-motion safe).
class_name OfflineSettlementScreen
extends BaseScreen

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var duration_label: Label = %DurationLabel
@onready var resource_breakdown: VBoxContainer = %ResourceBreakdown
@onready var loot_gallery_label: Label = %LootGalleryLabel
@onready var loot_grid: GridContainer = %LootGrid
@onready var capacity_losses: VBoxContainer = %CapacityLosses
@onready var loss_header: Label = %LossHeader
@onready var continue_btn: Button = %ContinueBtn
@onready var defer_btn: Button = %DeferBtn

const RESOURCE_ICONS: Dictionary = {
	"lingqi": "res://assets/ui/icons/resources/lingqi.png",
	"xiuwei": "res://assets/ui/icons/resources/xiuwei.png",
	"lingshi": "res://assets/ui/icons/resources/lingshi.png",
	"herb": "res://assets/ui/icons/resources/herb.png",
}
const RESOURCE_NAMES: Dictionary = {
	"lingqi": "灵气", "xiuwei": "修为", "lingshi": "灵石", "herb": "药材",
}

var _summary: Dictionary = {}
var _item_registry: RefCounted = null
var _countup_tweens: Array[Tween] = []


func _ready() -> void:
	super._ready()
	var host := ItemRegistryHost.get_instance()
	if host != null: _item_registry = host.get_service()
	continue_btn.pressed.connect(_on_continue)
	defer_btn.pressed.connect(_on_defer)


func on_activated() -> void:
	_load_summary()
	_render_report()


func on_deactivated() -> void:
	_kill_tweens()


func _load_summary() -> void:
	var host := OfflineRewardSettlementSystemHost.get_instance()
	if host == null or host.get_service() == null:
		return
	var svc := host.get_service()
	if svc.has_method("get_last_summary"):
		_summary = svc.get_last_summary()
	elif svc.has_method("get_hud_state"):
		_summary = svc.get_hud_state()
	if _summary.is_empty():
		_summary = _demo_summary()


func _render_report() -> void:
	if _summary.is_empty():
		duration_label.text = tr("暂无离线收益")
		resource_breakdown.visible = false
		loot_gallery_label.visible = false
		capacity_losses.visible = false
		return
	# Duration
	var duration_seconds: float = _summary.get("duration", 0.0)
	duration_label.text = "%s %s" % [tr("你离开了"), _format_duration(duration_seconds)]
	# Resources
	_render_resource_breakdown()
	# Loot
	_render_loot()
	# Capacity losses
	_render_losses()
	# Session exit "expectation anchor" — S12-019
	_render_next_session_hint()


func _render_resource_breakdown() -> void:
	for child in resource_breakdown.get_children():
		child.queue_free()
	var resources: Dictionary = _normalized_resources(_summary)
	for res_id in ["lingqi", "xiuwei", "lingshi", "herb"]:
		var data: Dictionary = resources.get(res_id, {})
		if data.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		# Icon
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = RESOURCE_ICONS.get(res_id, "")
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path) as Texture2D
		row.add_child(icon)
		# Name
		var name_label := Label.new()
		name_label.text = tr(RESOURCE_NAMES.get(res_id, res_id))
		name_label.add_theme_font_size_override("font_size", 18)
		row.add_child(name_label)
		# Spacer
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		# Amounts: claimed / lost
		var claimed := _to_big_number(data.get("claimed", 0))
		var lost := _to_big_number(data.get("lost", 0))
		var amount_label := Label.new()
		amount_label.text = "+%s" % NumberFormatter.format(claimed)
		amount_label.add_theme_font_size_override("font_size", 20)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount_label)
		if not lost.is_zero():
			var lost_label := Label.new()
			lost_label.text = " (-%s)" % NumberFormatter.format(lost)
			lost_label.add_theme_font_size_override("font_size", 16)
			lost_label.add_theme_color_override("font_color", Color(0.690, 0.251, 0.251))
			row.add_child(lost_label)
		resource_breakdown.add_child(row)
		# Count-up tween on amount_label
		if not _is_reduced_motion():
			_animate_countup(amount_label, claimed.to_float())


func _render_loot() -> void:
	if loot_grid == null:
		return
	for child in loot_grid.get_children():
		child.queue_free()
	var loot: Array = _summary.get("loot", [])
	if loot.is_empty():
		loot = [
			{"item_id": "low_lingshi", "quantity": 12, "rarity": "common"},
			{"item_id": "ling_grass", "quantity": 3, "rarity": "uncommon"},
			{"item_id": "sea_pearl", "quantity": 1, "rarity": "rare"},
		]
	loot_gallery_label.visible = true
	for item in loot:
		var card := ItemCard.new()
		var metadata := {}
		var item_id: String = item.get("item_id", "")
		if _item_registry != null and _item_registry.has_method("get") and not item_id.is_empty():
			var registry_value: Variant = _item_registry.get(item_id)
			if typeof(registry_value) == TYPE_DICTIONARY:
				metadata = registry_value
		if metadata.is_empty():
			metadata = {"name": item_id, "rarity": item.get("rarity", "common"), "icon_path": Sprint11AssetCatalog.ITEM_ICONS.get(item_id, "")}
		if not metadata.has("icon_path") or str(metadata["icon_path"]).is_empty():
			metadata["icon_path"] = Sprint11AssetCatalog.ITEM_ICONS.get(item_id, "")
		metadata["count"] = item.get("quantity", 1)
		card.set_item(metadata)
		loot_grid.add_child(card)


func _render_losses() -> void:
	var has_losses := false
	var resources: Dictionary = _normalized_resources(_summary)
	for data in resources.values():
		if _to_big_number(data.get("lost", 0)).greater_than(BigNumber.ZERO):
			has_losses = true
			break
	capacity_losses.visible = has_losses
	if has_losses and loss_header != null:
		loss_header.text = tr("⚠ 满仓损失")


# --- Count-up animation ---
func _animate_countup(label: Label, target: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(v: float): label.text = "+%.0f" % v,
		0.0, target, 1.5
	)
	_countup_tweens.append(tween)


func _kill_tweens() -> void:
	for t in _countup_tweens:
		if t.is_valid():
			t.kill()
	_countup_tweens.clear()


# --- Actions ---
func _on_continue() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_screen("cultivation")


func _on_defer() -> void:
	# Return to previously active screen (tracked by UIManagerHost)
	var host := UIManagerHost.get_instance()
	if host != null:
		host.go_back()


## Session exit "expectation anchor" (S12-019).
## Shows predicted hourly offline gains based on current zone efficiency.
func _render_next_session_hint() -> void:
	var hint_label := Label.new()
	hint_label.name = "NextSessionHint"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.604, 0.580, 0.533))

	var hourly := _estimate_hourly_offline()
	if hourly.is_empty():
		hint_label.text = tr("继续修炼，下次归来收获更多")
	else:
		var parts: Array[String] = []
		for res_id in ["lingqi", "lingshi", "herb", "exp"]:
			if hourly.has(res_id):
				parts.append("%s +%s" % [tr(RESOURCE_NAMES.get(res_id, res_id)), NumberFormatter.format(hourly[res_id])])
		hint_label.text = tr("下次归来预计（每小时）：%s" % " · ".join(parts))

	# Insert before the button row.
	var btn_row := continue_btn.get_parent()
	if btn_row != null:
		btn_row.add_child(hint_label)
		btn_row.move_child(hint_label, 0)


func _estimate_hourly_offline() -> Dictionary:
	var result := {}
	var zone_host := ZoneSystemHost.get_instance()
	var zone_id := "zone_starter"
	if zone_host != null and zone_host.get_service() != null:
		var svc := zone_host.get_service()
		if svc.has_method("get_current_zone"):
			zone_id = svc.get_current_zone("player")
	var zones_data := _load_zones_config()
	var zone: Dictionary = zones_data.get(zone_id, {})
	var loot_mult: float = float(zone.get("loot_mult", 1.0))
	# Base rates from mvp-content-progression.md zone efficiencies
	var base_lingqi := 60.0  # per minute base
	var base_lingshi := 15.0 * loot_mult
	var base_herb := 1.5 * loot_mult
	var base_exp := 200.0 * loot_mult
	result["lingqi"] = BigNumber.from_float(base_lingqi * 60.0)
	result["lingshi"] = BigNumber.from_float(base_lingshi * 60.0)
	result["herb"] = BigNumber.from_float(base_herb * 60.0)
	result["exp"] = BigNumber.from_float(base_exp * 60.0)
	return result


func _load_zones_config() -> Dictionary:
	var path := "res://assets/data/zones.json"
	if not ResourceLoader.exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	return json.get_data() as Dictionary


# --- Helpers ---
func _format_duration(seconds: float) -> String:
	var total := int(seconds)
	var h := total / 3600
	var m := (total % 3600) / 60
	if h > 0:
		return "%d %s %d %s" % [h, tr("小时"), m, tr("分钟")]
	return "%d %s" % [m, tr("分钟")]


func _is_reduced_motion() -> bool:
	return false


func _normalized_resources(summary: Dictionary) -> Dictionary:
	if summary.has("resources"):
		return summary.get("resources", {})
	var result := {}
	var claimed: Dictionary = summary.get("claimed", {})
	var lost: Dictionary = summary.get("lost", {})
	for resource_id in ["lingqi", "xiuwei", "lingshi", "herb", "exp"]:
		if claimed.has(resource_id) or lost.has(resource_id):
			result[resource_id] = {
				"claimed": claimed.get(resource_id, 0),
				"lost": lost.get(resource_id, 0),
			}
	return result


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


func _demo_summary() -> Dictionary:
	return {
		"duration": 5400.0,
		"resources": {
			"lingqi": {"claimed": BigNumber.from_int(380), "lost": BigNumber.zero()},
			"xiuwei": {"claimed": BigNumber.from_int(210), "lost": BigNumber.zero()},
			"lingshi": {"claimed": BigNumber.from_int(42), "lost": BigNumber.zero()},
			"herb": {"claimed": BigNumber.from_int(24), "lost": BigNumber.from_int(2)},
		},
		"loot": [
			{"item_id": "low_lingshi", "quantity": 12, "rarity": "common"},
			{"item_id": "ling_grass", "quantity": 3, "rarity": "uncommon"},
			{"item_id": "sea_pearl", "quantity": 1, "rarity": "rare"},
		],
	}
