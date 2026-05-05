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
	await _frames(8)

	var bus := EventBus.get_instance()
	var ftue_host := FTUEStateMachineHost.get_instance()
	var ui_host := UIManagerHost.get_instance()
	if bus == null:
		failures.append("EventBus autoload is unavailable")
	if ftue_host == null or ftue_host.get_service() == null:
		failures.append("FTUEStateMachineHost autoload/service is unavailable")
	if ui_host == null or ui_host.get_service() == null:
		failures.append("UIManagerHost autoload/service is unavailable")
	if not failures.is_empty():
		_report(failures)
		return

	var ftue := ftue_host.get_service()
	var ui := ui_host.get_service()
	_expect_stage(ftue, 0, "cold start", failures)
	_expect_screen(ui, "cultivation", "default screen", failures)

	if ui.is_screen_unlocked("combat"):
		failures.append("combat should be locked at FTUE stage 0")
	_expect_screen(ui, "cultivation", "combat remains locked at stage 0", failures)

	bus.emit("resource.lingqi.changed", {"resource_id": "lingqi", "new_value": BigNumber.from_int(100)})
	await _frames(2)
	_expect_stage(ftue, 1, "lingqi threshold unlocks combat", failures)
	ui_host.open_screen("combat")
	await _frames(4)
	_expect_screen(ui, "combat", "combat opens at stage 1", failures)

	bus.emit("combat.finished", {"victory": true, "enemy_id": "golem_stone", "zone_id": "zone_starter"})
	await _frames(2)
	_expect_stage(ftue, 2, "first combat advances to resources", failures)
	ui_host.open_screen("resources")
	await _frames(4)
	_expect_screen(ui, "resources", "resources opens at stage 2", failures)

	bus.emit("zone.unlocked", {"zone_id": "zone_forest"})
	await _frames(2)
	_expect_stage(ftue, 3, "zone unlock advances awareness", failures)

	bus.emit("realm.advanced", {"entity_id": "player", "old_realm": "fanren", "new_realm": "lianqi"})
	await _frames(2)
	_expect_stage(ftue, 4, "realm breakthrough advances ceremony", failures)
	ui_host.open_modal("stance_select")
	await _frames(4)
	if not ui.has_open_modal():
		failures.append("stance_select modal should open at FTUE stage 4")
	ui_host.close_modal()
	await _frames(2)

	bus.emit("offline.settled", {"id": "draft_s12", "duration": 3600.0, "claimed": {"lingshi": BigNumber.from_int(10).to_dict()}})
	await _frames(2)
	_expect_stage(ftue, 5, "offline settlement completes FTUE", failures)
	ui_host.open_screen("offline_settlement")
	await _frames(4)
	_expect_screen(ui, "offline_settlement", "offline settlement opens at stage 5", failures)

	var snapshot: Dictionary = ftue.collect_state()
	var restored := FTUEStateMachine.new()
	restored.restore_state(snapshot)
	if restored.get_stage() != 5 or not restored.is_completed():
		failures.append("FTUE snapshot/restore did not preserve completed stage 5")

	if not failures.is_empty():
		_report(failures)
		return

	print("SPRINT12_EXPERIENCE_GLUE_OK")
	quit(0)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _expect_stage(ftue: FTUEStateMachine, expected: int, label: String, failures: Array[String]) -> void:
	if ftue.get_stage() != expected:
		failures.append("%s: expected FTUE stage %d, got %d" % [label, expected, ftue.get_stage()])


func _expect_screen(ui: UIManager, expected: String, label: String, failures: Array[String]) -> void:
	if ui.active_screen_id != expected:
		failures.append("%s: expected screen '%s', got '%s'" % [label, expected, ui.active_screen_id])


func _report(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)
