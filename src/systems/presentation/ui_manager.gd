class_name UIManager
extends RefCounted

var screens := {}
var active_screen_id := ""
var error_state := {}
var modal_stack := []
var layout_rebuild_requested := false
var layout_rebuild_count := 0
var overscan_rows := 4


func register_screen(screen_id: String, scene_path: String, unlocked: bool = true) -> void:
	screens[screen_id] = {"path": scene_path, "unlocked": unlocked}


func open_screen(screen_id: String) -> Dictionary:
	if not screens.has(screen_id):
		error_state = {"screen_id": screen_id, "reason": "not_registered"}
		return {"ok": false, "reason": "not_registered"}
	var screen: Dictionary = screens[screen_id]
	if not bool(screen.get("unlocked", false)):
		return {"ok": false, "reason": "locked"}
	var path := str(screen.get("path", ""))
	if path.is_empty() or path.find("missing") >= 0:
		error_state = {"screen_id": screen_id, "reason": "missing_scene"}
		return {"ok": false, "reason": "missing_scene"}
	active_screen_id = screen_id
	return {"ok": true, "active_screen": active_screen_id, "scene_path": path}


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


func open_modal(id: String, allow_passthrough: bool = false) -> void:
	modal_stack.append({"id": id, "allow_passthrough": allow_passthrough})


func close_modal() -> void:
	if not modal_stack.is_empty():
		modal_stack.pop_back()


func can_execute_background_command() -> bool:
	if modal_stack.is_empty():
		return true
	return bool(modal_stack[modal_stack.size() - 1].get("allow_passthrough", false))
