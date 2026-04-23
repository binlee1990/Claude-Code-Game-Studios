# Autoload: SaveManager
extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 8

var _current_slot: int = -1
var _pending_loaded_data: SaveData = null

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

## Capture the current runtime state and persist it into the given slot.
func save_game(slot: int) -> bool:
	if slot < 0 or slot > MAX_SLOTS:
		return false

	var save_data := _create_save_data()

	var path := SAVE_DIR + "save_%d.tres" % slot
	var result := ResourceSaver.save(save_data, path)
	if result != OK:
		return false

	var verify := load(path) as SaveData
	if verify == null:
		return false

	_current_slot = slot
	GameEvents.game_saved.emit(slot, save_data.timestamp)
	return true

## Load a slot and stage its SaveData for the next runtime state provider to consume.
func load_game(slot: int) -> bool:
	var path := SAVE_DIR + "save_%d.tres" % slot
	if not FileAccess.file_exists(path):
		return false

	var save_data := load(path) as SaveData
	if save_data == null:
		return false

	_pending_loaded_data = save_data
	_current_slot = slot
	GameEvents.game_loaded.emit(slot)
	return true

## Check whether a save file exists for the given slot.
func has_save(slot: int) -> bool:
	var path := SAVE_DIR + "save_%d.tres" % slot
	return FileAccess.file_exists(path)

## Returns true when a previously loaded save is waiting to be consumed.
func has_pending_loaded_data() -> bool:
	return _pending_loaded_data != null

## Consume the pending loaded save data. Subsequent calls return null until another load.
func consume_pending_loaded_data() -> SaveData:
	var data := _pending_loaded_data
	_pending_loaded_data = null
	return data

## Clear any pending loaded save data without consuming it.
func clear_pending_loaded_data() -> void:
	_pending_loaded_data = null

## Return the slot most recently saved or loaded, or -1 if none.
func get_current_slot() -> int:
	return _current_slot

func _create_save_data() -> SaveData:
	var save_data := SaveData.new()
	save_data.timestamp = Time.get_unix_time_from_system()
	save_data.current_scene_key = _infer_scene_key()

	var provider: Node = _find_save_state_provider()
	if provider != null and provider.has_method("capture_runtime_state"):
		var runtime: Dictionary = provider.call("capture_runtime_state")
		save_data.settings = runtime.get("settings", {})
		save_data.battle_state = runtime.get("battle_state", {})
		save_data.camera_preferences = runtime.get("camera_preferences", {})
		save_data.ui_preferences = runtime.get("ui_preferences", {})
		save_data.inventory_state = runtime.get("inventory_state", {})
		save_data.battle_history = runtime.get("battle_history", {})

	return save_data

func _find_save_state_provider() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var providers: Array = tree.get_nodes_in_group("save_state_provider")
	if providers.is_empty():
		return null
	for i in range(providers.size() - 1, -1, -1):
		var provider: Node = providers[i]
		if is_instance_valid(provider) and provider.is_inside_tree():
			return provider
	return null

func _infer_scene_key() -> String:
	var provider: Node = _find_save_state_provider()
	if provider != null and provider.has_method("get_scene_key"):
		return String(provider.call("get_scene_key"))
	return ""
