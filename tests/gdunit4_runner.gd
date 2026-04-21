#!/usr/bin/env godot
# GUT Test Runner for SRPG
# Run with: godot --headless --script tests/gdunit4_runner.gd

extends SceneTree

func _init() -> void:
    var gut = GUT Gut.new()
    gut.set_include_subdirectories(true)
    gut.add_investigator_directory("res://tests/unit/")
    gut.add_investigator_directory("res://tests/integration/")
    gut.set_prefix("test_")
    gut.set_suffix(".gd")

    add_child(gut)
    var exit_code := gut.run_tests()
    quit(exit_code)
