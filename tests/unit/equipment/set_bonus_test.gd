extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "SetUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _add_set_item(item_id: String, slot: int, set_id: int) -> void:
	_unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": item_id,
		"slot": slot,
		"quality": EquipmentDefinitions.Quality.GOLD,
		"set_id": set_id,
	}))
	_unit.equipment_component.equip_item(StringName(item_id))

func test_two_piece_bonus_activates() -> void:
	_add_set_item("war_blade", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_add_set_item("war_armor", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.SetId.WARRIOR_POWER)
	var active: Dictionary = _unit.equipment_component.get_active_set_bonuses()
	assert_true(active["active_sets"].has(EquipmentDefinitions.SetId.WARRIOR_POWER))
	assert_eq(_unit.equipment_component.get_equipment_bonus(AttributeNames.Attribute.STR), 10)
	assert_eq(_unit.equipment_component.get_stat_bonus("hp"), 100.0)

func test_four_piece_bonus_activates() -> void:
	_add_set_item("mage_staff", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.SetId.MAGE_WISDOM)
	_add_set_item("mage_armor", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.SetId.MAGE_WISDOM)
	_add_set_item("mage_helm", EquipmentDefinitions.Slot.HELMET, EquipmentDefinitions.SetId.MAGE_WISDOM)
	_add_set_item("mage_ring", EquipmentDefinitions.Slot.ACCESSORY, EquipmentDefinitions.SetId.MAGE_WISDOM)
	assert_eq(_unit.equipment_component.get_equipment_bonus(AttributeNames.Attribute.INT), 10)
	assert_eq(_unit.equipment_component.get_stat_bonus("mp"), 50.0)
	assert_eq(_unit.equipment_component.get_effect_bonus("skill_damage_mult"), 0.15)

func test_different_set_bonuses_stack_independently() -> void:
	_add_set_item("war_blade", EquipmentDefinitions.Slot.WEAPON, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_add_set_item("war_armor", EquipmentDefinitions.Slot.ARMOR, EquipmentDefinitions.SetId.WARRIOR_POWER)
	_add_set_item("archer_legs", EquipmentDefinitions.Slot.LEGS, EquipmentDefinitions.SetId.ARCHER_PRECISION)
	_add_set_item("archer_ring", EquipmentDefinitions.Slot.ACCESSORY, EquipmentDefinitions.SetId.ARCHER_PRECISION)
	assert_eq(_unit.equipment_component.get_equipment_bonus(AttributeNames.Attribute.STR), 10)
	assert_eq(_unit.equipment_component.get_equipment_bonus(AttributeNames.Attribute.AGI), 10)
	assert_eq(_unit.equipment_component.get_stat_bonus("hp"), 100.0)
	assert_eq(_unit.equipment_component.get_stat_bonus("crit_rate"), 5.0)
