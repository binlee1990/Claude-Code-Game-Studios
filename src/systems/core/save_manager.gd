class_name SaveManager
extends Node

const CURRENT_SAVE_VERSION := 1
const DATA_VERSION := "0.0.3"

static var instance: SaveManager

var save_dir := "user://save/"
var backup_enabled := true
var _providers := {}
var _provider_order := []
var _migrations := {}
var _saving := false
var _loading := false
var _last_autosave_time: float = 0.0


func _ready() -> void:
	if instance == null:
		instance = self


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Returns the active SaveManager autoload instance.
static func get_instance() -> SaveManager:
	return instance


## Registers save and restore callbacks under one namespace.
func register_provider(provider_namespace: String, save_fn: Callable, restore_fn: Callable) -> void:
	if provider_namespace.strip_edges().is_empty():
		push_warning("Save provider namespace cannot be empty")
		return
	if _providers.has(provider_namespace):
		push_warning("Save provider overwritten: %s" % provider_namespace)
	else:
		_provider_order.append(provider_namespace)
	_providers[provider_namespace] = {
		"save": save_fn,
		"restore": restore_fn,
	}


## Registers a migration callable for one source version.
func register_migration(from_version: int, migration_fn: Callable) -> void:
	_migrations[from_version] = migration_fn


## Returns whether a save operation is active.
func is_saving() -> bool:
	return _saving


## Returns whether a load operation is active.
func is_loading() -> bool:
	return _loading


## Collects a complete save object without writing to disk.
func collect_save_data() -> Dictionary:
	var systems := {}
	for provider_namespace in _provider_order:
		var provider: Dictionary = _providers[provider_namespace]
		var save_fn: Callable = provider["save"]
		var value = null
		if save_fn.is_valid():
			value = save_fn.call()
		if typeof(value) != TYPE_DICTIONARY:
			push_warning("Provider '%s' returned invalid save data" % provider_namespace)
			value = null
		systems[provider_namespace] = value
	return {
		"meta": {
			"version": CURRENT_SAVE_VERSION,
			"saved_at": Time.get_unix_time_from_system(),
			"data_version": DATA_VERSION,
			"play_time_seconds": 0.0,
		},
		"systems": systems,
	}


## Writes the current save object to disk with a temporary file and backup.
func save_game(slot: int = -1) -> bool:
	if _saving:
		push_warning("Save already in progress")
		return false
	if _loading:
		push_warning("Cannot save while loading")
		return false
	_saving = true
	var save_data := collect_save_data()
	var json_text := JSON.stringify(save_data, "\t")
	var ok := _write_atomic(json_text, slot)
	_saving = false
	if ok:
		_last_autosave_time = Time.get_unix_time_from_system()
		_emit_save_event("save.saved", {"path": _save_path(slot), "slot": slot})
	return ok


## Loads save data from disk and restores registered providers.
func load_game(slot: int = -1) -> bool:
	if _loading:
		return false
	_loading = true
	var loaded: Variant = _read_save_file(_save_path(slot))
	var recovered_from_backup := false
	if loaded == null:
		var backup: Variant = _read_save_file(_backup_path(slot))
		if backup != null:
			loaded = backup
			recovered_from_backup = true
			_emit_save_event("save.corrupted", {"recovered_from_backup": true})
	if loaded == null:
		_emit_save_event("save.corrupted", {"recovered_from_backup": false})
		_loading = false
		return false
	var migrated = _migrate_if_needed(loaded)
	if migrated == null:
		_loading = false
		return false
	_restore_providers(migrated)
	_emit_save_event("save.loaded", {"slot": slot})
	_loading = false
	return true


func list_saves(slot_count: int = 3) -> Array:
	var result := []
	for slot in range(slot_count):
		var data: Variant = _read_save_file(_save_path(slot))
		if data == null and slot == 0:
			data = _read_save_file(_save_path())
		if typeof(data) == TYPE_DICTIONARY:
			var meta: Dictionary = data.get("meta", {})
			result.append({
				"slot": slot,
				"meta": meta,
				"level": _extract_level(data),
				"realm": _extract_realm(data),
			})
		else:
			result.append({})
	return result


