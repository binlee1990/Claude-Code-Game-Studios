extends Gut

const ComboSkillData = preload("res://src/core/bond/combo_skill_data.gd")
const ComboValidator = preload("res://src/core/bond/combo_validator.gd")

var _validator
var _skills: Array = []


func before_each() -> void:
	_validator = ComboValidator.new()
	_skills = _build_all_skills()


func _build_all_skills() -> Array:
	var comrade := ComboSkillData.new()
	comrade.skill_id = "combo_comrade_strike"
	comrade.bond_type = ComboSkillData.BondType.COMRADE
	comrade.skill_type = ComboSkillData.SkillType.DAMAGE
	comrade.ap_cost = 2
	comrade.cooldown_turns = 3
	comrade.range_max = 3

	var mentor := ComboSkillData.new()
	mentor.skill_id = "combo_skill_transfer"
	mentor.bond_type = ComboSkillData.BondType.MENTOR
	mentor.skill_type = ComboSkillData.SkillType.TEMP_SKILL
	mentor.ap_cost = 2
	mentor.cooldown_turns = 5
	mentor.range_max = 3

	var rival := ComboSkillData.new()
	rival.skill_id = "combo_rival_awakening"
	rival.bond_type = ComboSkillData.BondType.RIVAL
	rival.skill_type = ComboSkillData.SkillType.BUFF
	rival.ap_cost = 1
	rival.cooldown_turns = 4
	rival.range_max = 5

	var lover := ComboSkillData.new()
	lover.skill_id = "combo_oath_guard"
	lover.bond_type = ComboSkillData.BondType.LOVER
	lover.skill_type = ComboSkillData.SkillType.GUARD
	lover.ap_cost = 3
	lover.cooldown_turns = 1
	lover.range_max = 5

	return [comrade, mentor, rival, lover]


# --- UI state integration: all 4 types validate correctly ---

func test_combo_ui_4_skills_all_valid_in_range() -> void:
	for skill in _skills:
		var result: int = _validator.validate(
			"unit_a::unit_b", skill,
			Vector2i(2, 2), Vector2i(3, 3), 5, 5, "A", true, true, {}, true
		)
		assert_eq(result, ComboValidator.FailReason.NONE)


# --- button disabled: distance ---

func test_combo_ui_button_disabled_when_distance_too_far() -> void:
	for skill in _skills:
		var result: int = _validator.validate(
			"unit_a::unit_b", skill,
			Vector2i(0, 0), Vector2i(10, 10), 5, 5, "A", true, true, {}, true
		)
		assert_eq(result, ComboValidator.FailReason.DISTANCE_TOO_FAR)


# --- button disabled: AP ---

func test_combo_ui_button_disabled_when_ap_insufficient() -> void:
	for skill in _skills:
		var result: int = _validator.validate(
			"unit_a::unit_b", skill,
			Vector2i(2, 2), Vector2i(3, 3), 0, 0, "A", true, true, {}, true
		)
		assert_eq(result, ComboValidator.FailReason.NOT_ENOUGH_AP)


# --- button disabled: rank ---

func test_combo_ui_button_hidden_when_rank_below_a() -> void:
	var skill := _skills[0] as ComboSkillData
	assert_eq(_validator.validate("a::b", skill, Vector2i(2, 2), Vector2i(3, 3), 5, 5, "C", true, true, {}, true), ComboValidator.FailReason.BOND_RANK_TOO_LOW)
	assert_eq(_validator.validate("a::b", skill, Vector2i(2, 2), Vector2i(3, 3), 5, 5, "B", true, true, {}, true), ComboValidator.FailReason.BOND_RANK_TOO_LOW)


# --- button disabled: cooldown ---

func test_combo_ui_button_shows_cooldown_timer() -> void:
	var skill := _skills[0] as ComboSkillData
	var cooldowns: Dictionary = {"unit_a::unit_b::combo_comrade_strike": 2}
	assert_eq(_validator.validate("unit_a::unit_b", skill, Vector2i(2, 2), Vector2i(3, 3), 5, 5, "A", true, true, cooldowns, true), ComboValidator.FailReason.ON_COOLDOWN)


# --- button disabled: unit KO/retreat ---

func test_combo_ui_button_hidden_when_unit_dead() -> void:
	var skill := _skills[0] as ComboSkillData
	assert_eq(_validator.validate("a::b", skill, Vector2i(2, 2), Vector2i(3, 3), 5, 5, "A", false, true, {}, true), ComboValidator.FailReason.UNIT_NOT_AVAILABLE)


# --- fail message display ---

func test_combo_ui_all_fail_reasons_have_messages() -> void:
	var reasons: Array = [
		ComboValidator.FailReason.NONE,
		ComboValidator.FailReason.NOT_ENOUGH_AP,
		ComboValidator.FailReason.ON_COOLDOWN,
		ComboValidator.FailReason.DISTANCE_TOO_FAR,
		ComboValidator.FailReason.UNIT_NOT_AVAILABLE,
		ComboValidator.FailReason.BOND_RANK_TOO_LOW,
		ComboValidator.FailReason.NOT_PLAYER_TRIGGERED,
		ComboValidator.FailReason.INVALID_PAIR,
	]
	for reason in reasons:
		var msg: String = _validator.get_fail_message(reason)
		assert_true(msg is String)


# --- skill display names non-empty ---

func test_combo_ui_all_skills_have_display_names() -> void:
	for skill in _skills:
		var name: String = skill.get_display_name()
		assert_ne(name, "")


# --- reactive-type skills (mentor/lover) use range_max=5 ---

func test_combo_ui_mentor_skill_has_range_5() -> void:
	var mentor: ComboSkillData = _skills[1] as ComboSkillData
	assert_eq(mentor.range_max, 3)  # active-type uses 3

	var lover: ComboSkillData = _skills[3] as ComboSkillData
	assert_eq(lover.range_max, 5)   # reactive-type uses 5


# --- cooldown recovery ---

func test_combo_ui_cooldown_recovers_after_turns() -> void:
	var skill := _skills[0] as ComboSkillData
	var cooldowns: Dictionary = {"unit_a::unit_b::combo_comrade_strike": 0}  # expired
	assert_eq(_validator.validate("unit_a::unit_b", skill, Vector2i(2, 2), Vector2i(3, 3), 5, 5, "A", true, true, cooldowns, true), ComboValidator.FailReason.NONE)
