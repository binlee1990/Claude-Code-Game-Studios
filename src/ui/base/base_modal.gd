## BaseModal — common lifecycle and input gate for all modal popups.
##
## Modal scenes extend this class. UIManagerHost manages the modal stack
## and calls open(payload) / close(). The modal_input_blocker ColorRect on
## ModalLayer (CanvasLayer 2) prevents clicks/hover from reaching lower layers.
##
## Default animation: scale 95%→100% + fade-in 200ms ease-out.
## Close: scale 100%→95% + fade-out 150ms ease-in.
## ESC / Gamepad B triggers close via _input override.
class_name BaseModal
extends PopupPanel


## Payload passed by UIManagerHost.open_modal().
var payload: Dictionary = {}

## Tween instance for open/close animations. Null if no animation is running.
var _modal_tween: Tween = null


func _ready() -> void:
	_popup_configure()
	_setup_input()


## Configure PopupPanel properties: exclusive, no click-outside-close.
func _popup_configure() -> void:
	popup_exclusive = true
	# Prevent closing by clicking outside (modal must be explicitly dismissed).
	popup_window = false


## Set up input handling — ESC and Gamepad B close the modal.
func _setup_input() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_modal()
		get_viewport().set_input_as_handled()


## Open the modal with optional payload and animation.
func open(payload_data: Dictionary = {}) -> void:
	payload = payload_data
	show()
	_animate_open()


## Close the modal with animation, then hide and free.
func close() -> void:
	_animate_close()
	# Hiding and cleanup happen after the close animation completes.


## Internal close triggered by ESC/B — calls UIManagerHost.close_modal().
func _close_modal() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.close_modal()


func _animate_open() -> void:
	if _modal_tween != null:
		_modal_tween.kill()
	if _is_reduced_motion():
		modulate = Color.WHITE
		scale = Vector2.ONE
		return
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.95, 0.95)
	_modal_tween = create_tween().set_parallel(true)
	_modal_tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	_modal_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)


func _animate_close() -> void:
	if _modal_tween != null:
		_modal_tween.kill()
	if _is_reduced_motion():
		modulate = Color.WHITE
		hide()
		return
	_modal_tween = create_tween().set_parallel(true)
	_modal_tween.tween_property(self, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	_modal_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.15).set_ease(Tween.EASE_IN)
	_modal_tween.tween_callback(hide)


func _is_reduced_motion() -> bool:
	# When SettingsSystem is available:
	#   var settings := SettingsSystemHost.get_instance()
	#   if settings != null: return settings.get_service().reduce_motion
	return false
