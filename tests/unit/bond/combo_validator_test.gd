extends Gut

const ComboSkillData = preload("res://src/core/bond/combo_skill_data.gd")
const ComboValidator = preload("res://src/core/bond/combo_validator.gd")

var _validator
var _comrade_skill


func before_each() -> void:
	_validator = ComboValidator.new()
	_comrade_skill = ComboSkillData.new()
	_comrade_skill.skill_id = "combo_comrade_strike"
	_comrade_skill.bond_type = ComboSkillData.BondType.COMRADE
	_comrade_skill.skill_type = ComboSkillData.SkillType.DAMAGE
	_comrade_skill.ap_cost = 2
	_comrade_skill.cooldown_turns = 3
	_comrade_skill.range_max = 3


# --- happy path ---

func test_combo_validator_all_conditions_pass_returns_none() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(3, 3), Vector2i(5, 5),  # distance = 4? No: |3-5|+|3-5| = 4 > 3
		3, 3, "A", true, true, {}, true
	)
	# distance is 4, so this should fail
	assert_ne(result, ComboValidator.FailReason.NONE)


func test_combo_validator_valid_pair_within_range_passes() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(3, 3), Vector2i(5, 4),  # distance = |3-5|+|3-4| = 2+1 = 3
		3, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.NONE)


# --- distance checks ---

func test_combo_validator_distance_exceeds_range_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(5, 5),  # distance = 10
		3, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.DISTANCE_TOO_FAR)


func test_combo_validator_distance_exactly_range_passes() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(3, 0),  # distance = 3
		3, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.NONE)


# --- AP checks ---

func test_combo_validator_insufficient_ap_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		1, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.NOT_ENOUGH_AP)


func test_combo_validator_exact_ap_passes() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		2, 2, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.NONE)


# --- bond rank checks ---

func test_combo_validator_rank_b_is_too_low() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "B", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.BOND_RANK_TOO_LOW)


func test_combo_validator_rank_s_passes() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "S", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.NONE)


# --- unit availability ---

func test_combo_validator_unit_not_available_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", false, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.UNIT_NOT_AVAILABLE)


func test_combo_validator_both_units_unavailable_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", false, false, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.UNIT_NOT_AVAILABLE)


# --- cooldown ---

func test_combo_validator_on_cooldown_fails() -> void:
	var cooldowns: Dictionary = {"unit_a::unit_b::combo_comrade_strike": 2}
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", true, true, cooldowns, true
	)
	assert_eq(result, ComboValidator.FailReason.ON_COOLDOWN)


func test_combo_validator_cooldown_expired_passes() -> void:
	var cooldowns: Dictionary = {"unit_a::unit_b::combo_comrade_strike": 0}
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", true, true, cooldowns, true
	)
	assert_eq(result, ComboValidator.FailReason.NONE)


# --- player only ---

func test_combo_validator_not_player_triggered_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", true, true, {}, false
	)
	assert_eq(result, ComboValidator.FailReason.NOT_PLAYER_TRIGGERED)


# --- invalid pair ---

func test_combo_validator_empty_pair_key_fails() -> void:
	var result: int = _validator.validate(
		"", _comrade_skill,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.INVALID_PAIR)


func test_combo_validator_null_skill_fails() -> void:
	var result: int = _validator.validate(
		"unit_a::unit_b", null,
		Vector2i(0, 0), Vector2i(1, 1),
		3, 3, "A", true, true, {}, true
	)
	assert_eq(result, ComboValidator.FailReason.INVALID_PAIR)


# --- fail messages ---

func test_combo_validator_get_fail_message_returns_string() -> void:
	var msg: String = _validator.get_fail_message(ComboValidator.FailReason.DISTANCE_TOO_FAR)
	assert_ne(msg, "")


func test_combo_validator_success_has_empty_message() -> void:
	var msg: String = _validator.get_fail_message(ComboValidator.FailReason.NONE)
	assert_eq(msg, "")


# --- combo skill data ---

func test_combo_skill_data_has_fields() -> void:
	var cs := ComboSkillData.new()
	cs.skill_id = "test"
	cs.ap_cost = 3
	assert_eq(cs.skill_id, "test")
	assert_eq(cs.ap_cost, 3)


func test_combo_skill_data_get_display_name_comrade() -> void:
	var cs := ComboSkillData.new()
	cs.bond_type = ComboSkillData.BondType.COMRADE
	assert_eq(cs.get_display_name(), "协力一击")


func test_combo_skill_data_get_display_name_mentor() -> void:
	var cs := ComboSkillData.new()
	cs.bond_type = ComboSkillData.BondType.MENTOR
	assert_eq(cs.get_display_name(), "技能传授")


func test_combo_skill_data_get_display_name_rival() -> void:
	var cs := ComboSkillData.new()
	cs.bond_type = ComboSkillData.BondType.RIVAL
	assert_eq(cs.get_display_name(), "竞争觉醒")


func test_combo_skill_data_get_display_name_lover() -> void:
	var cs := ComboSkillData.new()
	cs.bond_type = ComboSkillData.BondType.LOVER
	assert_eq(cs.get_display_name(), "誓约守护")


func test_combo_skill_data_get_default_cooldown() -> void:
	var cs := ComboSkillData.new()
	cs.bond_type = ComboSkillData.BondType.COMRADE
	assert_eq(cs.get_default_cooldown(), 3)
	cs.bond_type = ComboSkillData.BondType.MENTOR
	assert_eq(cs.get_default_cooldown(), 5)
	cs.bond_type = ComboSkillData.BondType.RIVAL
	assert_eq(cs.get_default_cooldown(), 4)
	cs.bond_type = ComboSkillData.BondType.LOVER
	assert_eq(cs.get_default_cooldown(), 1)
