extends Gut

func test_full_damage_formula() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	skill.level = 10
	skill.base_damage = 100
	skill.select_trait(10, "damage_20")
	assert_eq(skill.calculate_damage(0.5), 342)

func test_level_multiplier() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"defend"))
	skill.level = 1
	assert_eq_fTol(skill.get_level_multiplier(), 1.0, 0.0001)
	skill.level = 20
	assert_eq_fTol(skill.get_level_multiplier(), 2.9, 0.0001)
	skill.level = 99
	assert_eq_fTol(skill.get_level_multiplier(), 10.8, 0.0001)

func test_attribute_bonus_source() -> void:
	var physical_unit := Unit.new()
	physical_unit.name = "PhysicalUnit"
	physical_unit.class_component = null
	add_child(physical_unit)
	var str_comp: AttributeComponent = physical_unit.attributes.get_component(AttributeNames.Attribute.STR)
	str_comp.load_data({"value": 30, "potential": 3, "barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false}, "thresholds_reached": {}})
	var physical_skill: SkillData = physical_unit.skill_component.get_skill(&"heavy_strike")

	var magic_unit := Unit.new()
	magic_unit.name = "MagicUnit"
	add_child(magic_unit)
	magic_unit.class_component.initialize(ClassNames.ClassID.BASIC_MAGE, ClassNames.ClassState.BASIC_ACTIVE, {}, false)
	magic_unit.skill_component.bind_to_unit(magic_unit, magic_unit.class_component)
	var int_comp: AttributeComponent = magic_unit.attributes.get_component(AttributeNames.Attribute.INT)
	int_comp.load_data({"value": 60, "potential": 3, "barrier_stage": 1, "barriers_broken": {1: false, 2: false, 3: false}, "thresholds_reached": {}})
	var magic_skill: SkillData = magic_unit.skill_component.get_skill(&"fireball")

	assert_true(physical_unit.skill_component.calculate_skill_damage(&"heavy_strike") > physical_skill.base_damage)
	assert_true(magic_unit.skill_component.calculate_skill_damage(&"fireball") > magic_skill.base_damage)

	physical_unit.queue_free()
	magic_unit.queue_free()
