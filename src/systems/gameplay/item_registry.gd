class_name ItemRegistry
extends RefCounted

const TABLE_NAME := "items"
const ITEM_CLASSES := ["resource_material", "consumable", "equipment", "quest"]
const RARITIES := ["fanpin", "jingliang", "xiyou", "shishi", "chuanshuo", "shenhua", "xiantian", "hundun"]

var _data_config: Object
var _items := {}
var _loaded := false
var _last_loaded_payload := {"count": 0, "item_classes": {}}


func _init(data_config: Object = null) -> void:
	_data_config = data_config


## Injects DataConfig or a compatible test double. Passing null makes the registry degrade to empty.
func set_data_config(data_config: Object) -> void:
	_data_config = data_config


## Loads item definitions from DataConfig and emits the startup lifecycle event synchronously.
func _initialize() -> void:
	_load_from_data_config()
	_emit_lifecycle("item_registry.loaded")


## Returns a deep-copy item definition, or an empty dictionary when missing.
func get_item(id: String) -> Dictionary:
	if not _items.has(id):
		push_warning("ItemRegistry: item not found: %s" % id)
		return {}
	return _items[id].duplicate(true)


## Returns true when the item id is registered. Missing ids are not warnings.
func has_item(id: String) -> bool:
	return _items.has(id)


## Returns one raw field. Container fields are intentionally unsafe; duplicate before mutating.
func peek_field(id: String, field: String) -> Variant:
	if not _items.has(id):
		return null
	var item: Dictionary = _items[id]
	return item.get(field, null)


## Returns all item ids. Do not call from _process/_physics_process; cache after item_registry.loaded.
func get_all_ids() -> Array:
	var ids := _items.keys()
	ids.sort()
	return ids


func get_count() -> int:
	return _items.size()


func is_loaded() -> bool:
	return _loaded


func get_last_loaded_payload() -> Dictionary:
	return _last_loaded_payload.duplicate(true)


func query_by_item_class(item_class: String) -> Array:
	if not ITEM_CLASSES.has(item_class):
		push_warning("ItemRegistry: invalid item_class: %s" % item_class)
		return []
	var result := []
	for id in get_all_ids():
		var item: Dictionary = _items[id]
		if str(item["item_class"]) == item_class:
			result.append(item.duplicate(true))
	return result


func query_by_tag(tag: String) -> Array:
	var result := []
	if tag.is_empty():
		return result
	for id in get_all_ids():
		var item: Dictionary = _items[id]
		var tags: Array = item.get("tags", [])
		if tags.has(tag):
			result.append(item.duplicate(true))
	return result


## Debug-only hot reload. DataConfig.hot_reload_enabled must also be true.
func reload() -> void:
	if not OS.is_debug_build():
		push_warning("ItemRegistry: reload disabled in release build")
		return
	if _data_config == null:
		push_warning("ItemRegistry: reload skipped because DataConfig is unavailable")
		return
	if not bool(_data_config.get("hot_reload_enabled")):
		push_warning("ItemRegistry: hot reload disabled in DataConfig")
		return
	var old_ids := {}
	for id in _items.keys():
		old_ids[id] = true
	if _data_config.has_method("reload_table"):
		_data_config.call("reload_table", TABLE_NAME)
	_load_from_data_config()
	for id in old_ids.keys():
		if not _items.has(id):
			push_warning("ItemRegistry: item removed during reload: %s" % id)
	_emit_lifecycle("item_registry.reloaded")


func _load_from_data_config() -> void:
	_items.clear()
	_loaded = false
	var raw_items = _read_items_table()
	if raw_items == null:
		push_warning("ItemRegistry: DataConfig returned null for items table")
		_loaded = true
		_last_loaded_payload = _build_payload()
		return
	if typeof(raw_items) != TYPE_DICTIONARY:
		push_warning("ItemRegistry: items table must be a Dictionary")
		_loaded = true
		_last_loaded_payload = _build_payload()
		return
	var raw_table: Dictionary = raw_items
	for raw_id in raw_table.keys():
		var item := _normalize_item(str(raw_id), raw_table[raw_id])
		if item.is_empty():
			continue
		if _items.has(item["id"]):
			push_warning("ItemRegistry: duplicate item id skipped: %s" % str(item["id"]))
			continue
		_items[item["id"]] = item
	_loaded = true
	_last_loaded_payload = _build_payload()


func _read_items_table() -> Variant:
	if _data_config == null or not _data_config.has_method("get_all"):
		push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry")
		return {}
	return _data_config.call("get_all", TABLE_NAME)


func _normalize_item(id: String, raw_value: Variant) -> Dictionary:
	var clean_id := id.strip_edges()
	if clean_id.is_empty():
		push_warning("ItemRegistry: empty item id skipped")
		return {}
	if typeof(raw_value) != TYPE_DICTIONARY:
		push_warning("ItemRegistry: non-dictionary item skipped: %s" % clean_id)
		return {}
	var raw: Dictionary = raw_value
	var item := raw.duplicate(true)
	item["id"] = clean_id
	var item_class := str(item.get("item_class", "")).strip_edges()
	if not ITEM_CLASSES.has(item_class):
		push_warning("ItemRegistry: invalid item_class '%s' on item '%s'" % [item_class, clean_id])
		return {}
	var name := str(item.get("name", "")).strip_edges()
	if name.is_empty():
		push_warning("ItemRegistry: item '%s' has empty name and was skipped" % clean_id)
		return {}
	var rarity := str(item.get("rarity", "fanpin")).strip_edges()
	if not RARITIES.has(rarity):
		push_warning("ItemRegistry: invalid rarity '%s' on item '%s', defaulted to fanpin" % [rarity, clean_id])
		rarity = "fanpin"
	var tags: Array = []
	if item.has("tags") and typeof(item["tags"]) != TYPE_ARRAY:
		push_warning("ItemRegistry: item '%s' tags must be an Array, defaulted to []" % clean_id)
	elif typeof(item.get("tags", [])) == TYPE_ARRAY:
		for tag in item.get("tags", []):
			tags.append(str(tag))
	item["name"] = name
	item["item_class"] = item_class
	item["rarity"] = rarity
	item["tags"] = tags
	item["description"] = str(item.get("description", ""))
	item["icon_path"] = str(item.get("icon_path", ""))
	item["stackable"] = bool(item.get("stackable", true))
	item["stack_limit"] = int(item.get("stack_limit", -1))
	if typeof(item.get("meta", {})) != TYPE_DICTIONARY:
		item["meta"] = {}
	else:
		item["meta"] = item.get("meta", {}).duplicate(true)
	return item


func _build_payload() -> Dictionary:
	var counts := {}
	for item in _items.values():
		var item_class := str(item["item_class"])
		counts[item_class] = int(counts.get(item_class, 0)) + 1
	return {"count": _items.size(), "item_classes": counts.duplicate()}


func _emit_lifecycle(event_name: String) -> void:
	var payload := _last_loaded_payload.duplicate(true)
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
