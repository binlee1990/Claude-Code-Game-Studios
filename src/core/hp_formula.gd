class_name HpFormula
extends RefCounted

## Centralized max HP formula.
## Formula: max_hp = class_base_hp + CON × CON_COEFFICIENT + class_level × LEVEL_COEFFICIENT + equipment_hp_bonus
## Outside combat units are always full HP — current HP is tracked by combat_system only.

const CON_COEFFICIENT: int = 5
const LEVEL_COEFFICIENT: int = 3

## Calculate a unit's max HP from class base, CON, class level, and equipment bonuses.
## Returns 0 when any required component is missing (unit pre-_ready, freed, or detached).
static func calculate_max_hp(unit: Unit) -> int:
	if not is_instance_valid(unit):
		return 0
	if not is_instance_valid(unit.class_component):
		return 0
	var class_id: int = unit.class_component.get_class_id()
	var class_base: int = ClassNames.get_class_base_hp(class_id)
	var con: int = unit.get_effective_attribute(AttributeNames.Attribute.CON)
	var level: int = unit.class_component.get_class_level()
	var equip_bonus: int = equipment_hp_bonus(unit)
	return class_base + con * CON_COEFFICIENT + level * LEVEL_COEFFICIENT + equip_bonus

## Total HP bonus from equipped items.
## Aggregates the "hp" stat bonus across every equipped affix and active set.
## Backed by EquipmentComponent.get_stat_bonus("hp"), which already integrates
## affix totals (AffixType.HP) and 4-piece set bonuses (e.g. WARRIOR_POWER).
static func equipment_hp_bonus(unit: Unit) -> int:
	if not is_instance_valid(unit):
		return 0
	if not is_instance_valid(unit.equipment_component):
		return 0
	return int(unit.equipment_component.get_stat_bonus("hp"))
