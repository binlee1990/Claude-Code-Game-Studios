# Autoload: SaveManager
extends Node

const SRPGLocalizationScript := preload("res://src/core/localization/srpg_localization.gd")

const SAVE_DIR := "user://saves/"
const SETTINGS_PATH := SAVE_DIR + "settings.tres"
const MAX_SLOTS := 8

var _current_slot: int = -1
var _pending_loaded_data: SaveData = null

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

## Capture the current runtime state and persist it into the given slot.
func save_game(slot: int) -> bool:
	if slot < 0 or slot > MAX_SLOTS:
		return false

	var save_data := _create_save_data(slot)

	var path := SAVE_DIR + "save_%d.tres" % slot
	_remove_save_file(path)

	var result := ResourceSaver.save(save_data, path)
	if result != OK:
		return false

	var verify := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
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

	var save_data := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
	if save_data == null:
		return false

	_apply_locale_from_save_data(save_data)
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

## Read-only preview of a save slot. Does NOT modify _current_slot or emit signals.
## Returns null if the slot file does not exist or cannot be loaded.
func peek_save(slot: int) -> SaveData:
	var path := SAVE_DIR + "save_%d.tres" % slot
	if not FileAccess.file_exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData

## Persist the language preference outside combat/base save-state providers.
func save_locale_preference(locale: String) -> bool:
	if not SRPGLocalizationScript.is_supported_locale(locale):
		return false
	var settings_data := _load_settings_data()
	settings_data.locale = locale
	settings_data.timestamp = Time.get_unix_time_from_system()
	settings_data.settings["locale"] = locale
	var result := ResourceSaver.save(settings_data, SETTINGS_PATH)
	if result != OK:
		return false
	SRPGLocalizationScript.set_locale(locale)
	return true

## Resolve the best available locale preference without mutating save slots.
func load_locale_preference() -> String:
	var settings_data := _load_settings_data(false)
	if settings_data != null:
		var settings_locale := _locale_from_save_data(settings_data)
		if settings_locale != "":
			return settings_locale
	var current_slot := get_current_slot()
	if current_slot >= 0:
		var current_save := peek_save(current_slot)
		var current_locale := _locale_from_save_data(current_save)
		if current_locale != "":
			return current_locale
	var slot_one := peek_save(1)
	var slot_one_locale := _locale_from_save_data(slot_one)
	if slot_one_locale != "":
		return slot_one_locale
	return SRPGLocalizationScript.DEFAULT_LOCALE

func _remove_save_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _create_save_data(slot: int) -> SaveData:
	var save_data := SaveData.new()
	save_data.timestamp = Time.get_unix_time_from_system()
	save_data.locale = SRPGLocalizationScript.get_locale()

	var snapshot := _capture_runtime_from_best_provider()
	var provider: Node = snapshot.get("provider", null)
	save_data.current_scene_key = _infer_scene_key(provider)
	var previous_save := peek_save(slot)

	var runtime: Dictionary = snapshot.get("runtime", {})
	if not runtime.is_empty():
		save_data.party_units = runtime.get("party_units", [])
		save_data.inventory_items = runtime.get("inventory_items", [])
		save_data.settings = runtime.get("settings", {})
		save_data.battle_state = runtime.get("battle_state", {})
		save_data.camera_preferences = runtime.get("camera_preferences", {})
		save_data.ui_preferences = runtime.get("ui_preferences", {})
		save_data.inventory_state = runtime.get("inventory_state", {})
		save_data.battle_history = runtime.get("battle_history", {})
		save_data.story_progress = runtime.get("story_progress", {})
	if previous_save != null:
		_preserve_campaign_state(save_data, previous_save)

	save_data.settings["locale"] = SRPGLocalizationScript.get_locale()
	return save_data

