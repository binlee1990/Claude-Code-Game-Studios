class_name EquipmentComponent
extends Node

signal equipment_changed(slot: int, old_item_id: StringName, new_item_id: StringName)

var _owner_unit: Unit = null
var _items: Dictionary = {}
var _loadout: Dictionary = {}

func bind_to_unit(unit: Unit) -> void:
	_owner_unit = unit

func add_item(item: EquipmentItem) -> bool:
	if item == null or item.item_id == &"":
		return false
	_items[item.item_id] = item
	return true

func get_item(item_id: StringName) -> EquipmentItem:
	return _items.get(item_id)

func get_item_ids() -> Array:
	return _items.keys()

func get_all_items() -> Array:
	var out: Array = []
	for item_id in _items:
		out.append(_items[item_id])
	return out

func get_equipped_item(slot: int) -> EquipmentItem:
	var item_id: StringName = _loadout.get(slot, &"")
	if item_id == &"":
		return null
	return get_item(item_id)

func get_loadout() -> Dictionary:
	return _loadout.duplicate()

func equip_item(item_id: StringName) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {"success": false, "reason": "missing_item"}
	var slot: int = item.slot
	var old_item_id: StringName = _loadout.get(slot, &"")
	if old_item_id == item_id:
		return {"success": true, "replaced_item_id": &""}
	if old_item_id != &"":
		GameEvents.item_unequipped.emit(_owner_unit, slot, String(old_item_id))
	_loadout[slot] = item_id
	equipment_changed.emit(slot, old_item_id, item_id)
	GameEvents.item_equipped.emit(_owner_unit, slot, String(item_id))
	return {"success": true, "replaced_item_id": old_item_id}

func unequip_slot(slot: int) -> StringName:
	var old_item_id: StringName = _loadout.get(slot, &"")
	if old_item_id == &"":
		return &""
	_loadout.erase(slot)
	equipment_changed.emit(slot, old_item_id, &"")
	GameEvents.item_unequipped.emit(_owner_unit, slot, String(old_item_id))
	return old_item_id

func remove_item(item_id: StringName) -> bool:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return false
	if _loadout.get(item.slot, &"") == item_id:
		unequip_slot(item.slot)
	_items.erase(item_id)
	return true

func get_equipment_bonus(attr_type: int) -> int:
	return int(get_bonus_snapshot()["attributes"].get(attr_type, 0))

func get_stat_bonus(stat_key: String) -> float:
	return float(get_bonus_snapshot()["stats"].get(stat_key, 0.0))

func get_effect_bonus(effect_key: String) -> float:
	return float(get_bonus_snapshot()["effects"].get(effect_key, 0.0))

func get_active_set_bonuses() -> Dictionary:
	return EquipmentDefinitions.aggregate_set_bonuses(_count_equipped_sets())

func get_bonus_snapshot() -> Dictionary:
	var out: Dictionary = {
		"attributes": {},
		"stats": {},
		"effects": {},
	}
	for slot in _loadout:
		var item: EquipmentItem = get_equipped_item(slot)
		if item == null:
			continue
		for affix in item.affixes:
			var attr_type: int = int(affix.get("attribute_type", -1))
			if attr_type >= 0:
				out["attributes"][attr_type] = out["attributes"].get(attr_type, 0) + int(affix.get("value", 0))
				continue
			var stat_key: String = String(affix.get("stat_key", ""))
			if stat_key != "":
				out["stats"][stat_key] = out["stats"].get(stat_key, 0.0) + float(affix.get("value", 0))
	_merge_numeric_dict(out["attributes"], get_active_set_bonuses()["attributes"])
	_merge_numeric_dict(out["stats"], get_active_set_bonuses()["stats"])
	_merge_numeric_dict(out["effects"], get_active_set_bonuses()["effects"])
	return out

func calculate_final_attribute(attr_type: int, base_value: int, class_bonus: int, barrier_bonus: int = 0) -> int:
	return base_value + class_bonus + get_equipment_bonus(attr_type) + barrier_bonus

func get_enhancement_cost(item_id: StringName, inventory = null) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {}
	if inventory != null and inventory.has_method("peek_cost"):
		return inventory.peek_cost(item.enhancement_level)
	return ResourceFormulas.calculate_enhancement_cost(100, item.enhancement_level)

func get_enhancement_shortage(item_id: StringName, inventory) -> Dictionary:
	if inventory == null:
		return {"inventory": 1}
	var cost := get_enhancement_cost(item_id, inventory)
	if cost.is_empty():
		return {}
	if inventory.has_method("get_cost_shortage"):
		return inventory.get_cost_shortage(cost)
	var shortage := {}
	if not inventory.has_resource(ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0))):
		shortage["gold"] = int(cost.get("gold", 0)) - inventory.get_amount(ResourceTypes.ResourceId.GOLD)
	if not inventory.has_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("materials", 0))):
		shortage["materials"] = int(cost.get("materials", 0)) - inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	return shortage

