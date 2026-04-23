extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "EquipmentSaveUnit"
	_unit.unit_id = &"equip_save"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _build_item(item_id: String, slot: int, quality: int, bonus: int, set_id: int = EquipmentDefinitions.NO_SET, level: int = 0) -> EquipmentItem:
	return EquipmentItem.new({
		"item_id": item_id,
		"slot": slot,
		"quality": quality,
		"enhancement_level": level,
		"set_id": set_id,
		"affixes": [{
			"type": EquipmentDefinitions.AffixType.STR,
			"value": bonus,
			"attribute_type": AttributeNames.Attribute.STR,
			"stat_key": "",
			"category": EquipmentDefinitions.AffixCategory.ATTACK,
		}],
	})

func test_full_equipment_state_round_trip() -> void:
	var sword := _build_item("sword", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.Quality.BLUE, 15, EquipmentDefinitions.SetId.WARRIOR_POWER, 8)
	var armor := _build_item("armor", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.Quality.GOLD, 10, EquipmentDefinitions.SetId.WARRIOR_POWER, 4)
	_unit.equipment_component.add_item(sword)
	_unit.equipment_component.add_item(armor)
	_unit.equipment_component.equip_item(&"sword")
	_unit.equipment_component.equip_item(&"armor")

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	add_child(loaded)
	loaded.deserialize(saved)

	var loaded_sword: EquipmentItem = loaded.equipment_component.get_item(&"sword")
	assert_eq(loaded_sword.quality, EquipmentDefinitions.Quality.BLUE)
	assert_eq(loaded_sword.enhancement_level, 8)
	assert_eq(loaded_sword.affixes[0]["value"], 15)
	assert_eq(loaded.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.WEAPON).item_id, &"sword")
	assert_eq(loaded.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.ARMOR).item_id, &"armor")
	assert_eq(loaded.equipment_component.get_equipment_bonus(AttributeNames.Attribute.STR), 35)
	loaded.queue_free()

func test_set_bonus_restores_after_round_trip() -> void:
	var weapon := _build_item("weapon", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.Quality.GOLD, 0, EquipmentDefinitions.SetId.WARRIOR_POWER)
	var armor := _build_item("armor", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.Quality.GOLD, 0, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_unit.equipment_component.add_item(weapon)
	_unit.equipment_component.add_item(armor)
	_unit.equipment_component.equip_item(&"weapon")
	_unit.equipment_component.equip_item(&"armor")

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	add_child(loaded)
	loaded.deserialize(saved)

	assert_true(loaded.equipment_component.get_active_set_bonuses()["active_sets"].has(EquipmentDefinitions.SetId.WARRIOR_POWER))
	assert_eq(loaded.equipment_component.get_equipment_bonus(AttributeNames.Attribute.STR), 10)
	loaded.queue_free()

func test_double_round_trip_keeps_loadout_identical() -> void:
	_unit.equipment_component.add_item(_build_item("ring", EquipmentDefinitions.Slot.ACCESSORY, EquipmentDefinitions.Quality.PURPLE, 6))
	_unit.equipment_component.equip_item(&"ring")

	var saved1: Dictionary = _unit.serialize()
	var loaded1 := Unit.new()
	add_child(loaded1)
	loaded1.deserialize(saved1)
	var saved2: Dictionary = loaded1.serialize()
	var loaded2 := Unit.new()
	add_child(loaded2)
	loaded2.deserialize(saved2)

	assert_eq(loaded2.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.ACCESSORY).item_id, &"ring")
	assert_eq(loaded2.equipment_component.get_item(&"ring").affixes[0]["value"], 6)
	loaded1.queue_free()
	loaded2.queue_free()
