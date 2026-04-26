#!/usr/bin/env godot
# Legacy script-mode compatibility runner for SRPG.
#
# The actual runner is tests/test_runner.tscn. Running tests directly from
# --script skips project autoload initialization, which makes autoload globals
# such as GameEvents, Inventory, SaveManager, and SceneManager unavailable while
# test scripts are compiled. Keep this file as a shim for older commands.

extends SceneTree

func _init() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"res://tests/test_runner.tscn",
	]
	var exit_code: int = OS.execute(OS.get_executable_path(), args, output, true, true)
	for line in output:
		print(line)
	quit(exit_code)
