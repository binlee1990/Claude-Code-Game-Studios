extends GdUnitTestSuite

const DebugConsoleScript := preload("res://src/tools/debug_console/debug_console.gd")
const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")


func before_test() -> void:
	EventBusScript.instance = EventBusScript.new()
	EventBusScript.instance.clear_all()


func after_test() -> void:
	if EventBusScript.instance != null:
		EventBusScript.instance.clear_all()
	EventBusScript.instance = null


func test_help_lists_ten_commands() -> void:
	var console := DebugConsoleScript.new()
	console._register_commands()
	var lines := console.execute_line("help")
	assert_int(lines.size()).is_equal(10)


func test_event_watch_rejects_duplicate_and_empty_prefix() -> void:
	var console := DebugConsoleScript.new()
	console._register_commands()
	var first := console.execute_line("event watch resource")
	assert_bool(str(first[0]).contains("Watching")).is_true()
	var second := console.execute_line("event watch resource")
	assert_bool(str(second[0]).contains("Already watching 'resource'")).is_true()
	var bad := console.execute_line("event watch ")
	assert_bool(str(bad[0]).contains("Prefix must not be empty")).is_true()
