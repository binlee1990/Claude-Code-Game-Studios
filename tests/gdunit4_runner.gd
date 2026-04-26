#!/usr/bin/env godot
# Legacy script-mode GUT runner for SRPG.
# Prefer: godot --headless res://tests/test_runner.tscn
# Scene mode initializes autoload globals before tests are loaded.

extends SceneTree

func _init() -> void:
	var gut := Gut.new()
	gut.add_directory("res://tests/unit/")
	gut.add_directory("res://tests/integration/")
	gut.set_include_subdirectories(true)

	root.add_child(gut)
	gut.run_tests()
	quit()
