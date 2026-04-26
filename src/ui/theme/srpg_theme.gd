class_name SRPGTheme
extends RefCounted

const INK := Color(0.045, 0.044, 0.050)
const INK_SOFT := Color(0.075, 0.071, 0.078)
const INK_PANEL := Color(0.105, 0.096, 0.095, 0.94)
const PAPER := Color(0.890, 0.835, 0.710)
const PAPER_MUTED := Color(0.670, 0.610, 0.490)
const VERMILION := Color(0.780, 0.125, 0.105)
const VERMILION_DARK := Color(0.420, 0.055, 0.050)
const GOLD := Color(0.890, 0.690, 0.330)
const JADE := Color(0.255, 0.620, 0.520)
const CYAN := Color(0.420, 0.700, 0.780)
const WHITE := Color(0.960, 0.930, 0.840)
const DISABLED_TEXT := Color(0.440, 0.400, 0.340)

const TITLE_FONT := preload("res://assets/fonts/zcool_xiaowei.ttf")
const BODY_FONT := preload("res://assets/fonts/noto_serif_sc.otf")

static func panel(bg: Color = INK_PANEL, border: Color = GOLD, radius: int = 6, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0.0, 3.0)
	style.set_content_margin(SIDE_LEFT, 12.0)
	style.set_content_margin(SIDE_TOP, 10.0)
	style.set_content_margin(SIDE_RIGHT, 12.0)
	style.set_content_margin(SIDE_BOTTOM, 10.0)
	return style

static func button_style(bg: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var style := panel(bg, border, radius, 1)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	return style

static func apply_button(button: Button, accent: bool = false, danger: bool = false, compact: bool = false) -> void:
	var base_bg := Color(0.145, 0.130, 0.118, 0.98)
	var hover_bg := Color(0.205, 0.180, 0.145, 0.98)
	var pressed_bg := Color(0.100, 0.090, 0.088, 0.98)
	var border := Color(GOLD.r, GOLD.g, GOLD.b, 0.58)
	var text := PAPER
	if accent:
		base_bg = Color(0.470, 0.065, 0.055, 0.98)
		hover_bg = Color(0.620, 0.095, 0.075, 0.98)
		pressed_bg = Color(0.320, 0.046, 0.040, 0.98)
		border = Color(GOLD.r, GOLD.g, GOLD.b, 0.85)
		text = WHITE
	elif danger:
		base_bg = Color(0.095, 0.080, 0.075, 0.98)
		hover_bg = Color(0.320, 0.060, 0.052, 0.98)
		pressed_bg = Color(0.180, 0.038, 0.035, 0.98)
		border = Color(VERMILION.r, VERMILION.g, VERMILION.b, 0.72)

	button.add_theme_stylebox_override("normal", button_style(base_bg, border))
	button.add_theme_stylebox_override("hover", button_style(hover_bg, Color(GOLD.r, GOLD.g, GOLD.b, 0.95)))
	button.add_theme_stylebox_override("pressed", button_style(pressed_bg, border))
	button.add_theme_stylebox_override("focus", button_style(Color(base_bg.r, base_bg.g, base_bg.b, 0.72), GOLD))
	button.add_theme_stylebox_override("disabled", button_style(Color(0.085, 0.078, 0.075, 0.82), Color(0.220, 0.200, 0.165, 0.74)))
	button.add_theme_color_override("font_color", text)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	button.add_theme_font_size_override("font_size", 15 if compact else 18)
	button.add_theme_font_override("font", BODY_FONT)
	button.custom_minimum_size = Vector2(96.0, 34.0 if compact else 44.0)

static func scale_size(value: float, scale: float) -> float:
	var safe_scale: float = maxf(scale, 0.1)
	return float(int(round(value * safe_scale)))

static func scale_font_size(size: int, scale: float) -> int:
	var safe_scale: float = maxf(scale, 0.1)
	return maxi(1, int(round(float(size) * safe_scale)))

static func apply_button_scaled(button: Button, scale: float, accent: bool = false, danger: bool = false, compact: bool = false) -> void:
	apply_button(button, accent, danger, compact)
	button.add_theme_font_size_override("font_size", scale_font_size(15 if compact else 18, scale))
	button.custom_minimum_size = Vector2(
		scale_size(96.0, scale),
		scale_size(34.0 if compact else 44.0, scale)
	)

static func apply_label(label: Label, color: Color = PAPER, size: int = 16, is_title: bool = false) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_font_override("font", TITLE_FONT if is_title else BODY_FONT)

static func apply_label_scaled(label: Label, scale: float, color: Color = PAPER, size: int = 16, is_title: bool = false) -> void:
	apply_label(label, color, scale_font_size(size, scale), is_title)

static func apply_panel(panel_node: Control, bg: Color = INK_PANEL, border: Color = GOLD) -> void:
	panel_node.add_theme_stylebox_override("panel", panel(bg, Color(border.r, border.g, border.b, 0.68)))

static func apply_hp_bar(bar: ProgressBar, is_player: bool) -> void:
	bar.add_theme_stylebox_override("background", button_style(Color(0.055, 0.052, 0.050, 0.94), Color(0.220, 0.190, 0.145, 0.80), 2))
	var fill_color := JADE if is_player else VERMILION
	bar.add_theme_stylebox_override("fill", button_style(fill_color, Color(fill_color.r, fill_color.g, fill_color.b, 0.92), 2))
