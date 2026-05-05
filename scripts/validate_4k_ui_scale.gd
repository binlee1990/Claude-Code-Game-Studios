extends SceneTree


const SCREENSHOT_PATH := "res://production/qa/evidence/sprint-11/screenshots/4k_ui_scale.png"


func _initialize() -> void:
	var failures: Array[String] = []
	var original_mode := DisplayServer.window_get_mode()
	var original_size := root.size
	root.size = Vector2i(3840, 2160)
	await process_frame

	var scale_settings := UIScaleSettings.get_instance()
	if scale_settings == null:
		failures.append("UIScaleSettings service unavailable")
	else:
		scale_settings.set_window_size(Vector2i(3840, 2160), false)
		scale_settings.set_ui_scale_multiplier(1.0, false)
		await _frames(2)

	var window := root
	if window.size != Vector2i(3840, 2160):
		failures.append("Expected 4K window size 3840x2160, got %s" % str(window.size))
	if window.content_scale_size != Vector2i(1280, 720):
		failures.append("Expected content_scale_size 1280x720, got %s" % str(window.content_scale_size))
	if not is_equal_approx(window.content_scale_factor, 1.0):
		failures.append("Expected content_scale_factor 1.0, got %.2f" % window.content_scale_factor)
	if window.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		failures.append("Expected canvas_items content scale mode")
	if window.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_EXPAND:
		failures.append("Expected expand content scale aspect")

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	await _frames(4)
	if window.content_scale_size != Vector2i(1280, 720):
		failures.append("Fullscreen should preserve 1280x720 logical canvas, got %s" % str(window.content_scale_size))
	if not is_equal_approx(window.content_scale_factor, 1.0):
		failures.append("Fullscreen expected content_scale_factor 1.0, got %.2f" % window.content_scale_factor)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(3840, 2160)
	await _frames(2)

	var scene := load("res://src/main/main.tscn") as PackedScene
	if scene == null:
		failures.append("main.tscn failed to load")
	else:
		var main := scene.instantiate()
		root.add_child(main)
		await _frames(8)
		var root_viewport := root.get_node_or_null("Main/RootViewport")
		if root_viewport == null:
			failures.append("RootViewport missing in 4K scale validation")
		var ui_host := UIManagerHost.get_instance()
		if ui_host != null and root_viewport != null:
			_unlock_ftue_for_full_navigation()
			ui_host.open_screen("combat")
		await _frames(8)
		var combat_screen := root.get_node_or_null("Main/RootViewport/UILayer/Shell/MainHBox/CenterContent/ScreenContainer/CombatScreen")
		if combat_screen == null or not combat_screen.visible:
			failures.append("Combat screen did not open through UIManagerHost at 4K scale")
		if not _capture(SCREENSHOT_PATH):
			failures.append("4K screenshot capture failed")

	if scale_settings != null:
		scale_settings.set_ui_scale_multiplier(1.25, false)
		await _frames(2)
		if window.content_scale_size != Vector2i(1280, 720):
			failures.append("125%% UI scale should preserve 1280x720 logical canvas, got %s" % str(window.content_scale_size))
		if not is_equal_approx(window.content_scale_factor, 1.25):
			failures.append("Expected 125%% UI scale to use content_scale_factor 1.25, got %.2f" % window.content_scale_factor)
		scale_settings.set_ui_scale_multiplier(1.0, false)
	DisplayServer.window_set_mode(original_mode)
	root.size = original_size

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("S11_4K_UI_SCALE_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _unlock_ftue_for_full_navigation() -> void:
	var ftue_host := FTUEStateMachineHost.get_instance()
	if ftue_host == null or ftue_host.get_service() == null:
		return
	ftue_host.get_service().advance_to(5)


func _capture(path: String) -> bool:
	if DisplayServer.get_name() == "headless":
		print("4K_SCREENSHOT_SKIPPED_HEADLESS")
		return true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return false
	var image := viewport_texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return false
	return image.save_png(path) == OK and FileAccess.file_exists(path)
