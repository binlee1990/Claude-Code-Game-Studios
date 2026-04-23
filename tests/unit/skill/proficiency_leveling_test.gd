extends Gut

func test_proficiency_gain_calculation() -> void:
	assert_eq(SkillData.calculate_proficiency_gain(30, 0.2, 0.0), 36)
	assert_eq(SkillData.calculate_proficiency_gain(50, 0.2, 0.3), 75)

func test_level_up_trigger() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"defend"))
	skill.level = 5
	skill.base_cost = 100
	skill.max_proficiency = 200
	skill.proficiency = 150
	var result: Dictionary = skill.apply_proficiency_gain(50, 0.2, 0.0)
	assert_eq(result["gained"], 60)
	assert_eq(result["levels_gained"], 1)
	assert_eq(skill.level, 6)
	assert_eq(skill.proficiency, 10)

func test_overflow_can_trigger_multiple_levels() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"defend"))
	skill.level = 1
	skill.base_cost = 1
	skill.max_proficiency = 5
	skill.proficiency = 4
	var result: Dictionary = skill.apply_proficiency_gain(20, 0.0, 0.0)
	assert_true(result["levels_gained"] >= 2, "Overflow should support chained level-ups")
	assert_true(skill.level >= 3)
