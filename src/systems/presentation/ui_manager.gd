## UIManager — screen registry, navigation logic, and modal depth enforcement.
##
## RefCounted service owned by UIManagerHost. Manages screen metadata,
## unlock conditions, transition timing, and the modal stack depth limit.
## Does NOT directly manage Control nodes — UIManagerHost handles
## load().instantiate(), add_child(), show/hide, and animation tweens.
##
## ADR-0011: Screen stack with show/hide switching.
## ADR-0011: Modal stack with max_modal_depth=3.
class_name UIManager
extends RefCounted


# Screen registry: screen_id -> {path, unlocked, unlock_condition, instance}
var screens := {}

# Currently active screen id.
var active_screen_id := ""

# Error state for degraded mode.
var error_state := {}

# Modal stack — list of {id, allow_passthrough, node}.
var modal_stack := []

# Layout rebuild tracking.
var layout_rebuild_requested := false
var layout_rebuild_count := 0

# Virtual list overscan rows.
var overscan_rows := 4

# Transition duration in milliseconds (default 120ms per ADR-0011).
var default_transition_ms: int = 120

# Maximum concurrent modals (ADR-0011).
var max_modal_depth: int = 3


# ---------------------------------------------------------------------------
# Screen registration (Sprint 10 backward-compatible)
# ---------------------------------------------------------------------------

## Register a screen. If `unlock_condition` is a Callable, it will be evaluated
## at open time. Boolean `true` means always unlocked.
func register_screen(screen_id: String, scene_path: String, unlocked = true) -> void:
	var unlock_condition: Callable = _always_unlocked
	if typeof(unlocked) == TYPE_CALLABLE:
		unlock_condition = unlocked
	elif typeof(unlocked) == TYPE_BOOL and not bool(unlocked):
		unlock_condition = _always_locked

	screens[screen_id] = {
		"path": scene_path,
		"unlocked": bool(unlocked) if typeof(unlocked) != TYPE_CALLABLE else false,
		"unlock_condition": unlock_condition,
		"instance": null,
	}


# ---------------------------------------------------------------------------
# Screen navigation (Sprint 10 dict-return API preserved)
# ---------------------------------------------------------------------------

## Evaluate and open a screen. Returns a Dictionary for Sprint 10 backward compat.
## The Host layer calls this and then handles actual scene instantiation.
func open_screen(screen_id: String) -> Dictionary:
	if not screens.has(screen_id):
		error_state = {"screen_id": screen_id, "reason": "not_registered"}
		return {"ok": false, "reason": "not_registered"}

	var screen: Dictionary = screens[screen_id]

	# Evaluate unlock condition if it's a Callable.
	var cond: Callable = screen.get("unlock_condition", _always_unlocked)
	if not cond.call():
		return {"ok": false, "reason": "locked"}

	var path := str(screen.get("path", ""))
	if path.is_empty() or path.find("missing") >= 0:
		error_state = {"screen_id": screen_id, "reason": "missing_scene"}
		return {"ok": false, "reason": "missing_scene"}

	active_screen_id = screen_id
	return {"ok": true, "active_screen": active_screen_id, "scene_path": path}


# ---------------------------------------------------------------------------
# New screen management (Sprint 11+ — used by UIManagerHost)
# ---------------------------------------------------------------------------

## Return the scene path for a registered screen, or empty string.
func get_screen_path(screen_id: String) -> String:
	if not screens.has(screen_id):
		return ""
	return str(screens[screen_id].get("path", ""))


## Check whether a screen is unlocked.
func is_screen_unlocked(screen_id: String) -> bool:
	if not screens.has(screen_id):
		return false
	var screen: Dictionary = screens[screen_id]
	var cond: Callable = screen.get("unlock_condition", _always_unlocked)
	return cond.call()


## Store a reference to an instantiated screen node.
func set_screen_instance(screen_id: String, node: Node) -> void:
	if screens.has(screen_id):
		screens[screen_id]["instance"] = node


## Retrieve the instantiated screen node, or null.
func get_screen_instance(screen_id: String) -> Node:
	if not screens.has(screen_id):
		return null
	return screens[screen_id].get("instance")


## Clear instance reference (for replace_screen / remove).
func clear_screen_instance(screen_id: String) -> void:
	if screens.has(screen_id):
		screens[screen_id]["instance"] = null


# ---------------------------------------------------------------------------
# Modal management (ADR-0011 modal depth enforcement)
# ---------------------------------------------------------------------------

## Open a modal. Returns true if within depth limit.
func open_modal(id: String, allow_passthrough: bool = false) -> bool:
	if modal_stack.size() >= max_modal_depth:
		push_warning("UIManager: modal depth exceeded (%d)" % max_modal_depth)
		return false
	modal_stack.append({"id": id, "allow_passthrough": allow_passthrough, "node": null})
	return true


## Close the topmost modal. Returns the closed modal id or empty string.
func close_modal() -> String:
	if modal_stack.is_empty():
		return ""
	var entry := modal_stack.pop_back()
	return str(entry.get("id", ""))


## Check whether there is at least one open modal.
func has_open_modal() -> bool:
	return not modal_stack.is_empty()


## Store a reference to an instantiated modal node.
func set_modal_node(id: String, node: Node) -> void:
	for entry in modal_stack:
		if str(entry.get("id", "")) == id:
			entry["node"] = node
			return


## Check whether background commands are allowed (blocked when modal is open).
func can_execute_background_command() -> bool:
	if modal_stack.is_empty():
		return true
	return bool(modal_stack[modal_stack.size() - 1].get("allow_passthrough", false))


# ---------------------------------------------------------------------------
# Layout & virtual list
# ---------------------------------------------------------------------------

func render_virtual_list(items: Array, viewport_height: int, row_height: int) -> Array:
	var visible_count := int(ceil(float(viewport_height) / max(1.0, float(row_height)))) + overscan_rows * 2
	return items.slice(0, min(items.size(), visible_count))


func request_layout_rebuild() -> void:
	layout_rebuild_requested = true


func flush_layout() -> void:
	if not layout_rebuild_requested:
		return
	layout_rebuild_count += 1
	layout_rebuild_requested = false


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _always_unlocked() -> bool:
	return true


func _always_locked() -> bool:
	return false
