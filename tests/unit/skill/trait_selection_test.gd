extends Gut

func test_trait_event_trigger() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	skill.level = 9
	skill.max_proficiency = 10
	skill.proficiency = 9
	var result: Dictionary = skill.apply_proficiency_gain(1, 0.0, 0.0)
	assert_eq(skill.level, 10)
	assert_eq(result["trait_triggers"].size(), 1)
	assert_eq(result["trait_triggers"][0]["level"], 10)

func test_trait_application() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	assert_true(skill.select_trait(10, "damage_20"))
	assert_eq(skill.get_trait_multiplier(), 1.2)

func test_deferred_trait_has_no_bonus() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	skill.level = 10
	skill.pending_trait_levels[10] = true
	assert_eq(skill.get_trait_multiplier(), 1.0)
	assert_eq(skill.get_range_bonus(), 0)
