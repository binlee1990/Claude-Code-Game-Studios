class_name LootSystem
extends RefCounted

const MAX_DROPS_PER_KILL := 5

var data_config: Object
var item_registry: ItemRegistry
var _tables := {}


func _init(config: Object = null, registry: ItemRegistry = null) -> void:
	data_config = config
	item_registry = registry
	load_all()


func load_all() -> void:
	_tables.clear()
	if data_config != null and data_config.has_method("get_all"):
		var table = data_config.call("get_all", "loot_tables")
		if typeof(table) == TYPE_DICTIONARY:
			_tables = table.duplicate(true)


func roll_drops(context: Dictionary) -> Dictionary:
	var table_id := str(context.get("loot_table_id", ""))
	var table: Dictionary = _tables.get(table_id, {})
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(str(context.get("seed_context", "loot")).hash())
	var rewards := []
	var entries: Array = table.get("entries", [])
	var max_drops: int = min(MAX_DROPS_PER_KILL, int(table.get("max_drops", MAX_DROPS_PER_KILL)))
	for entry in entries:
		if rewards.size() >= max_drops:
			break
		var item_id := str(entry.get("item_id", entry.get("resource_id", "")))
		if item_registry != null and not item_registry.has_item(item_id):
			push_warning("LootSystem: unknown item id skipped: %s" % item_id)
			continue
		if rng.randf() > clamp(float(entry.get("chance", 0.0)), 0.0, 1.0):
			continue
		var min_qty := int(entry.get("min_qty", 1))
		var max_qty := int(entry.get("max_qty", min_qty))
		if min_qty > max_qty:
			var old_min := min_qty
			min_qty = max_qty
			max_qty = old_min
		rewards.append({"item_id": item_id, "amount": rng.randi_range(min_qty, max_qty)})
	var bundle := {"source_enemy": context.get("enemy_id", ""), "source_zone": context.get("zone_id", ""), "rewards": rewards}
	if not rewards.is_empty():
		_emit("loot.dropped", bundle)
	return bundle


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
