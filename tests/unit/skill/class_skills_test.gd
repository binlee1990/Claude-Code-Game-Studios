extends Gut

var _unit: Unit

func before_each() -> void:
	_unit = Unit.new()
	_unit.name = "SkillClassUnit"
	add_child(_unit)

func after_each() -> void:
	if is_instance_valid(_unit):
		_unit.queue_free()

func test_new_class_skill_unlock() -> void:
	assert_ne(_unit.skill_component.get_skill(&"heavy_strike"), null)
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	var sword_qi: SkillData = _unit.skill_component.get_skill(&"sword_qi")
	assert_ne(sword_qi, null)
	assert_eq(sword_qi.level, 1)

func test_old_class_skill_retained_but_frozen() -> void:
	var heavy: SkillData = _unit.skill_component.get_skill(&"heavy_strike")
	heavy.level = 8
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	assert_true(heavy.frozen)
	assert_eq(heavy.level, 8)

func test_new_class_skill_immediately_available() -> void:
	_unit.class_component.try_unlock_advanced()
	_unit.class_component.confirm_class_change(ClassNames.ClassID.ADV_SWORDMASTER)
	var skills: Array = _unit.skill_component.get_available_active_skills(100)
	var ids: Array = []
	for skill in skills:
		ids.append(String(skill["skill_id"]))
	assert_true(ids.has("sword_qi"))
