## ResourceProductionRow — P-DAT-01-EXP expandable resource row.
##
## Collapsed state: icon (24x24) + name (20px) + production rate (24px) + expand arrow.
## Expanded state: all of the above + breakdown rows showing base/stance/level/realm/modifier.
## Expand/collapse animation: tween height + content fade, 200ms ease-out.
class_name ResourceProductionRow
extends Control

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

const COLLAPSED_HEIGHT: float = 44.0
const ROW_HEIGHT: float = 28.0
const EXPAND_DURATION: float = 0.2

var resource_id: String = ""
var resource_label: String = ""
var icon_path: String = ""
var _expanded: bool = false
var _expand_tween: Tween = null

# Child references
var _icon_rect: TextureRect = null
var _name_label: Label = null
var _value_label: Label = null
var _rate_label: Label = null
var _cap_bar: ProgressBar = null
var _expand_indicator: Label = null
var _breakdown_container: VBoxContainer = null


func _init(p_id: String = "", p_label: String = "", p_icon: String = "") -> void:
	resource_id = p_id
	resource_label = p_label
	icon_path = p_icon


func _ready() -> void:
	_build_ui()
	custom_minimum_size.y = COLLAPSED_HEIGHT


func _build_ui() -> void:
	# Collapsed row
	var collapsed_row := HBoxContainer.new()
	collapsed_row.name = "CollapsedRow"
	collapsed_row.add_theme_constant_override("separation", 8)
	collapsed_row.alignment = BoxContainer.ALIGNMENT_CENTER

	# Icon
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.custom_minimum_size = Vector2(24, 24)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		_icon_rect.texture = load(icon_path) as Texture2D
	collapsed_row.add_child(_icon_rect)

	# Name
	_name_label = Label.new()
	_name_label.name = "Name"
	_name_label.text = tr(resource_label)
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collapsed_row.add_child(_name_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collapsed_row.add_child(spacer)

	# Current value
	_value_label = Label.new()
	_value_label.name = "Value"
	_value_label.text = "0"
	_value_label.add_theme_font_size_override("font_size", 18)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collapsed_row.add_child(_value_label)

	# Production rate
	_rate_label = Label.new()
	_rate_label.name = "Rate"
	_rate_label.text = "+0.0/s"
	_rate_label.add_theme_font_size_override("font_size", 24)
	_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collapsed_row.add_child(_rate_label)

	# Expand indicator
	_expand_indicator = Label.new()
	_expand_indicator.name = "ExpandArrow"
	_expand_indicator.text = ">"
	_expand_indicator.add_theme_font_size_override("font_size", 16)
	_expand_indicator.add_theme_color_override("font_color", Color(0.604, 0.580, 0.533))
	_expand_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collapsed_row.add_child(_expand_indicator)

	# Click area — a transparent button over the row
	var click_area := Button.new()
	click_area.name = "ClickArea"
	click_area.flat = true
	click_area.focus_mode = Control.FOCUS_ALL
	click_area.pressed.connect(_toggle_expand)
	# Make the button fill the row
	collapsed_row.add_child(click_area)
	click_area.mouse_filter = Control.MOUSE_FILTER_PASS

	add_child(collapsed_row)

	# Breakdown container (hidden when collapsed)
	_breakdown_container = VBoxContainer.new()
	_breakdown_container.name = "Breakdown"
	_breakdown_container.visible = false
	_breakdown_container.modulate = Color(1, 1, 1, 0)
	_breakdown_container.add_theme_constant_override("separation", 2)
	_breakdown_container.add_theme_constant_override("margin_left", 32)
	add_child(_breakdown_container)

	_cap_bar = ProgressBar.new()
	_cap_bar.name = "CapFill"
	_cap_bar.visible = false
	_cap_bar.max_value = 1.0
	_cap_bar.value = 0.0
	_cap_bar.custom_minimum_size = Vector2(0, 8)
	_breakdown_container.add_child(_cap_bar)

	# Initial layout
	_update_layout()


func _update_layout() -> void:
	var row_y := 4.0
	var collapsed := get_node_or_null("CollapsedRow") as HBoxContainer
	if collapsed:
		collapsed.position = Vector2(0, row_y)
		collapsed.size = Vector2(size.x, COLLAPSED_HEIGHT - 8)
		row_y += COLLAPSED_HEIGHT - 4

	if _breakdown_container:
		_breakdown_container.position = Vector2(0, row_y)
		_breakdown_container.size = Vector2(size.x, 0)


## Toggle expand/collapse with animation.
func _toggle_expand() -> void:
	_expanded = not _expanded
	if _expanded:
		_expand()
	else:
		_collapse()


func _expand() -> void:
	if _expand_tween != null:
		_expand_tween.kill()
	_expand_indicator.text = "v"
	_breakdown_container.visible = true

	var breakdown_count := _breakdown_container.get_child_count()
	var expanded_height := COLLAPSED_HEIGHT + (breakdown_count * ROW_HEIGHT) + 8.0

	if _is_reduced_motion():
		custom_minimum_size.y = expanded_height
		_breakdown_container.modulate = Color.WHITE
		return

	_expand_tween = create_tween().set_parallel(true)
	_expand_tween.tween_property(self, "custom_minimum_size:y", expanded_height, EXPAND_DURATION).set_ease(Tween.EASE_OUT)
	_expand_tween.tween_property(_breakdown_container, "modulate:a", 1.0, EXPAND_DURATION).set_ease(Tween.EASE_OUT)
	_expand_tween.tween_callback(_update_layout)


func _collapse() -> void:
	if _expand_tween != null:
		_expand_tween.kill()
	_expand_indicator.text = ">"

	if _is_reduced_motion():
		custom_minimum_size.y = COLLAPSED_HEIGHT
		_breakdown_container.modulate = Color(1, 1, 1, 0)
		_breakdown_container.visible = false
		return

	_expand_tween = create_tween().set_parallel(true)
	_expand_tween.tween_property(self, "custom_minimum_size:y", COLLAPSED_HEIGHT, EXPAND_DURATION).set_ease(Tween.EASE_OUT)
	_expand_tween.tween_property(_breakdown_container, "modulate:a", 0.0, EXPAND_DURATION).set_ease(Tween.EASE_OUT)
	_expand_tween.tween_callback(_on_collapse_complete)


func _on_collapse_complete() -> void:
	_breakdown_container.visible = false
	_update_layout()


## Set the production rate display.
func set_rate(rate_per_second: float) -> void:
	if _rate_label == null:
		return
	_rate_label.text = "%+.1f/s" % rate_per_second


func configure(p_id: String, p_label: String, p_icon: String) -> void:
	resource_id = p_id
	resource_label = p_label
	icon_path = p_icon
	if _name_label != null:
		_name_label.text = tr(resource_label)
	if _icon_rect != null:
		_icon_rect.texture = Sprint11AssetCatalog.texture(icon_path)


func set_value(value: BigNumber) -> void:
	if _value_label == null or value == null:
		return
	_value_label.text = NumberFormatter.format(value)


func set_capacity_state(state: Dictionary) -> void:
	if _cap_bar == null:
		return
	var fill_ratio := float(state.get("fill_ratio", 0.0))
	_cap_bar.visible = str(state.get("state", "")) != "uncapped"
	_cap_bar.value = clamp(fill_ratio, 0.0, 1.0)
	if fill_ratio >= 0.85:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.690, 0.251, 0.251)
		_cap_bar.add_theme_stylebox_override("fill", style)


