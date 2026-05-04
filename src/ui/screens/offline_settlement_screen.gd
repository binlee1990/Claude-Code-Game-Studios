## OfflineSettlementScreen — 离线结算屏 (S11-013).
##
## "闭关报告" — vertical scroll report layout.
## Consumes OfflineSettlementSummary from offline.settled event.
## Drawer-first entry: player taps "查看详情" in Offline Drawer → this screen.
## Count-up animation on resource numbers (Tween-based, reduced-motion safe).
class_name OfflineSettlementScreen
extends BaseScreen


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


func _render_resource_breakdown() -> void:
	for child in resource_breakdown.get_children():
		child.queue_free()
	var resources: Dictionary = _summary.get("resources", {})
	for res_id in ["lingqi", "xiuwei", "lingshi", "herb"]:
		var data: Dictionary = resources.get(res_id, {})
		if data.is_empty():
			continue
		var row := HBoxContainer.new()
		row.theme_override_constants_separation = 8
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
		var claimed: float = data.get("claimed", 0.0)
		var lost: float = data.get("lost", 0.0)
		var amount_label := Label.new()
		amount_label.text = "+%.0f" % claimed
		amount_label.add_theme_font_size_override("font_size", 20)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount_label)
		if lost > 0.0:
			var lost_label := Label.new()
			lost_label.text = " (-%.0f)" % lost
			lost_label.add_theme_font_size_override("font_size", 16)
			lost_label.add_theme_color_override("font_color", Color(0.690, 0.251, 0.251))
			row.add_child(lost_label)
		resource_breakdown.add_child(row)
		# Count-up tween on amount_label
		if not _is_reduced_motion():
			_animate_countup(amount_label, claimed)


func _render_loot() -> void:
	if loot_grid == null:
		return
	for child in loot_grid.get_children():
		child.queue_free()
	var loot: Array = _summary.get("loot", [])
	if loot.is_empty():
		loot_gallery_label.visible = false
		return
	loot_gallery_label.visible = true
	for item in loot:
		var card := ItemCard.new()
		var metadata := {}
		var item_id: String = item.get("item_id", "")
		if _item_registry != null and _item_registry.has_method("get") and not item_id.is_empty():
			metadata = _item_registry.get(item_id)
		if metadata.is_empty():
			metadata = {"name": item_id, "rarity": "common", "icon_path": ""}
		metadata["count"] = item.get("quantity", 1)
		card.set_item(metadata)
		loot_grid.add_child(card)


func _render_losses() -> void:
	var has_losses := false
	var resources: Dictionary = _summary.get("resources", {})
	for data in resources.values():
		if data.get("lost", 0.0) > 0.0:
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
