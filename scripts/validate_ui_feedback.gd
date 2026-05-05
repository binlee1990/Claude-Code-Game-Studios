extends SceneTree


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

	var ui_host := UIManagerHost.get_instance()
	if ui_host == null:
		failures.append("UIManagerHost missing")
		_report(failures)
		return

	ui_host.open_screen("cultivation")
	await _frames(8)

	var header := root.find_child("SimHeaderLabel", true, false) as Label
	var result := root.find_child("SimResultLabel", true, false) as RichTextLabel
	var apply_button := root.find_child("SimApplyBtn", true, false) as Button
	var feedback_layer := root.find_child("FeedbackLayer", true, false) as CanvasLayer
	if header == null or header.text != "姿态收益预览":
		failures.append("Simulation panel header should explain purpose")
	if result == null or result.text.find("预览") < 0 or result.text.find("拖动滑块查看试算结果") >= 0:
		failures.append("Simulation result should show a real preview, not the old placeholder")
	if apply_button == null or apply_button.text.find("切换到") < 0:
		failures.append("Simulation apply button should describe the target stance")
	if feedback_layer == null:
		failures.append("FeedbackLayer missing")

	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit("level.changed", {"entity_id": "player", "new_level": 2})
		await _frames(2)
		if root.find_child("MilestoneFeedback", true, false) == null:
			failures.append("Level changed event should create MilestoneFeedback")
	else:
		failures.append("EventBus missing")

	var manual_button := root.find_child("ManualBtn", true, false) as Button
	if manual_button != null:
		manual_button.pressed.emit()
		await _frames(2)
		if root.find_child("FloatingGain", true, false) == null:
			failures.append("Manual cultivation should show FloatingGain feedback")
	else:
		failures.append("ManualBtn missing")

	if not failures.is_empty():
		_report(failures)
		return

	print("UI_FEEDBACK_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _report(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)
