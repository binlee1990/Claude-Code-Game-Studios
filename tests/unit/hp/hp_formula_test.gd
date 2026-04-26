# tests/unit/hp_formula_test.gd
# HP System (design/gdd/hp-system.md)
# Validates AC-1 (formula), AC-2 (Unit API), AC-6 (equipment bonus),
# AC-7 (null safety) and the F-3 worked examples.

extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "HPFormulaUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func _set_attr(attr: int, value: int) -> void:
	var comp: AttributeComponent = _unit.attributes.get_component(attr)
	comp.load_data({
		"value": value, "potential": 3,
		"barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false},
		"thresholds_reached": {}
	})

func _set_basic_class_level(class_id: int, level: int) -> void:
	# Basic class: exp_cap = 1000, level = exp/cap + 1, so for level N: exp = (N-1)*1000
	var class_exp: int = (level - 1) * ClassNames.EXP_CAP_BASIC
	_unit.class_component.initialize(
		class_id, ClassNames.ClassState.BASIC_ACTIVE, {class_id: class_exp}, false
	)

func _equip_hp_affix_item(item_id: String, slot: int, hp_value: int) -> void:
	var item := EquipmentItem.new({
		"item_id": item_id,
		"slot": slot,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"affixes": [{
			"type": EquipmentDefinitions.AffixType.HP,
			"value": hp_value,
			"stat_key": "hp",
			"category": EquipmentDefinitions.AffixCategory.SURVIVAL,
		}],
		"base_attributes": {},
		"set_id": EquipmentDefinitions.NO_SET,
	})
	_unit.equipment_component.add_item(item)
	_unit.equipment_component.equip_item(StringName(item_id))

func _equip_warrior_power_piece(slot: int) -> void:
	var item_id := "wpset_%d" % slot
	var item := EquipmentItem.new({
		"item_id": item_id,
		"slot": slot,
		"quality": EquipmentDefinitions.Quality.BLUE,
		"affixes": [],
		"base_attributes": {},
		"set_id": EquipmentDefinitions.SetId.WARRIOR_POWER,
	})
	_unit.equipment_component.add_item(item)
	_unit.equipment_component.equip_item(StringName(item_id))

# ---------- Constants & Tables ----------

func test_hp_formula_constants_match_design() -> void:
	assert_eq(HpFormula.CON_COEFFICIENT, 5, "CON_COEFFICIENT")
	assert_eq(HpFormula.LEVEL_COEFFICIENT, 3, "LEVEL_COEFFICIENT")

func test_class_base_hp_table_spot_check_matches_design_f2() -> void:
	# Spot-check 5 representative classes from F-2 of hp-system.md
	assert_eq(ClassNames.get_class_base_hp(ClassNames.ClassID.BASIC_WARRIOR), 40)
	assert_eq(ClassNames.get_class_base_hp(ClassNames.ClassID.BASIC_MAGE), 25)
	assert_eq(ClassNames.get_class_base_hp(ClassNames.ClassID.BASIC_KNIGHT), 50)
	assert_eq(ClassNames.get_class_base_hp(ClassNames.ClassID.ADV_PALADIN), 55)
	assert_eq(ClassNames.get_class_base_hp(ClassNames.ClassID.SPC_DRAGONKNIGHT), 60)

func test_class_base_hp_unknown_class_returns_default_30() -> void:
	# Edge case: an out-of-range class_id falls back to 30 (defensive default)
	assert_eq(ClassNames.get_class_base_hp(-999), 30)

# ---------- F-3 Worked Examples ----------

# F-3 Example 1: 新手剑士 — Lv1 BASIC_WARRIOR, effective CON=10, no equipment
# max_hp = 40 + 10×5 + 1×3 + 0 = 93
func test_hp_formula_basic_warrior_lv1_con10_no_equip_equals_93() -> void:
	# Arrange — BASIC_WARRIOR has CON +5 bonus, so base=5 → effective=10
	_set_basic_class_level(ClassNames.ClassID.BASIC_WARRIOR, 1)
	_set_attr(AttributeNames.Attribute.CON, 5)

	# Act
	var max_hp: int = _unit.get_max_hp()

	# Assert
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 10, "effective CON")
	assert_eq(_unit.class_component.get_class_level(), 1, "class level")
	assert_eq(max_hp, 93)