func delete_save(slot: int = -1) -> bool:
	var removed := false
	for path in [_save_path(slot), _backup_path(slot), _tmp_path(slot)]:
		if FileAccess.file_exists(path):
			removed = DirAccess.remove_absolute(path) == OK or removed
	if removed:
		_emit_save_event("save.deleted", {"slot": slot})
	return removed


func get_last_autosave_time() -> float:
	return _last_autosave_time


## Clears providers and migrations for isolated tests.
func clear_all() -> void:
	_providers.clear()
	_provider_order.clear()
	_migrations.clear()
	_saving = false
	_loading = false


func _write_atomic(json_text: String, slot: int = -1) -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var tmp_path := _tmp_path(slot)
	var save_path := _save_path(slot)
	var backup_path := _backup_path(slot)
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open temp save file: %s" % tmp_path)
		return false
	var stored := file.store_string(json_text)
	file.flush()
	file.close()
	if not stored:
		push_error("Failed to write temp save file: %s" % tmp_path)
		return false
	if backup_enabled and FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(save_path, backup_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var renamed := DirAccess.rename_absolute(tmp_path, save_path)
	if renamed != OK:
		push_error("Failed to promote temp save file: %s" % tmp_path)
		return false
	return true


func _read_save_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	if not parsed.has("meta") or not parsed.has("systems"):
		return null
	return parsed


func _migrate_if_needed(data: Dictionary) -> Variant:
	var version := int(data.get("meta", {}).get("version", 1))
	if version > CURRENT_SAVE_VERSION:
		push_warning("Save version %d is newer than game version %d" % [version, CURRENT_SAVE_VERSION])
		return null
	while version < CURRENT_SAVE_VERSION:
		if not _migrations.has(version):
			push_error("Migration gap: no script for version %d" % version)
			return null
		var migrated = _migrations[version].call(data)
		if typeof(migrated) != TYPE_DICTIONARY:
			push_error("Migration failed for version %d" % version)
			return null
		data = migrated
		version += 1
		data["meta"]["version"] = version
	return data


func _restore_providers(data: Dictionary) -> void:
	var systems: Dictionary = data.get("systems", {})
	for provider_namespace in _provider_order:
		var provider: Dictionary = _providers[provider_namespace]
		var restore_fn: Callable = provider["restore"]
		if not restore_fn.is_valid():
			continue
		var stored_payload = systems.get(provider_namespace, {})
		var payload := {}
		if typeof(stored_payload) == TYPE_DICTIONARY:
			payload = stored_payload
		var result = restore_fn.call(payload)
		if typeof(result) == TYPE_BOOL and not bool(result):
			push_warning("Provider '%s' restore returned false" % provider_namespace)


func _save_path(slot: int = -1) -> String:
	if slot >= 0:
		return save_dir.path_join("save_slot_%d.json" % slot)
	return save_dir.path_join("save.json")


func _backup_path(slot: int = -1) -> String:
	if slot >= 0:
		return save_dir.path_join("save_slot_%d.json.bak" % slot)
	return save_dir.path_join("save.json.bak")


func _tmp_path(slot: int = -1) -> String:
	if slot >= 0:
		return save_dir.path_join("save_slot_%d.json.tmp" % slot)
	return save_dir.path_join("save.json.tmp")


func _extract_level(data: Dictionary) -> int:
	var level_data: Dictionary = data.get("systems", {}).get("level_system", {})
	var entities: Dictionary = level_data.get("entities", {})
	return int(entities.get("player", {}).get("level", 1))


func _extract_realm(data: Dictionary) -> String:
	var level_data: Dictionary = data.get("systems", {}).get("level_system", {})
	var entities: Dictionary = level_data.get("entities", {})
	return str(entities.get("player", {}).get("realm", "fanren"))


func _emit_save_event(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
