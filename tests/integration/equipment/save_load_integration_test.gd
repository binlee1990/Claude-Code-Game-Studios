extends Gut

var _unit: Unit

func before_each() -> void:
	Inventory.reset()
	_unit = Unit.new()
	_unit.name = "EquipmentSaveUnit"
	_unit.unit_id = &"equip_save"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()
	Inventory.reset()

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

func test_risk_zone_levels_round_trip_at_plus_six_eight_and_ten() -> void:
	_unit.equipment_component.add_item(_build_item("sword_6", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.Quality.BLUE, 7, EquipmentDefinitions.NO_SET, 6))
	_unit.equipment_component.add_item(_build_item("armor_8", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.Quality.PURPLE, 9, EquipmentDefinitions.NO_SET, 8))
	_unit.equipment_component.add_item(_build_item("helm_10", EquipmentDefinitions.Slot.HELMET, EquipmentDefinitions.Quality.GOLD, 12, EquipmentDefinitions.NO_SET, 10))
	_unit.equipment_component.equip_item(&"sword_6")
	_unit.equipment_component.equip_item(&"armor_8")
	_unit.equipment_component.equip_item(&"helm_10")

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	add_child(loaded)
	loaded.deserialize(saved)

	assert_eq(loaded.equipment_component.get_item(&"sword_6").enhancement_level, 6)
	assert_eq(loaded.equipment_component.get_item(&"armor_8").enhancement_level, 8)
	assert_eq(loaded.equipment_component.get_item(&"helm_10").enhancement_level, 10)
	assert_eq(loaded.equipment_component.get_equipped_item(EquipmentDefinitions.Slot.HELMET).item_id, &"helm_10")
	loaded.queue_free()

func test_protect_symbol_consumption_round_trips_without_dead_state() -> void:
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 5000)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 500)
	Inventory.add_resource(ResourceTypes.ResourceId.PROTECT_SYMBOL, 1)
	_unit.equipment_component.add_item(_build_item("protected_sword", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.Quality.BLUE, 7, EquipmentDefinitions.NO_SET, 5))
	_unit.equipment_component.equip_item(&"protected_sword")
	var seed := _find_seed_for_result(&"protected_sword", 5, "protected")
	assert_true(seed > 0, "Fixture should find a deterministic protected-failure seed")

	_unit.equipment_component.get_item(&"protected_sword").enhancement_level = 5
	Inventory.deserialize({
		ResourceTypes.ResourceId.GOLD: 5000,
		ResourceTypes.ResourceId.BASIC_MATERIAL: 500,
		ResourceTypes.ResourceId.PROTECT_SYMBOL: 1,
	})
	var result: Dictionary = _unit.equipment_component.attempt_enhancement(&"protected_sword", Inventory, true, seed)
	assert_eq(result.get("result", ""), "protected")

	var saved_unit: Dictionary = _unit.serialize()
	var saved_inventory := Inventory.serialize()
	var loaded := Unit.new()
	add_child(loaded)
	loaded.deserialize(saved_unit)
	Inventory.deserialize(saved_inventory)

	assert_eq(loaded.equipment_component.get_item(&"protected_sword").enhancement_level, 5)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.PROTECT_SYMBOL), 0)
	assert_true(Inventory.get_amount(ResourceTypes.ResourceId.GOLD) < 5000)
	loaded.queue_free()

func _find_seed_for_result(item_id: StringName, level: int, expected_result: String) -> int:
	for seed in range(1, 500):
		_unit.equipment_component.get_item(item_id).enhancement_level = level
		Inventory.deserialize({
			ResourceTypes.ResourceId.GOLD: 5000,
			ResourceTypes.ResourceId.BASIC_MATERIAL: 500,
			ResourceTypes.ResourceId.PROTECT_SYMBOL: 1,
		})
		var result: Dictionary = _unit.equipment_component.attempt_enhancement(item_id, Inventory, true, seed)
		if String(result.get("result", "")) == expected_result:
			return seed
	return -1