# F-3 Example 2: Lv5 法师 — BASIC_MAGE, effective CON=10, no equipment
# max_hp = 25 + 10×5 + 5×3 + 0 = 90
func test_hp_formula_basic_mage_lv5_con10_no_equip_equals_90() -> void:
	# Arrange — BASIC_MAGE has CON -5 bonus, so base=15 → effective=10
	_set_basic_class_level(ClassNames.ClassID.BASIC_MAGE, 5)
	_set_attr(AttributeNames.Attribute.CON, 15)

	# Act
	var max_hp: int = _unit.get_max_hp()

	# Assert
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 10, "effective CON")
	assert_eq(_unit.class_component.get_class_level(), 5, "class level")
	assert_eq(max_hp, 90)

# F-3 Example 3: Lv5 骑士（无装备）— BASIC_KNIGHT, effective CON=20, no equipment
# max_hp = 50 + 20×5 + 5×3 + 0 = 165
func test_hp_formula_basic_knight_lv5_con20_no_equip_equals_165() -> void:
	# Arrange — BASIC_KNIGHT has CON +15 bonus, so base=5 → effective=20
	_set_basic_class_level(ClassNames.ClassID.BASIC_KNIGHT, 5)
	_set_attr(AttributeNames.Attribute.CON, 5)

	# Act
	var max_hp: int = _unit.get_max_hp()

	# Assert
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 20, "effective CON")
	assert_eq(max_hp, 165)

# ---------- Equipment HP Bonus ----------

# F-3 Example 6 fragment: a single HP affix contributes its full value
func test_equipment_hp_bonus_with_hp_affix_50_returns_50() -> void:
	_set_basic_class_level(ClassNames.ClassID.BASIC_WARRIOR, 1)
	_set_attr(AttributeNames.Attribute.CON, 5)
	_equip_hp_affix_item("vital_amulet", EquipmentDefinitions.Slot.ACCESSORY, 50)

	assert_eq(HpFormula.equipment_hp_bonus(_unit), 50)
	# 40 + 50 + 3 + 50 = 143
	assert_eq(_unit.get_max_hp(), 143)

# F-3 Example 4: WARRIOR_POWER 2-piece set already provides hp:100 (and STR:+10)
func test_equipment_hp_bonus_warrior_power_2piece_returns_100() -> void:
	_set_basic_class_level(ClassNames.ClassID.BASIC_KNIGHT, 5)
	_set_attr(AttributeNames.Attribute.CON, 5)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.WEAPON)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.ARMOR)

	assert_eq(HpFormula.equipment_hp_bonus(_unit), 100)
	# 50 + 100 + 15 + 100 = 265
	assert_eq(_unit.get_max_hp(), 265)

# F-3 Example 5: 4-piece adds effects only — total HP bonus stays at 100
func test_equipment_hp_bonus_warrior_power_4piece_still_100_hp() -> void:
	_set_basic_class_level(ClassNames.ClassID.BASIC_KNIGHT, 5)
	_set_attr(AttributeNames.Attribute.CON, 5)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.WEAPON)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.ARMOR)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.HELMET)
	_equip_warrior_power_piece(EquipmentDefinitions.Slot.LEGS)

	# 4-piece adds double_damage_chance (effect), not hp — total still 100
	assert_eq(HpFormula.equipment_hp_bonus(_unit), 100)
	# 50 + 100 + 15 + 100 = 265 (matches 2-piece scenario)
	assert_eq(_unit.get_max_hp(), 265)

# ---------- Edge Cases (AC-7) ----------

func test_calculate_max_hp_null_unit_returns_0() -> void:
	assert_eq(HpFormula.calculate_max_hp(null), 0)

func test_equipment_hp_bonus_null_unit_returns_0() -> void:
	assert_eq(HpFormula.equipment_hp_bonus(null), 0)

# Edge case: zero-CON survival baseline still positive (base + level only)
func test_hp_formula_basic_warrior_lv1_con_zero_returns_class_plus_level_plus_class_bonus() -> void:
	_set_basic_class_level(ClassNames.ClassID.BASIC_WARRIOR, 1)
	_set_attr(AttributeNames.Attribute.CON, 0)
	# base=0 + class+5 = effective=5
	# max_hp = 40 + 5×5 + 1×3 + 0 = 68
	assert_eq(_unit.get_effective_attribute(AttributeNames.Attribute.CON), 5)
	assert_eq(_unit.get_max_hp(), 68)
