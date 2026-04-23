extends Gut

func test_skill_object_contains_required_fields() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	assert_eq(skill.skill_id, &"fireball")
	assert_eq(skill.name, "Fireball")
	assert_eq(skill.source_type, SkillDefinitions.SourceType.CLASS)
	assert_eq(skill.usage_type, SkillDefinitions.UsageType.ACTIVE)
	assert_eq(skill.rank, SkillDefinitions.Rank.BASIC)
	assert_eq(skill.level, 1)
	assert_eq(skill.proficiency, 0)
	assert_eq(skill.mp_cost, 20)
	assert_eq(skill.cooldown, 2)
	assert_eq(skill.base_damage, 22)
	assert_true(skill.traits.has(10), "Traits table should exist")

func test_source_classification() -> void:
	var normal_skill := SkillData.new(SkillDefinitions.get_definition(&"defend"))
	var class_skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	assert_eq(normal_skill.source_type, SkillDefinitions.SourceType.NORMAL)
	assert_eq(class_skill.source_type, SkillDefinitions.SourceType.CLASS)

func test_usage_classification() -> void:
	var active_skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	var passive_skill := SkillData.new(SkillDefinitions.get_definition(&"magic_shield"))
	assert_eq(active_skill.usage_type, SkillDefinitions.UsageType.ACTIVE)
	assert_eq(passive_skill.usage_type, SkillDefinitions.UsageType.PASSIVE)
	assert_true(active_skill.mp_cost > 0)
	assert_eq(passive_skill.mp_cost, 0)
	assert_eq(passive_skill.cooldown, 0)
