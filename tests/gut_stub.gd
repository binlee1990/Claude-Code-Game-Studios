## Minimal in-tree GUT-compatible test runner for this project.
##
## Implements only the subset of the GUT API currently used by the test suite
## (verified via grep): assert_eq, assert_ne, assert_true, assert_false,
## assert_almost_eq, assert_eq_fTol, before_each, after_each.
##
## Runner side (instantiated once by tests/gdunit4_runner.gd):
##   add_directory / set_include_subdirectories / run_tests — discovers
##   *_test.gd files, instantiates each as a Gut subclass, invokes every
##   public test_* method with before_each/after_each around it, collects
##   pass/fail, prints a summary.
##
## Replace with the official GUT addon when CI adopts one and update
## runner + extends clauses accordingly.

class_name Gut
extends Node

# --- runner state (used when this is the top-level Gut instance) ---

var _test_dirs: PackedStringArray = []
var _include_subdirs: bool = true

var _total_tests: int = 0
var _passed_tests: int = 0
var _failed_tests: int = 0
var _load_errors: Array[String] = []
var _fail_details: Array[String] = []

# --- per-test state (shared across all Gut instances via static) ---

## Set true by any failing assertion during the currently executing test.
## Static so the running test instance and the runner observe the same flag.
static var _current_test_failed: bool = false
static var _current_test_message: String = ""

# --- configuration API (matches the runner script's calls) ---

func add_directory(path: String) -> void:
	_test_dirs.append(path)

func set_include_subdirectories(enabled: bool) -> void:
	_include_subdirs = enabled

# --- discovery + execution ---

func run_tests() -> void:
	# Two-phase: discover all *_test.gd paths first, then execute.
	# Prefer a pre-generated manifest (tests/tests_manifest.txt) because
	# Godot headless --script mode does not refresh the FileSystem cache,
	# so new files created outside the editor are invisible to DirAccess.
	var discovered: Array[String] = []
	var manifest_path: String = "res://tests/tests_manifest.txt"
	if FileAccess.file_exists(manifest_path):
		discovered = _read_manifest(manifest_path)
	else:
		for dir_path in _test_dirs:
			_collect_test_files(dir_path, discovered)
	discovered.sort()
	for path in discovered:
		_run_test_file(path)
	_print_summary()

func _read_manifest(path: String) -> Array[String]:
	var out: Array[String] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_load_errors.append("cannot open manifest: %s" % path)
		return out
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		# Accept both res:// paths and relative paths (relative → res://).
		if not line.begins_with("res://"):
			line = "res://" + line
		out.append(line)
	return out

func _collect_test_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_load_errors.append("cannot open dir: %s" % dir_path)
		return
	dir.list_dir_begin()
	var subdirs: Array[String] = []
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		if dir.current_is_dir():
			subdirs.append(entry)
		elif entry.ends_with("_test.gd") or (entry.begins_with("test_") and entry.ends_with(".gd")):
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	if _include_subdirs:
		for sub in subdirs:
			_collect_test_files(dir_path.path_join(sub), out)

func _run_test_file(script_path: String) -> void:
	if not ResourceLoader.exists(script_path):
		_load_errors.append("%s: ResourceLoader.exists=false" % script_path)
		return
	var script: Resource = load(script_path)
	if script == null or not (script is GDScript):
		_load_errors.append("%s: failed to load as GDScript (likely parse error)" % script_path)
		return
	# Defer-compensate: pre-register an error because calling .new() on a script
	# with compilation failure silently returns from this function before any
	# code after the call runs. If .new() actually succeeds, we remove this
	# entry below; otherwise it remains as the diagnostic.
	var pending_err_idx: int = _load_errors.size()
	_load_errors.append("%s: compilation failure — script loaded but .new() failed (see SCRIPT ERROR above)" % script_path)
	var instance: Object = (script as GDScript).new()
	# Reached here → .new() succeeded; clear the pre-registered error.
	_load_errors.remove_at(pending_err_idx)
	if instance == null:
		_load_errors.append("%s: .new() returned null" % script_path)
		return
	if not (instance is Gut):
		_load_errors.append("%s: class does not extend Gut" % script_path)
		if instance is Node:
			(instance as Node).queue_free()
		return

	var node_instance: Node = instance as Node
	# Attach so _ready fires if tests rely on it; runner node is already in-tree.
	add_child(node_instance)

	var test_methods: Array[String] = _collect_test_methods(node_instance)
	print("\n--- %s (%d) ---" % [script_path, test_methods.size()])

	for method_name in test_methods:
		_current_test_failed = false
		_current_test_message = ""
		_total_tests += 1
		node_instance.call("before_each")
		node_instance.call(method_name)
		node_instance.call("after_each")
		if _current_test_failed:
			_failed_tests += 1
			var detail: String = "%s :: %s — %s" % [script_path, method_name, _current_test_message]
			_fail_details.append(detail)
			print("  FAIL %s — %s" % [method_name, _current_test_message])
		else:
			_passed_tests += 1
			print("  pass %s" % method_name)

	node_instance.queue_free()

func _collect_test_methods(instance: Node) -> Array[String]:
	var out: Array[String] = []
	for m in instance.get_method_list():
		var name_str: String = String(m.name)
		if name_str.begins_with("test_") and (m.args as Array).is_empty():
			out.append(name_str)
	out.sort()
	return out

func _print_summary() -> void:
	print("\n====== GUT SUMMARY ======")
	print("Total: %d | Pass: %d | Fail: %d" % [_total_tests, _passed_tests, _failed_tests])
	if not _load_errors.is_empty():
		print("\nLoad errors (%d):" % _load_errors.size())
		for e in _load_errors:
			print("  %s" % e)
	if not _fail_details.is_empty():
		print("\nFailure details (%d):" % _fail_details.size())
		for f in _fail_details:
			print("  %s" % f)
	print("=========================")

# --- per-test lifecycle hooks (subclasses may override) ---

func before_each() -> void:
	pass

func after_each() -> void:
	pass

# --- assertions ---
# Every assertion records failure via the static flag so the runner can detect
# it after the test method returns. The first failure wins so the user sees the
# earliest diverging check rather than a cascade.

func _record_failure(message: String) -> void:
	if not _current_test_failed:
		_current_test_failed = true
		_current_test_message = message
	push_error(message)

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		_record_failure("assert_eq failed: got %s, expected %s. %s" % [str(actual), str(expected), msg])

func assert_ne(actual: Variant, unexpected: Variant, msg: String = "") -> void:
	if actual == unexpected:
		_record_failure("assert_ne failed: value equals %s. %s" % [str(unexpected), msg])

func assert_true(condition: bool, msg: String = "") -> void:
	if not condition:
		_record_failure("assert_true failed. %s" % msg)

func assert_false(condition: bool, msg: String = "") -> void:
	if condition:
		_record_failure("assert_false failed. %s" % msg)

func assert_almost_eq(actual: float, expected: float, tolerance: float, msg: String = "") -> void:
	if absf(actual - expected) > tolerance:
		_record_failure("assert_almost_eq failed: got %s, expected %s ± %s. %s" % [str(actual), str(expected), str(tolerance), msg])

## Float equality with explicit tolerance — matches existing test usage.
func assert_eq_fTol(actual: float, expected: float, tolerance: float, msg: String = "") -> void:
	assert_almost_eq(actual, expected, tolerance, msg)
