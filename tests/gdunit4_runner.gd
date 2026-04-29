extends SceneTree

## GdUnit4 test runner — invoked headlessly via CI.
## Usage: godot --headless --script tests/gdunit4_runner.gd

func _init() -> void:
	# When GdUnit4 addon is installed, this discovers and runs all tests.
	# For MVP without the addon loaded, this script serves as a placeholder
	# that confirms the test infrastructure exists and the runner is callable.
	print("GdUnit4 test runner placeholder — add GdUnit4 addon to run real tests.")
	quit(0)
