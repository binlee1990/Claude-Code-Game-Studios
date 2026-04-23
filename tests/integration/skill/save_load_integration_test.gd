extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "SkillSaveUnit"
	_unit.unit_id = &"skill_save"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func test_full_skill_state_round_trip() -> void:
	_unit.class_component.initialize(ClassNames.ClassID.BASIC_MAGE, ClassNames.ClassState.BASIC_ACTIVE, {}, false)
	_unit.skill_component.bind_to_unit(_unit, _unit.class_component)
	var fireball: SkillData = _unit.skill_component.get_skill(&"fireball")
	fireball.level = 15
	fireball.rank = SkillDefinitions.Rank.INTERMEDIATE
	fireball.proficiency = 450
	fireball.max_proficiency = 800
	fireball.select_trait(10, "damage_20")
	fireball.cooldown_remaining = 1

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "LoadedSkillSaveUnit"
	add_child(loaded)
	loaded.deserialize(saved)
	var loaded_fireball: SkillData = loaded.skill_component.get_skill(&"fireball")
	assert_eq(loaded_fireball.level, 15)
	assert_eq(loaded_fireball.rank, SkillDefinitions.Rank.INTERMEDIATE)
	assert_eq(loaded_fireball.proficiency, 450)
	assert_eq(loaded_fireball.cooldown_remaining, 1)
	assert_eq(loaded_fireball.get_trait_multiplier(), 1.2)
	loaded.queue_free()

func test_frozen_class_skill_preserved() -> void:
	var heavy: SkillData = _unit.skill_component.get_skill(&"heavy_strike")
	heavy.level = 8
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_true(heavy.frozen)

	var saved: Dictionary = _unit.serialize()
	var loaded := Unit.new()
	loaded.name = "LoadedFrozenSkillUnit"
	add_child(loaded)
	loaded.deserialize(saved)
	var loaded_heavy: SkillData = loaded.skill_component.get_skill(&"heavy_strike")
	assert_true(loaded_heavy.frozen)
	assert_eq(loaded_heavy.level, 8)
	loaded.queue_free()

func test_double_round_trip_identical() -> void:
	_unit.learn_skill(&"defend")
	var defend: SkillData = _unit.skill_component.get_skill(&"defend")
	defend.level = 11
	defend.rank = SkillDefinitions.Rank.INTERMEDIATE
	defend.proficiency = 210
	defend.max_proficiency = 420
	defend.select_trait(10, "damage_20")

	var saved1: Dictionary = _unit.serialize()
	var loaded1 := Unit.new()
	add_child(loaded1)
	loaded1.deserialize(saved1)
	var saved2: Dictionary = loaded1.serialize()
	var loaded2 := Unit.new()
	add_child(loaded2)
	loaded2.deserialize(saved2)

	var skill1: SkillData = loaded1.skill_component.get_skill(&"defend")
	var skill2: SkillData = loaded2.skill_component.get_skill(&"defend")
	assert_eq(skill2.level, skill1.level)
	assert_eq(skill2.rank, skill1.rank)
	assert_eq(skill2.proficiency, skill1.proficiency)
	assert_eq(skill2.get_selected_trait_ids().size(), skill1.get_selected_trait_ids().size())

	loaded1.queue_free()
	loaded2.queue_free()
