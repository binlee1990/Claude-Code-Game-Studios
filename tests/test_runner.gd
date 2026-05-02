extends SceneTree

var _passed = 0
var _failed = 0
var _errors = []

func _init():
	_run_all()
	_print_summary()
	quit(0 if _failed == 0 else 1)

func _run_all():
	_run_file("res://tests/unit/map/grid_space_test.gd")
	_run_file("res://tests/unit/unit/unit_stats_test.gd")
	_run_file("res://tests/unit/unit/unit_scene_visual_test.gd")
	_run_file("res://tests/unit/unit/unit_interface_test.gd")
	_run_file("res://tests/unit/unit/hp_system_test.gd")
	_run_file("res://tests/unit/map/map_loading_test.gd")
	_run_file("res://tests/unit/map/grid_topology_test.gd")
	_run_file("res://tests/unit/map/occupancy_test.gd")
	_run_file("res://tests/unit/map/map_variant_pack_test.gd")
	_run_file("res://tests/unit/turn/turn_manager_init_test.gd")
	_run_file("res://tests/unit/turn/turn_state_machine_test.gd")
	_run_file("res://tests/unit/turn/turn_ai_execution_test.gd")
	_run_file("res://tests/unit/turn/victory_checker_test.gd")
	_run_file("res://tests/unit/turn/turn_signals_test.gd")
	_run_file("res://tests/unit/movement/movement_bfs_test.gd")
	_run_file("res://tests/unit/movement/movement_result_test.gd")
	_run_file("res://tests/unit/attack/attack_damage_test.gd")
	_run_file("res://tests/unit/attack/attack_range_test.gd")
	_run_file("res://tests/unit/ai/ai_controller_test.gd")
	_run_file("res://tests/unit/ai/ai_data_structures_test.gd")
	_run_file("res://tests/unit/ai/basic_ai_test.gd")
	_run_file("res://tests/unit/ui/highlight_layer_test.gd")
	_run_file("res://tests/unit/ui/debug_overlay_test.gd")
	_run_file("res://tests/unit/ui/input_handler_test.gd")
	_run_file("res://tests/unit/ui/game_ai_mode_test.gd")
	_run_file("res://tests/unit/ui/hud_test.gd")
	_run_file("res://tests/unit/ui/result_overlay_test.gd")
	_run_file("res://tests/unit/victory/victory_elimination_test.gd")
	_run_file("res://tests/unit/victory/victory_turn_cap_test.gd")
	_run_file("res://tests/integration/movement/movement_execution_test.gd")
	_run_file("res://tests/integration/attack/attack_execution_test.gd")
	_run_file("res://tests/integration/ui/e2e_game_flow_test.gd")

func _run_file(path):
	print("")
	print("=== ", path, " ===")
	var script = load(path)
	if script == null:
		_errors.append("FAIL load: " + path)
		_failed += 1
		return

	var instance = script.new()
	if instance == null:
		_errors.append("FAIL new: " + path)
		_failed += 1
		return

	var test_count = 0
	for method in script.get_script_method_list():
		var mname = method["name"]
		if str(mname).begins_with("test_"):
			test_count += 1
			if instance.has_method("before"):
				instance.before()
			if instance.has_method("set_scene_tree"):
				instance.set_scene_tree(self)
			instance.call(mname)
			_passed += 1
			print("  PASS: ", mname)
			if instance.has_method("after"):
				instance.after()
			_free_tracked_nodes()
	print("  [", test_count, " tests in file]")

func _free_tracked_nodes() -> void:
	Unit.free_test_instances()
	Map.free_test_instances()
	HighlightLayer.free_test_instances()

func _print_summary():
	print("")
	print("====================")
	print("  Total Passed: ", _passed)
	print("====================")
	if _errors.size() > 0:
		print("Errors:")
		for e in _errors:
			print("  ", e)
