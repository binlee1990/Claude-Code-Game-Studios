## ToastStack — P-FBK-01 floating notification stack.
##
## Anchored top-right. Each toast is a PanelContainer with a Label.
## Default 4s auto-dismiss. Max 4 visible toasts (oldest removed).
## New toasts slide in from right + fade in (200ms ease-out).
class_name ToastStack
extends VBoxContainer

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

const MAX_TOASTS := 4
const DEFAULT_DURATION: float = 4.0
const TOAST_HEIGHT: float = 48.0

var _toast_scene: PackedScene = null


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size = Vector2(320, 0)
	_subscribe_events()


## Push a new toast message onto the stack.
func push_toast(message: String, duration: float = DEFAULT_DURATION) -> void:
	push_typed_toast("info", message, {}, duration)


func push_typed_toast(kind: String, message: String, payload: Dictionary = {}, duration: float = DEFAULT_DURATION) -> void:
	# Remove oldest if at max.
	if get_child_count() >= MAX_TOASTS:
		var oldest := get_child(0)
		if oldest.has_method("dismiss"):
			oldest.dismiss()
		else:
			oldest.queue_free()

	var toast := _create_toast(kind, message, payload)
	add_child(toast)
	toast.show()
	# Auto-dismiss after duration.
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_on_toast_timeout.bind(toast))


func _create_toast(kind: String, message: String, payload: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Toast"
	panel.custom_minimum_size = Vector2(320, TOAST_HEIGHT)
	_apply_toast_style(panel, kind, payload)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_for(kind, payload)
	row.add_child(icon)

	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# Animate in.
	var tween := panel.create_tween()
	tween.set_parallel(true)
	panel.modulate = Color(1, 1, 1, 0)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

	return panel


func _apply_toast_style(panel: PanelContainer, kind: String, payload: Dictionary) -> void:
	var frame_key := "epic" if kind in ["rare_drop", "realm"] else "common"
	var rarity := str(payload.get("rarity", ""))
	if not rarity.is_empty() and Sprint11AssetCatalog.RARITY_FRAMES.has(rarity):
		frame_key = rarity
	var texture := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.RARITY_FRAMES, frame_key)
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 16
	style.texture_margin_top = 16
	style.texture_margin_right = 16
	style.texture_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)


func _icon_for(kind: String, payload: Dictionary) -> Texture2D:
	match kind:
		"level":
			return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STATUS_ICONS, "level_up")
		"offline":
			return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STATUS_ICONS, "offline_pending")
		"combat":
			return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.VFX, "victory_burst_gold")
		"rare_drop":
			var item_id := str(payload.get("item_id", "item_pack_rare_sheet"))
			return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.ITEM_ICONS, item_id)
		"realm":
			return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.SEALS, "burst_gold")
	return Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.SEALS, "ink_default")


func _subscribe_events() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		return
	bus.subscribe("level.changed", _on_level_changed)
	bus.subscribe("realm.advanced", _on_realm_advanced)
	bus.subscribe("combat.finished", _on_combat_finished)
	bus.subscribe("loot.rare_drop", _on_rare_drop)


func _on_level_changed(payload: Dictionary) -> void:
	push_typed_toast("level", tr("等级提升：Lv.%d") % int(payload.get("new_level", 1)), payload)


func _on_realm_advanced(payload: Dictionary) -> void:
	push_typed_toast("realm", tr("境界突破：%s") % tr(str(payload.get("new_realm", ""))), payload)


func _on_combat_finished(payload: Dictionary) -> void:
	if bool(payload.get("victory", false)):
		push_typed_toast("combat", tr("战斗胜利，掉落已结算"), payload)
		var loot: Dictionary = payload.get("loot", {})
		for reward in loot.get("rewards", []):
			if reward is Dictionary:
				_on_rare_drop(reward)


func _on_rare_drop(payload: Dictionary) -> void:
	var item_id := str(payload.get("item_id", payload.get("resource_id", "item_pack_rare_sheet")))
	push_typed_toast("rare_drop", tr("稀有掉落：%s") % tr(item_id), {"item_id": item_id, "rarity": str(payload.get("rarity", "epic"))})


func _on_toast_timeout(toast: PanelContainer) -> void:
	if not is_instance_valid(toast):
		return
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(toast.queue_free)
