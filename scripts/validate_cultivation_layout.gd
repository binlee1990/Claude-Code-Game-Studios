extends SceneTree


const SCREENSHOT_PATH := "res://production/qa/evidence/sprint-11/screenshots/cultivation_scale_135.png"


func _initialize() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1920, 1080)

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
	settings.set_window_size(Vector2i(1920, 1080), false)
	settings.set_ui_scale_multiplier(1.35, false)
	await _frames(8)

	ui_host.open_screen("cultivation")
	await _frames(8)

	var screen_container := root.find_child("ScreenContainer", true, false) as Control
	var apply_button := root.find_child("SimApplyBtn", true, false) as Button
	var inspection_scroll := root.find_child("InspectionScroll", true, false) as ScrollContainer
	if screen_container == null:
		failures.append("ScreenContainer missing")
	if apply_button == null:
		failures.append("SimApplyBtn missing")
	if inspection_scroll == null:
		failures.append("InspectionScroll missing")

	if screen_container != null and apply_button != null:
		var container_rect := screen_container.get_global_rect()
		var button_rect := apply_button.get_global_rect()
		print("CULTIVATION_LAYOUT container=%s apply=%s scale=%.2f size=%s" % [str(container_rect), str(button_rect), root.content_scale_factor, str(root.size)])
		if button_rect.position.y < container_rect.position.y - 0.5:
			failures.append("SimApplyBtn is above ScreenContainer: %s vs %s" % [str(button_rect), str(container_rect)])
		if button_rect.end.y > container_rect.end.y + 0.5:
			failures.append("SimApplyBtn is clipped below ScreenContainer: %s vs %s" % [str(button_rect), str(container_rect)])
		if button_rect.size.y <= 0.0:
			failures.append("SimApplyBtn has invalid height: %s" % str(button_rect))

	if not _capture(SCREENSHOT_PATH):
		failures.append("Cultivation layout screenshot failed")

	settings.set_ui_scale_multiplier(1.0, false)
	settings.set_window_size(Vector2i(1280, 720), false)
	settings.set_persistence_enabled(true)
	await _frames(2)

	if not failures.is_empty():
		_report(failures)
		return

	print("CULTIVATION_LAYOUT_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _capture(path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return false
	var image := viewport_texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return false
	return image.save_png(path) == OK and FileAccess.file_exists(path)


func _report(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)
