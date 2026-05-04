class_name DataConfig
extends RefCounted

var data_root_dir := "res://assets/data/"
var hot_reload_enabled := false
var _tables := {}
var _loaded := false


func _init(root_dir: String = "res://assets/data/") -> void:
	data_root_dir = root_dir


## Loads every JSON file from the configured data root.
func load_all() -> void:
	_tables.clear()
	var dir := DirAccess.open(data_root_dir)
	if dir == null:
		push_error("Data directory not found: %s" % data_root_dir)
		_loaded = true
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var table_name := file_name.get_basename()
			_load_table_from_path(table_name, data_root_dir.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	_loaded = true


## Loads a table from an in-memory dictionary. This is used by tests and bootstrap fixtures.
func load_table_data(table_name: String, records: Dictionary) -> void:
	var table := {}
	for id in records.keys():
		if records[id] == null:
			push_warning("Null record skipped: %s/%s" % [table_name, str(id)])
			continue
		if table.has(id):
			push_warning("Duplicate ID '%s' in table '%s', using last definition" % [str(id), table_name])
		table[id] = records[id]
	_tables[table_name] = table
	_loaded = true


## Returns one record or null when table or record is missing.
func get_record(table_name: String, id: String) -> Variant:
	if not _tables.has(table_name):
		push_warning("Table not found: %s" % table_name)
		return null
	var table: Dictionary = _tables[table_name]
	if not table.has(id):
		push_warning("Record not found: %s/%s" % [table_name, id])
		return null
	return table[id]


## Returns a whole table, or an empty dictionary when missing.
func get_all(table_name: String) -> Dictionary:
	if not _tables.has(table_name):
		push_warning("Table not found: %s" % table_name)
		return {}
	return _tables[table_name].duplicate(true)


## Returns loaded table names sorted for tooling and debug console output.
func get_table_names() -> Array:
	var names := _tables.keys()
	names.sort()
	return names


## Returns records accepted by the filter callable.
func query(table_name: String, filter: Callable) -> Array:
	var table := get_all(table_name)
	var result := []
	if not filter.is_valid():
		push_warning("Invalid query filter for table: %s" % table_name)
		return result
	for record in table.values():
		var accepted = filter.call(record)
		if typeof(accepted) == TYPE_BOOL and accepted:
			result.append(record)
	return result


## Returns true when a table exists.
func has_table(table_name: String) -> bool:
	return _tables.has(table_name)


## Returns true when a record exists in a loaded table.
func has_record(table_name: String, id: String) -> bool:
	return _tables.has(table_name) and _tables[table_name].has(id)


## Returns a field value from one record, or null when missing.
func get_field(table_name: String, id: String, field: String) -> Variant:
	var record = get_record(table_name, id)
	if record == null or typeof(record) != TYPE_DICTIONARY:
		return null
	return record.get(field, null)


## Returns whether load_all or load_table_data has completed at least once.
func is_loaded() -> bool:
	return _loaded


## Reloads one table in debug/hot-reload mode.
func reload_table(table_name: String) -> void:
	if not hot_reload_enabled or not OS.is_debug_build():
		return
	_load_table_from_path(table_name, data_root_dir.path_join("%s.json" % table_name))


## Reloads all tables in debug/hot-reload mode.
func reload_all() -> void:
	if not hot_reload_enabled or not OS.is_debug_build():
		return
	load_all()


func _load_table_from_path(table_name: String, path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("Data file not found: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open data file: %s" % path)
		_tables[table_name] = {}
		return
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to parse table: %s, path: %s" % [table_name, path])
		_tables[table_name] = {}
		return
	load_table_data(table_name, parsed)
