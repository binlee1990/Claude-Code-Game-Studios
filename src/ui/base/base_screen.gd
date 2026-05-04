## BaseScreen — common lifecycle for all screen scenes.
##
## All 5 MVP screen scenes extend this class. UIManagerHost calls
## on_activated() / on_deactivated() / on_removed() at the appropriate
## lifecycle points. Screens override these to subscribe/unsubscribe
## EventBus events and manage initial focus.
##
## Screens use show/hide + PROCESS_MODE_DISABLED for switching — they
## are never removed from the tree unless replace_screen() is called.
class_name BaseScreen
extends Control


## Called by UIManagerHost when this screen becomes the active screen.
## Subscribe to EventBus events here and set initial focus.
func on_activated() -> void:
	pass


## Called by UIManagerHost when this screen becomes inactive (hidden).
## Unsubscribe from real-time EventBus events here to prevent hidden
## screens from doing unnecessary layout work.
func on_deactivated() -> void:
	pass


## Called by UIManagerHost when this screen is about to be removed from
## the tree (replace_screen). Free any pooled resources here.
func on_removed() -> void:
	pass


## Convenience: subscribe to an EventBus event with automatic guard.
func _subscribe(event_name: String, callback: Callable) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.subscribe(event_name, callback)


## Convenience: unsubscribe from an EventBus event.
func _unsubscribe(event_name: String, callback: Callable) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.unsubscribe(event_name, callback)


## Convenience: emit an event through EventBus.
func _emit(event_name: String, payload: Dictionary = {}) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)


## Convenience: load a texture, returning null if path is missing.
func _try_load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("BaseScreen: missing texture %s" % path)
		return null
	return load(path) as Texture2D


## Check if reduced motion is enabled via SettingsSystem.
## Returns false if SettingsSystem is not yet available (assume full animation).
func _is_reduced_motion() -> bool:
	# SettingsSystem is not yet wired — default to false.
	# When SettingsSystem is available, use:
	#   var settings := SettingsSystemHost.get_instance()
	#   if settings != null: return settings.get_service().reduce_motion
	return false
