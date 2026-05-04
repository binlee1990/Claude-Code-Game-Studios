extends GdUnitTestSuite

const DebugConsoleScript := preload("res://src/tools/debug_console/debug_console.gd")


func test_debug_ready_builds_hidden_canvas_layer() -> void:
	var console := DebugConsoleScript.new()
	if OS.is_debug_build():
		console._ready()
		assert_int(console.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
		assert_int(console.canvas_layer.layer).is_equal(128)
		assert_bool(console.canvas_layer.visible).is_false()
	else:
		console._ready()
		assert_bool(console.is_queued_for_deletion()).is_true()