func _preserve_campaign_state(save_data: SaveData, previous_save: SaveData) -> void:
	var lacks_battle_state := save_data.battle_state.is_empty()
	if lacks_battle_state:
		save_data.battle_state = previous_save.battle_state.duplicate(true)
	if lacks_battle_state and save_data.story_progress.is_empty():
		save_data.story_progress = previous_save.story_progress.duplicate(true)
	if lacks_battle_state and save_data.camera_preferences.is_empty():
		save_data.camera_preferences = previous_save.camera_preferences.duplicate(true)
	if lacks_battle_state and save_data.battle_history.is_empty():
		save_data.battle_history = previous_save.battle_history.duplicate(true)
	if save_data.current_scene_key.is_empty():
		save_data.current_scene_key = previous_save.current_scene_key

	if save_data.ui_preferences.is_empty():
		save_data.ui_preferences = previous_save.ui_preferences.duplicate(true)

	var merged_settings := previous_save.settings.duplicate(true)
	for key in save_data.settings.keys():
		merged_settings[key] = save_data.settings[key]
	save_data.settings = merged_settings

func _load_settings_data(create_if_missing: bool = true) -> SaveData:
	if FileAccess.file_exists(SETTINGS_PATH):
		var loaded := ResourceLoader.load(SETTINGS_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
		if loaded != null:
			return loaded
	if not create_if_missing:
		return null
	return SaveData.new()

func _apply_locale_from_save_data(save_data: SaveData) -> void:
	var locale := _locale_from_save_data(save_data)
	if locale != "":
		SRPGLocalizationScript.set_locale(locale)

func _locale_from_save_data(save_data: SaveData) -> String:
	if save_data == null:
		return ""
	if save_data.locale != "" and SRPGLocalizationScript.is_supported_locale(save_data.locale):
		return save_data.locale
	var settings_locale := String(save_data.settings.get("locale", ""))
	if settings_locale != "" and SRPGLocalizationScript.is_supported_locale(settings_locale):
		return settings_locale
	return ""

func _capture_runtime_from_best_provider() -> Dictionary:
	var best_provider: Node = null
	var best_runtime: Dictionary = {}
	var best_score := -1
	for provider in _find_save_state_providers():
		var runtime: Dictionary = provider.call("capture_runtime_state")
		var score := _score_runtime_state(runtime)
		if score > best_score:
			best_provider = provider
			best_runtime = runtime
			best_score = score
	return {
		"provider": best_provider,
		"runtime": best_runtime,
	}

func _score_runtime_state(runtime: Dictionary) -> int:
	var score := 0
	score += runtime.get("party_units", []).size() * 10
	score += runtime.get("inventory_items", []).size() * 3
	score += runtime.get("battle_state", {}).get("units", []).size() * 5
	score += 5 if not runtime.get("story_progress", {}).is_empty() else 0
	score += 3 if not runtime.get("inventory_state", {}).is_empty() else 0
	score += 2 if not runtime.get("battle_history", {}).is_empty() else 0
	return score

func _find_save_state_provider() -> Node:
	var providers := _find_save_state_providers()
	if providers.is_empty():
		return null
	return providers[providers.size() - 1]

func _find_save_state_providers() -> Array:
	var tree := get_tree()
	if tree == null:
		return []
	var valid_providers: Array = []
	var providers: Array = tree.get_nodes_in_group("save_state_provider")
	for i in range(0, providers.size()):
		var provider: Node = providers[i]
		if (
			is_instance_valid(provider)
			and provider.is_inside_tree()
			and not provider.is_queued_for_deletion()
			and provider.has_method("capture_runtime_state")
		):
			valid_providers.append(provider)

	if valid_providers.is_empty():
		_find_providers_recursive(tree.root, valid_providers)
	return valid_providers

func _find_providers_recursive(node: Node, out: Array) -> void:
	if node == null:
		return
	if (
		is_instance_valid(node)
		and node.is_inside_tree()
		and not node.is_queued_for_deletion()
		and node.has_method("capture_runtime_state")
	):
		out.append(node)
	for child in node.get_children():
		_find_providers_recursive(child, out)

func _infer_scene_key(provider: Node = null) -> String:
	if provider == null:
		provider = _find_save_state_provider()
	if provider != null and provider.has_method("get_scene_key"):
		return String(provider.call("get_scene_key"))
	return ""
