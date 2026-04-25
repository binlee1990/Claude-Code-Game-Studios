class_name InkBackdrop
extends Control

const SRPGTheme := preload("res://src/ui/theme/srpg_theme.gd")

@export var intensity: float = 1.0
@export var show_moon: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, SRPGTheme.INK)
	draw_rect(rect, Color(0.145, 0.038, 0.034, 0.18 * intensity))

	var paper_alpha := 0.050 * intensity
	for i in range(8):
		var y := size.y * (0.12 + float(i) * 0.11)
		draw_line(Vector2(0.0, y), Vector2(size.x, y + sin(float(i)) * 10.0), Color(SRPGTheme.PAPER.r, SRPGTheme.PAPER.g, SRPGTheme.PAPER.b, paper_alpha), 1.0)

	var seal_center := Vector2(size.x * 0.115, size.y * 0.225)
	draw_circle(seal_center, minf(size.x, size.y) * 0.085, Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, 0.18 * intensity))
	draw_arc(seal_center, minf(size.x, size.y) * 0.092, 0.2, TAU - 0.4, 72, Color(SRPGTheme.GOLD.r, SRPGTheme.GOLD.g, SRPGTheme.GOLD.b, 0.26 * intensity), 2.0)

	if show_moon:
		var moon_center := Vector2(size.x * 0.800, size.y * 0.185)
		draw_circle(moon_center, minf(size.x, size.y) * 0.058, Color(SRPGTheme.PAPER.r, SRPGTheme.PAPER.g, SRPGTheme.PAPER.b, 0.70 * intensity))
		draw_circle(moon_center + Vector2(11.0, -4.0), minf(size.x, size.y) * 0.060, Color(SRPGTheme.INK.r, SRPGTheme.INK.g, SRPGTheme.INK.b, 0.92))

	var stroke_color := Color(SRPGTheme.CYAN.r, SRPGTheme.CYAN.g, SRPGTheme.CYAN.b, 0.18 * intensity)
	_draw_breath_line(size.y * 0.56, stroke_color, 2.0)
	_draw_breath_line(size.y * 0.66, Color(SRPGTheme.GOLD.r, SRPGTheme.GOLD.g, SRPGTheme.GOLD.b, 0.12 * intensity), 1.0)
	_draw_blade_line(Vector2(size.x * 0.085, size.y * 0.785), Vector2(size.x * 0.470, size.y * 0.305), Color(SRPGTheme.PAPER.r, SRPGTheme.PAPER.g, SRPGTheme.PAPER.b, 0.15 * intensity), 2.0)

func _draw_breath_line(y_base: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	for i in range(7):
		var t := float(i) / 6.0
		points.append(Vector2(size.x * (0.18 + t * 0.68), y_base + sin(t * PI * 1.7) * 34.0))
	draw_polyline(points, color, width, true)

func _draw_blade_line(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	draw_line(from_point, to_point, color, width, true)
	draw_line(from_point + Vector2(14.0, 18.0), to_point + Vector2(42.0, -8.0), Color(SRPGTheme.VERMILION.r, SRPGTheme.VERMILION.g, SRPGTheme.VERMILION.b, color.a * 0.78), 1.0, true)
