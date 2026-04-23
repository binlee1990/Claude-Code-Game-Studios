class_name EquipmentItem
extends RefCounted

var item_id: StringName = &""
var name: String = ""
var slot: int = EquipmentDefinitions.Slot.WEAPON
var quality: int = EquipmentDefinitions.Quality.WHITE
var enhancement_level: int = 0
var affixes: Array = []
var set_id: int = EquipmentDefinitions.NO_SET
var base_attributes: Dictionary = {}
var item_kind: StringName = &""

func _init(definition: Dictionary = {}) -> void:
	if not definition.is_empty():
		apply_definition(definition)

func apply_definition(definition: Dictionary) -> void:
	var seed: int = int(definition.get("rng_seed", 0))
	item_id = StringName(definition.get("item_id", item_id))
	name = String(definition.get("name", name))
	slot = int(definition.get("slot", slot))
	quality = int(definition.get("quality", quality))
	enhancement_level = int(definition.get("enhancement_level", enhancement_level))
	item_kind = StringName(definition.get("item_kind", item_kind))
	if definition.has("affixes"):
		affixes = []
		for affix in definition["affixes"]:
			affixes.append((affix as Dictionary).duplicate(true))
	elif affixes.is_empty():
		affixes = []
	if definition.has("set_id"):
		set_id = int(definition["set_id"])
	elif quality == EquipmentDefinitions.Quality.GOLD:
		set_id = EquipmentDefinitions.pick_random_set_id(seed)
	if definition.has("base_attributes"):
		base_attributes = (definition["base_attributes"] as Dictionary).duplicate(true)
	elif base_attributes.is_empty():
		base_attributes = EquipmentDefinitions.generate_base_attributes(slot, quality, seed)

func get_affix_capacity() -> int:
	return EquipmentDefinitions.get_affix_capacity(quality)

func get_enhancement_cap() -> int:
	return EquipmentDefinitions.get_enhancement_cap(quality)

func get_affix_bonus(attr_type: int) -> int:
	var total: int = 0
	for affix in affixes:
		if int(affix.get("attribute_type", -1)) == attr_type:
			total += int(affix.get("value", 0))
	return total

func get_stat_bonus(stat_key: String) -> float:
	var total: float = 0.0
	for affix in affixes:
		if String(affix.get("stat_key", "")) == stat_key:
			total += float(affix.get("value", 0))
	return total

func serialize() -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"slot": slot,
		"quality": quality,
		"enhancement_level": enhancement_level,
		"affixes": affixes.duplicate(true),
		"set_id": set_id,
		"base_attributes": base_attributes.duplicate(true),
		"item_kind": item_kind,
	}

static func deserialize(data: Dictionary) -> EquipmentItem:
	return EquipmentItem.new(data)
