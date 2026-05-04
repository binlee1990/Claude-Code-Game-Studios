extends GdUnitTestSuite

const DebugConsoleScript := preload("res://src/tools/debug_console/debug_console.gd")


func test_help_event_clear_unknown_and_invalid_handler_contracts() -> void:
	var console := DebugConsoleScript.new()
	console._register_commands()
	assert_str(str(console.execute_line("help event")[0])).is_equal("event watch <prefix> | event unwatch <prefix>")
	console.execute_line("help")
	assert_bool(console.get_output_lines().is_empty()).is_false()
	console.execute_line("clear")
	assert_int(console.get_output_lines().size()).is_equal(0)
	console.execute_line("foo")
	assert_bool(console._history.has("foo")).is_false()
	console._commands["broken"] = {"handler": Callable(), "help": "broken"}
	var output := console.execute_line("broken")
	assert_bool(str(output[0]).contains("Command handler unavailable: broken")).is_true()
	assert_bool(console._history.has("broken")).is_false()


func test_history_empty_and_navigation_contract() -> void:
	var console := DebugConsoleScript.new()
	console._build_ui()
	console._register_commands()
	console._step_history(-1)
	assert_str(console.line_edit.text).is_equal("")
	console._record_history("res list")
	console._record_history("time status")
	console._record_history("attr")
	console._step_history(-1)
	assert_str(console.line_edit.text).is_equal("attr")
	console._step_history(-1)
	assert_str(console.line_edit.text).is_equal("time status")
