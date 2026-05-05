extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	var main_scene := load("res://src/main/main.tscn") as PackedScene
	if main_scene == null:
		push_error("main.tscn failed to load")
		quit(1)
		return

	var main := main_scene.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame
	await process_frame

	var root_viewport := root.get_node_or_null("Main/RootViewport")
	if root_viewport == null:
		failures.append("Main/RootViewport is missing after instantiation")
	else:
		for path in [
			"UILayer/Shell/TopStrip",
			"UILayer/Shell/MainHBox/LeftNav",
			"UILayer/Shell/MainHBox/CenterContent/ScreenContainer",
			"UILayer/Shell/MainHBox/RightPanel",
			"ToastLayer/ToastStack",
			"ModalLayer/ModalContainer",
		]:
			if root_viewport.get_node_or_null(path) == null:
				failures.append("RootViewport missing node: %s" % path)

	var ui_host := UIManagerHost.get_instance()
	if ui_host == null:
		failures.append("UIManagerHost autoload is unavailable")
	else:
		var service := ui_host.get_service()
		if service == null:
			failures.append("UIManagerHost service is unavailable")
		elif service.active_screen_id != "cultivation":
			failures.append("Expected default screen 'cultivation', got '%s'" % service.active_screen_id)
		else:
			for screen_id in ["combat", "resources", "save", "offline_settlement", "cultivation"]:
				ui_host.open_screen(screen_id)
				await process_frame
				await process_frame
				if service.active_screen_id != screen_id:
					failures.append("Expected active screen '%s', got '%s'" % [screen_id, service.active_screen_id])
				if service.get_screen_instance(screen_id) == null:
					failures.append("Screen '%s' did not instantiate" % screen_id)
				if screen_id == "cultivation":
					await _validate_cultivation_layout(failures)

			var modal_payloads := {
				"settings": {},
				"stance_select": {},
				"confirm_critical": {
					"title": "验证",
					"consequences": ["验证 modal 可加载"],
					"confirm_label": "确认",
				},
			}
			for modal_id in ["settings", "stance_select", "confirm_critical"]:
				ui_host.open_modal(modal_id, modal_payloads[modal_id])
				await process_frame
				if not service.has_open_modal():
					failures.append("Modal '%s' did not open" % modal_id)
				if modal_id == "settings":
					await _validate_settings_controls(failures)
				ui_host.close_modal()
				await process_frame
				if service.has_open_modal():
					failures.append("Modal '%s' did not close cleanly" % modal_id)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("MAIN_SCENE_LOAD_OK")
	quit(0)


func _validate_settings_controls(failures: Array[String]) -> void:
	var scale_settings := UIScaleSettings.get_instance()
	if scale_settings == null:
		failures.append("UIScaleSettings autoload is unavailable")
		return

	var resolution_option := root.find_child("ResolutionOption", true, false) as OptionButton
	var slider := root.find_child("UIScaleSlider", true, false) as HSlider
	var value_label := root.find_child("UIScaleValueLabel", true, false) as Label
	var confirm_button := root.find_child("ConfirmSettingsButton", true, false) as Button
	if resolution_option == null:
		failures.append("Settings modal is missing ResolutionOption")
		return
	if slider == null:
		failures.append("Settings modal is missing UIScaleSlider")
		return
	if value_label == null:
		failures.append("Settings modal is missing UIScaleValueLabel")
		return
	if confirm_button == null:
		failures.append("Settings modal is missing ConfirmSettingsButton")
		return

	var original_persistence := scale_settings.is_persistence_enabled()
	scale_settings.set_persistence_enabled(false)
	var original_size := root.size
	var original_scale := scale_settings.get_ui_scale_multiplier()
	resolution_option.select(0)
	resolution_option.item_selected.emit(0)
	slider.value = 1.25
	await process_frame
	if root.size == Vector2i(1280, 720) and original_size != Vector2i(1280, 720):
		failures.append("Settings controls applied before confirmation")
	if value_label.text != "125%":
		failures.append("UI scale label expected pending 125%%, got '%s'" % value_label.text)

	confirm_button.pressed.emit()
	await process_frame
	if scale_settings.get_window_size() != Vector2i(1280, 720):
		failures.append("Resolution option did not apply 1280x720 setting")
	if root.size != Vector2i(1280, 720):
		failures.append("Resolution option expected window size 1280x720, got %s" % str(root.size))
	if not is_equal_approx(scale_settings.get_ui_scale_multiplier(), 1.25):
		failures.append("UI scale slider did not apply 125%% scale")
	if root.content_scale_size != Vector2i(1280, 720):
		failures.append("UI scale should preserve 1280x720 logical canvas, got %s" % str(root.content_scale_size))
	if not is_equal_approx(root.content_scale_factor, 1.25):
		failures.append("UI scale slider expected content_scale_factor 1.25, got %.2f" % root.content_scale_factor)

	scale_settings.set_ui_scale_multiplier(original_scale, false)
	scale_settings.set_window_size(original_size, false)
	scale_settings.set_persistence_enabled(original_persistence)
	await process_frame


func _validate_cultivation_layout(failures: Array[String]) -> void:
	var screen_container := root.find_child("ScreenContainer", true, false) as Control
	var apply_button := root.find_child("SimApplyBtn", true, false) as Button
	var inspection_scroll := root.find_child("InspectionScroll", true, false) as ScrollContainer
	if screen_container == null:
		failures.append("Cultivation layout missing ScreenContainer")
		return
	if apply_button == null:
		failures.append("Cultivation layout missing SimApplyBtn")
		return
	if inspection_scroll == null:
		failures.append("Cultivation layout missing InspectionScroll")
		return
	await process_frame
	var container_rect := screen_container.get_global_rect()
	var button_rect := apply_button.get_global_rect()
	if button_rect.end.y > container_rect.end.y + 0.5:
		failures.append("Cultivation SimApplyBtn clipped below ScreenContainer: %s vs %s" % [str(button_rect), str(container_rect)])
