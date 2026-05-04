## ToastStack — P-FBK-01 floating notification stack.
##
## Anchored top-right. Each toast is a PanelContainer with a Label.
## Default 4s auto-dismiss. Max 4 visible toasts (oldest removed).
## New toasts slide in from right + fade in (200ms ease-out).
class_name ToastStack
extends VBoxContainer


const MAX_TOASTS := 4
const DEFAULT_DURATION: float = 4.0
const TOAST_HEIGHT: float = 48.0

var _toast_scene: PackedScene = null


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size = Vector2(320, 0)


## Push a new toast message onto the stack.
func push_toast(message: String, duration: float = DEFAULT_DURATION) -> void:
	# Remove oldest if at max.
	if get_child_count() >= MAX_TOASTS:
		var oldest := get_child(0)
		if oldest.has_method("dismiss"):
			oldest.dismiss()
		else:
			oldest.queue_free()

	var toast := _create_toast(message)
	add_child(toast)
	toast.show()
	# Auto-dismiss after duration.
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_on_toast_timeout.bind(toast))


func _create_toast(message: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Toast"
	panel.custom_minimum_size = Vector2(320, TOAST_HEIGHT)

	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("margin_left", 16)
	label.add_theme_constant_override("margin_right", 16)
	panel.add_child(label)

	# Animate in.
	var tween := panel.create_tween()
	tween.set_parallel(true)
	panel.modulate = Color(1, 1, 1, 0)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

	return panel


func _on_toast_timeout(toast: PanelContainer) -> void:
	if not is_instance_valid(toast):
		return
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(toast.queue_free)
