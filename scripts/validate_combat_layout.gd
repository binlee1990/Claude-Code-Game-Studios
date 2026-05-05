extends SceneTree


const SCREENSHOT_PATH := "res://production/qa/evidence/sprint-11/screenshots/combat_scale_135.png"


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

	ui_host.open_screen("combat")
	await _frames(8)

	var screen_container := root.find_child("ScreenContainer", true, false) as Control
	var main_area := root.find_child("MainArea", true, false) as Control
	var control_bar := root.find_child("ControlBar", true, false) as Control
	var pause_button := root.find_child("PauseToggle", true, false) as Button
	var resolve_button := root.find_child("ResolveBtn", true, false) as Button
	var control_hbox := root.find_child("ControlBarHBox", true, false) as HBoxContainer
	var enemy_portrait := root.find_child("EnemyPortrait", true, false) as TextureRect
	var enemy_hp_bar := root.find_child("EnemyHPBar", true, false) as ProgressBar
	var enemy_name_label := root.find_child("EnemyNameLabel", true, false) as Label
	var player_hp_bar := root.find_child("PlayerHPBar", true, false) as ProgressBar
	var player_atk_label := root.find_child("PlayerATKLabel", true, false) as Label
	if screen_container == null:
		failures.append("ScreenContainer missing")
	if main_area == null:
		failures.append("MainArea missing")
	if control_bar == null:
		failures.append("ControlBar missing")
	if pause_button == null:
		failures.append("PauseToggle missing")
	if resolve_button == null:
		failures.append("ResolveBtn missing")
	if control_hbox == null:
		failures.append("ControlBarHBox missing")

	if screen_container != null and pause_button != null and resolve_button != null:
		var container_rect := screen_container.get_global_rect()
		var pause_rect := pause_button.get_global_rect()
		var resolve_rect := resolve_button.get_global_rect()
		print("COMBAT_LAYOUT container=%s pause=%s resolve=%s scale=%.2f size=%s" % [str(container_rect), str(pause_rect), str(resolve_rect), root.content_scale_factor, str(root.size)])
		if _rects_overlap(pause_rect, resolve_rect):
			failures.append("Combat bottom buttons overlap: %s vs %s" % [str(pause_rect), str(resolve_rect)])
		if pause_rect.end.y > container_rect.end.y + 0.5:
			failures.append("PauseToggle clipped below ScreenContainer: %s vs %s" % [str(pause_rect), str(container_rect)])
		if resolve_rect.end.y > container_rect.end.y + 0.5:
			failures.append("ResolveBtn clipped below ScreenContainer: %s vs %s" % [str(resolve_rect), str(container_rect)])
		if pause_rect.size.x <= 0.0 or resolve_rect.size.x <= 0.0:
			failures.append("Combat bottom buttons have invalid width")

	if screen_container != null and main_area != null and control_bar != null:
		var main_rect := main_area.get_global_rect()
		var control_rect := control_bar.get_global_rect()
		print("COMBAT_CONTENT main=%s control=%s" % [str(main_rect), str(control_rect)])
		if main_rect.end.y > control_rect.position.y + 0.5:
			failures.append("MainArea overlaps ControlBar: %s vs %s" % [str(main_rect), str(control_rect)])
		_assert_above_control(enemy_portrait, "EnemyPortrait", control_rect, failures)
		_assert_above_control(enemy_hp_bar, "EnemyHPBar", control_rect, failures)
		_assert_above_control(enemy_name_label, "EnemyNameLabel", control_rect, failures)
		_assert_above_control(player_hp_bar, "PlayerHPBar", control_rect, failures)
		_assert_above_control(player_atk_label, "PlayerATKLabel", control_rect, failures)

	if not _capture(SCREENSHOT_PATH):
		failures.append("Combat layout screenshot failed")

	settings.set_ui_scale_multiplier(1.0, false)
	settings.set_window_size(Vector2i(1280, 720), false)
	settings.set_persistence_enabled(true)
	await _frames(2)

	if not failures.is_empty():
		_report(failures)
		return

	print("COMBAT_LAYOUT_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y


func _assert_above_control(node: Control, label: String, control_rect: Rect2, failures: Array[String]) -> void:
	if node == null:
		failures.append("%s missing" % label)
		return
	var rect := node.get_global_rect()
	print("COMBAT_NODE %s=%s" % [label, str(rect)])
	if rect.end.y > control_rect.position.y - 1.0:
		failures.append("%s overlaps ControlBar: %s vs %s" % [label, str(rect), str(control_rect)])


func _capture(path: String) -> bool:
	if DisplayServer.get_name() == "headless":
		print("COMBAT_SCREENSHOT_SKIPPED_HEADLESS")
		return true
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
