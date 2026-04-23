extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "FinalAttrUnit"
	add_child(_unit)
	var comp: AttributeComponent = _unit.attributes.get_component(AttributeNames.Attribute.STR)
	comp.load_data({
		"value": 50,
		"potential": 3,
		"barrier_stage": 1,
		"barriers_broken": {1: false, 2: false, 3: false},
		"thresholds_reached": {}
	})

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _equip_str_item(item_id: String, slot: int, bonus: int, set_id: int = EquipmentDefinitions.NO_SET) -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": item_id,
		"slot": slot,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"affixes": [{
			"type": EquipmentDefinitions.AffixType.STR,
			"value": bonus,
			"attribute_type": AttributeNames.Attribute.STR,
			"stat_key": "",
			"category": EquipmentDefinitions.AffixCategory.ATTACK,
		}],
		"set_id": set_id,
	}))
	_unit.equipment_component.equip_item(StringName(item_id))

func test_final_attribute_uses_base_class_and_equipment_bonus() -> void:
	_equip_str_item("blade", EquipmentDefinitions.Slot.WEAPON, 8, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_equip_str_item("armor", EquipmentDefinitions.Slot.ARMOR, 5, EquipmentDefinitions.SetId.WARRIOR_POWER)
	assert_eq(_unit.get_equipment_bonus(AttributeNames.Attribute.STR), 23)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 83)

func test_unequip_recalculates_effective_attribute() -> void:
	_equip_str_item("blade", EquipmentDefinitions.Slot.WEAPON, 8, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_equip_str_item("armor", EquipmentDefinitions.Slot.ARMOR, 5, EquipmentDefinitions.SetId.WARRIOR_POWER)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 83)
	_unit.equipment_component.unequip_slot(EquipmentDefinitions.Slot.WEAPON)
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.STR), 65)

func test_equipment_changed_signal_emitted_on_equip_and_unequip() -> void:
	var seen: Array = []
	_unit.equipment_component.equipment_changed.connect(func(slot, old_id, new_id): seen.append([slot, old_id, new_id]))
	_equip_str_item("blade", EquipmentDefinitions.Slot.WEAPON, 8)
	_unit.equipment_component.unequip_slot(EquipmentDefinitions.Slot.WEAPON)
	assert_eq(seen.size(), 2)
