extends Gut

func test_rank_ceiling_enforcement() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"defend"))
	skill.rank = SkillDefinitions.Rank.BASIC
	skill.level = 10
	skill.max_proficiency = 200
	skill.proficiency = 190
	skill.apply_proficiency_gain(30, 0.0, 0.0)
	assert_eq(skill.level, 10)
	assert_eq(skill.proficiency, 200, "Overflow should be capped at the current threshold while blocked")

func test_rank_advancement_when_conditions_met() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	skill.level = 10
	assert_true(skill.can_advance_rank(50, false))
	assert_true(skill.advance_rank(50, false))
	assert_eq(skill.rank, SkillDefinitions.Rank.INTERMEDIATE)

func test_rank_advancement_unlocks_effects() -> void:
	var skill := SkillData.new(SkillDefinitions.get_definition(&"fireball"))
	skill.level = 10
	skill.advance_rank(50, false)
	assert_true(skill.unlocked_effects.size() > 0)