func attempt_enhancement(item_id: StringName, inventory, use_protection: bool = false, rng_seed: int = 0) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {"success": false, "reason": "missing_item"}
	if inventory == null:
		return {"success": false, "reason": "missing_inventory"}
	if item.enhancement_level >= item.get_enhancement_cap():
		return {"success": false, "reason": "at_cap"}
	var cost: Dictionary = get_enhancement_cost(item_id, inventory)
	if not inventory.has_resource(ResourceTypes.ResourceId.GOLD, cost["gold"]):
		return {"success": false, "reason": "insufficient_gold", "cost": cost}
	if not inventory.has_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, cost["materials"]):
		return {"success": false, "reason": "insufficient_materials", "cost": cost}
	var protection_active: bool = use_protection and inventory.has_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 1)
	inventory.remove_resource(ResourceTypes.ResourceId.GOLD, cost["gold"])
	inventory.remove_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, cost["materials"])
	if protection_active:
		inventory.remove_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 1)
	var result: Dictionary = _resolve_enhancement(item, protection_active, rng_seed)
	result["cost"] = cost
	result["protection_consumed"] = protection_active
	GameEvents.equipment_enhanced.emit(String(item_id), int(result.get("new_level", item.enhancement_level)), bool(result.get("success", false)))
	return result

func decompose_item(item_id: StringName, inventory = null, rng_seed: int = 0) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {"success": false, "reason": "missing_item"}
	var rewards: Dictionary = EquipmentDefinitions.calculate_decomposition_rewards(item.quality, rng_seed)
	if inventory != null:
		inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, rewards["basic_materials"])
		if rewards["rare_materials"] > 0:
			inventory.add_resource(ResourceTypes.ResourceId.RARE_MATERIAL, rewards["rare_materials"])
	remove_item(item_id)
	rewards["success"] = true
	return rewards

func get_reroll_cost(item_id: StringName) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {}
	return ResourceFormulas.calculate_affix_reroll_cost(item.quality)

func get_reroll_shortage(item_id: StringName, inventory) -> Dictionary:
	if inventory == null:
		return {"inventory": 1}
	var cost := get_reroll_cost(item_id)
	if cost.is_empty():
		return {}
	var shortage := {}
	if not inventory.has_resource(ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0))):
		shortage["gold"] = int(cost.get("gold", 0)) - inventory.get_amount(ResourceTypes.ResourceId.GOLD)
	if not inventory.has_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("materials", 0))):
		shortage["materials"] = int(cost.get("materials", 0)) - inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL)
	return shortage

func reroll_affix(item_id: StringName, affix_index: int, inventory, rng_seed: int = 0) -> Dictionary:
	var item: EquipmentItem = get_item(item_id)
	if item == null:
		return {"success": false, "reason": "missing_item"}
	if affix_index < 0 or affix_index >= item.affixes.size():
		return {"success": false, "reason": "missing_affix"}
	if inventory == null:
		return {"success": false, "reason": "missing_inventory"}
	var cost := get_reroll_cost(item_id)
	if not get_reroll_shortage(item_id, inventory).is_empty():
		return {"success": false, "reason": "insufficient_resources", "cost": cost}
	inventory.remove_resource(ResourceTypes.ResourceId.GOLD, int(cost.get("gold", 0)))
	inventory.remove_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, int(cost.get("materials", 0)))
	var old_affix: Dictionary = (item.affixes[affix_index] as Dictionary).duplicate(true)
	var new_affix := EquipmentAffixGenerator.generate_affix(item.quality, -1, rng_seed)
	item.affixes[affix_index] = new_affix
	return {
		"success": true,
		"cost": cost,
		"old_affix": old_affix,
		"new_affix": new_affix,
		"enhancement_level": item.enhancement_level,
	}

func get_data() -> Dictionary:
	var items: Array = []
	for item_id in _items:
		items.append((_items[item_id] as EquipmentItem).serialize())
	var loadout: Dictionary = {}
	for slot in _loadout:
		loadout[str(slot)] = String(_loadout[slot])
	return {
		"items": items,
		"loadout": loadout,
	}

func load_data(data: Dictionary) -> void:
	_items.clear()
	_loadout.clear()
	for entry in data.get("items", []):
		var item: EquipmentItem = EquipmentItem.deserialize(entry)
		_items[item.item_id] = item
	for raw_slot in data.get("loadout", {}):
		_loadout[int(raw_slot)] = StringName(data["loadout"][raw_slot])

func _count_equipped_sets() -> Dictionary:
	var counts: Dictionary = {}
	for slot in _loadout:
		var item: EquipmentItem = get_equipped_item(slot)
		if item == null or item.set_id == EquipmentDefinitions.NO_SET:
			continue
		counts[item.set_id] = counts.get(item.set_id, 0) + 1
	return counts

func _resolve_enhancement(item: EquipmentItem, protection_active: bool, rng_seed: int) -> Dictionary:
	var current_level: int = item.enhancement_level
	if current_level < 5:
		item.enhancement_level += 1
		return {"success": true, "result": "success", "new_level": item.enhancement_level}
	if _roll_success(EquipmentDefinitions.get_success_rate(current_level), rng_seed):
		item.enhancement_level += 1
		return {"success": true, "result": "success", "new_level": item.enhancement_level}
	if protection_active:
		return {"success": false, "result": "protected", "new_level": item.enhancement_level}
	item.enhancement_level = maxi(item.enhancement_level - 5, 0)
	return {"success": false, "result": "downgraded", "new_level": item.enhancement_level}

func _roll_success(success_rate: float, rng_seed: int = 0) -> bool:
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	return rng.randf() < success_rate

func _merge_numeric_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[key] = target.get(key, 0) + source[key]
