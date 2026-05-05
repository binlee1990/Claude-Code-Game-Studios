## ItemCard — P-DAT-04 item card for inventory grids.
##
## Displays item icon (48x48) + rarity frame (8 tiers, per art-bible Sec 4.3) +
## item name + stack count badge. Supports grid (96x128) and detail (320x420)
## sizes via set_detail_mode(). Colorblind-safe: rarity encoded as border width +
## shape + text badge, not just color.
class_name ItemCard
extends PanelContainer

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

enum CardSize { GRID, DETAIL }

const RARITY_COLORS: Dictionary = {
	"common":    Color(0.58, 0.58, 0.58),      # 凡 — grey
	"uncommon":  Color(0.18, 0.80, 0.44),      # 精 — green
	"rare":      Color(0.20, 0.60, 0.86),      # 稀 — blue
	"epic":       Color(0.64, 0.20, 0.79),      # 史 — purple
	"legendary":  Color(0.96, 0.78, 0.26),      # 传 — gold
	"mythic":     Color(0.96, 0.40, 0.16),      # 神 — orange
	"innate":     Color(0.86, 0.70, 0.20),      # 先 — gold
	"primordial": Color(0.86, 0.08, 0.24),      # 先 — crimson
	"chaos":      Color(0.06, 0.06, 0.12),      # 混 — void
}

const RARITY_BORDER_WIDTH: Dictionary = {
	"common": 1, "uncommon": 1, "rare": 2, "epic": 2,
	"legendary": 3, "mythic": 3, "innate": 4, "primordial": 4, "chaos": 4,
}

const RARITY_NAMES: Dictionary = {
	"common": "凡", "uncommon": "精", "rare": "稀", "epic": "史",
	"legendary": "传", "mythic": "神", "innate": "先", "primordial": "先", "chaos": "混",
}

var _card_size: CardSize = CardSize.GRID
var _icon_rect: TextureRect = null
var _name_label: Label = null
var _count_badge: Label = null
var _rarity_badge: Label = null
var _pending_item_data: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(96, 128)


func _ready() -> void:
	_build_card()


func _build_card() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)

	# Icon container with rarity border
	var icon_container := PanelContainer.new()
	icon_container.name = "IconContainer"
	icon_container.custom_minimum_size = Vector2(64, 64) if _card_size == CardSize.GRID else Vector2(128, 128)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = Vector2(48, 48) if _card_size == CardSize.GRID else Vector2(96, 96)
	icon_container.add_child(_icon_rect)

	# Rarity badge (text overlay, top-right corner)
	_rarity_badge = Label.new()
	_rarity_badge.name = "RarityBadge"
	_rarity_badge.add_theme_font_size_override("font_size", 10 if _card_size == CardSize.GRID else 14)
	_rarity_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	icon_container.add_child(_rarity_badge)

	vbox.add_child(icon_container)

	# Name label
	_name_label = Label.new()
	_name_label.name = "Name"
	_name_label.add_theme_font_size_override("font_size", 14 if _card_size == CardSize.GRID else 18)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.clip_text = true
	vbox.add_child(_name_label)

	# Count badge
	_count_badge = Label.new()
	_count_badge.name = "Count"
	_count_badge.add_theme_font_size_override("font_size", 12 if _card_size == CardSize.GRID else 16)
	_count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_badge.visible = false
	vbox.add_child(_count_badge)

	add_child(vbox)
	if not _pending_item_data.is_empty():
		_apply_item_data(_pending_item_data)


## Set the item data on this card.
func set_item(item_data: Dictionary) -> void:
	_pending_item_data = item_data.duplicate(true)
	if _icon_rect == null or _name_label == null:
		return
	_apply_item_data(_pending_item_data)


func _apply_item_data(item_data: Dictionary) -> void:
	var rarity: String = item_data.get("rarity", "common")
	if rarity == "primordial":
		rarity = "innate"
	var icon_path: String = item_data.get("icon_path", "")
	var item_name: String = item_data.get("name", "?")
	var count: int = item_data.get("count", 0)

	# Icon
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		_icon_rect.texture = load(icon_path) as Texture2D

	# Name
	_name_label.text = tr(item_name)

	# Count badge
	if count > 1:
		_count_badge.text = "x%d" % count
		_count_badge.visible = true
	else:
		_count_badge.visible = false

	# Rarity frame
	_apply_rarity(rarity)


func _apply_rarity(rarity: String) -> void:
	if rarity == "primordial":
		rarity = "innate"
	var col: Color = RARITY_COLORS.get(rarity, Color(0.58, 0.58, 0.58))
	var border_w: int = RARITY_BORDER_WIDTH.get(rarity, 1)
	var rarity_text: String = RARITY_NAMES.get(rarity, "?")

	var frame_texture := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.RARITY_FRAMES, rarity)
	if frame_texture != null:
		var texture_style := StyleBoxTexture.new()
		texture_style.texture = frame_texture
		texture_style.texture_margin_left = 10
		texture_style.texture_margin_top = 10
		texture_style.texture_margin_right = 10
		texture_style.texture_margin_bottom = 10
		add_theme_stylebox_override("panel", texture_style)
	else:
		var style := StyleBoxFlat.new()
		style.set_border_width_all(border_w)
		style.border_color = col
		style.bg_color = Color(0, 0, 0, 0.15)
		add_theme_stylebox_override("panel", style)

	# Rarity badge (text — colorblind backup)
	_rarity_badge.text = rarity_text
	_rarity_badge.add_theme_color_override("font_color", col)


## Swap between grid (96x128) and detail (320x420) sizes.
func set_detail_mode(detail: bool) -> void:
	_card_size = CardSize.DETAIL if detail else CardSize.GRID
	custom_minimum_size = Vector2(320, 420) if detail else Vector2(96, 128)
	# Rebuild children on next ready.
	if is_inside_tree():
		for child in get_children():
			child.queue_free()
		_build_card()
