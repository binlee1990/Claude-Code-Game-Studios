## Scene-mode test runner.
##
## Run with: godot --headless res://tests/test_runner.tscn
##
## Running as a scene (not --script) ensures autoloads (GameEvents,
## SaveManager, SceneManager) are fully initialised and available as
## parse-time global identifiers — otherwise test files that directly
## reference GameEvents fail compilation.

extends Node

func _ready() -> void:
	var gut := Gut.new()
	gut.add_directory("res://tests/unit/")
	gut.add_directory("res://tests/integration/")
	gut.set_include_subdirectories(true)
	add_child(gut)
	gut.run_tests()
	get_tree().quit()
