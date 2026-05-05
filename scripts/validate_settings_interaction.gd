extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var scene := load("res://src/main/main.tscn") as PackedScene
	if scene == null:
		push_error("main.tscn failed to load")
		quit(1)
		return

	var main := scene.instantiate()
	root.add_child(main)
	await _frames(8)

	var settings := UIScaleSettings.get_instance()
	var ui_host := UIManagerHost.get_instance()
	if settings == null:
		failures.append("UIScaleSettings missing")
	if ui_host == null:
		failures.append("UIManagerHost missing")
	if not failures.is_empty():
		_report(failures)
		return

	settings.set_persistence_enabled(false)
	settings.set_window_size(Vector2i(1280, 720), false)
	settings.set_ui_scale_multiplier(1.0, false)
	await _frames(4)
	print("BEFORE size=%s scale_size=%s ui_scale=%.2f" % [str(root.size), str(root.content_scale_size), settings.get_ui_scale_multiplier()])

	ui_host.open_modal("settings")
	await _frames(4)
	var resolution_option := root.find_child("ResolutionOption", true, false) as OptionButton
	var slider := root.find_child("UIScaleSlider", true, false) as HSlider
	var apply_button := root.find_child("ApplySettingsButton", true, false) as Button
	var confirm_button := root.find_child("ConfirmSettingsButton", true, false) as Button
	if resolution_option == null:
		failures.append("ResolutionOption missing after opening settings")
	if slider == null:
		failures.append("UIScaleSlider missing after opening settings")
	if apply_button == null:
		failures.append("ApplySettingsButton missing after opening settings")
	if confirm_button == null:
		failures.append("ConfirmSettingsButton missing after opening settings")
	if not failures.is_empty():
		_report(failures)
		return

	resolution_option.select(1)
	resolution_option.item_selected.emit(1)
	slider.value = 1.35
	await _frames(2)
	print("PENDING size=%s scale_size=%s selected=%d stored=%s ui_scale=%.2f slider=%.2f" % [str(root.size), str(root.content_scale_size), resolution_option.selected, str(settings.get_window_size()), settings.get_ui_scale_multiplier(), slider.value])
	if root.size != Vector2i(1280, 720):
		failures.append("Settings changed resolution before confirmation")
	if not is_equal_approx(settings.get_ui_scale_multiplier(), 1.0):
		failures.append("Settings changed UI scale before confirmation")

	apply_button.pressed.emit()
	await _frames(8)
	print("AFTER_APPLY size=%s scale_size=%s scale_factor=%.2f stored=%s ui_scale=%.2f modal_open=%s" % [str(root.size), str(root.content_scale_size), root.content_scale_factor, str(settings.get_window_size()), settings.get_ui_scale_multiplier(), str(UIManagerHost.has_open_modal())])
	if root.size != Vector2i(1920, 1080):
		failures.append("Apply expected 1920x1080, got %s" % str(root.size))
	if not is_equal_approx(settings.get_ui_scale_multiplier(), 1.35):
		failures.append("Apply expected UI scale 1.35, got %.2f" % settings.get_ui_scale_multiplier())
	if root.content_scale_size != Vector2i(1280, 720):
		failures.append("Apply should preserve 1280x720 logical canvas, got %s" % str(root.content_scale_size))
	if not is_equal_approx(root.content_scale_factor, 1.35):
		failures.append("Apply expected content_scale_factor 1.35, got %.2f" % root.content_scale_factor)
	if not UIManagerHost.has_open_modal():
		failures.append("Apply should keep settings modal open")

	confirm_button.pressed.emit()
	await _frames(4)
	if UIManagerHost.has_open_modal():
		failures.append("Confirm should close settings modal")

	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		await _frames(4)
		ui_host.open_modal("settings")
		await _frames(4)
		resolution_option = root.find_child("ResolutionOption", true, false) as OptionButton
		apply_button = root.find_child("ApplySettingsButton", true, false) as Button
		if resolution_option == null or apply_button == null:
			failures.append("Settings controls missing for fullscreen resolution validation")
		else:
			resolution_option.select(2)
			apply_button.pressed.emit()
			await _frames(8)
			print("AFTER_FULLSCREEN_APPLY mode=%d size=%s stored=%s" % [DisplayServer.window_get_mode(), str(root.size), str(settings.get_window_size())])
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
				failures.append("Resolution Apply should leave fullscreen and return to windowed mode")
			if root.size != Vector2i(2560, 1440):
				failures.append("Fullscreen Apply expected window size 2560x1440, got %s" % str(root.size))
			if settings.get_window_size() != Vector2i(2560, 1440):
				failures.append("Fullscreen Apply expected stored resolution 2560x1440, got %s" % str(settings.get_window_size()))
		if UIManagerHost.has_open_modal():
			ui_host.close_modal()
		await _frames(2)

	settings.set_window_size(Vector2i(1280, 720), false)
	settings.set_ui_scale_multiplier(1.0, false)
	settings.set_persistence_enabled(true)
	await _frames(2)

	if not failures.is_empty():
		_report(failures)
		return

	print("SETTINGS_INTERACTION_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _report(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)
