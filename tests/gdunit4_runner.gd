#!/usr/bin/env godot
# GUT Test Runner for SRPG
# Run with: godot --headless --script tests/gdunit4_runner.gd

extends SceneTree

func _init() -> void:
	var gut := Gut.new()
	gut.add_directory("res://tests/unit/")
	gut.add_directory("res://tests/integration/")
	gut.set_include_subdirectories(true)

	root.add_child(gut)
	gut.run_tests()
	quit()