## Set breakdown rows from OMS.get_breakdown() Dictionary.
func set_breakdown(breakdown: Dictionary) -> void:
	if _breakdown_container == null:
		return
	# Clear existing breakdown rows.
	for child in _breakdown_container.get_children():
		if child != _cap_bar:
			child.queue_free()

	var base_rate: float = breakdown.get("base_rate", 0.0)
	var pools: Dictionary = breakdown.get("pools", {})
	var final_multiplier: float = breakdown.get("final_multiplier", 1.0)
	var rate_per_second: float = breakdown.get("rate_per_second", 0.0)

	# Add breakdown rows.
	_add_breakdown_row(tr("基础产出"), "%.2f" % base_rate)
	for pool_name in pools.keys():
		var pool_val: float = pools[pool_name]
		if pool_val != 1.0:
			_add_breakdown_row(tr(pool_name), "x%.3f" % pool_val)
	_add_breakdown_row(tr("最终倍率"), "x%.3f" % final_multiplier)
	_add_breakdown_row(tr("每秒产出"), "%.2f" % rate_per_second, true)

	set_rate(rate_per_second)


func _add_breakdown_row(label_text: String, value_text: String, bold: bool = false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16 if not bold else 18)
	label.add_theme_color_override("font_color", Color(0.604, 0.580, 0.533))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18 if bold else 16)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	_breakdown_container.add_child(row)


func _is_reduced_motion() -> bool:
	return false
