# tests/unit/ai/target_skill_selection_test.gd
# Story 003: Target & Skill Selection
# Validates AC.3.1-3.3

extends Gut

var _brain: AIBrain

func before_each() -> void:
	_brain = AIBrain.new(AI.AIType.BALANCED)

# AC.3.1: Killable target priority (lowest HP among killable)

func test_killable_target_lowest_hp() -> void:
	_brain.threat_system.add_damage_threat(1, 100)
	_brain.threat_system.add_damage_threat(2, 50)
	_brain.threat_system.add_damage_threat(3, 20)
	var killable: Array[int] = [1, 3]
	var hp_map: Dictionary = {1: 20, 2: 80, 3: 15}
	var target: int = _brain.threat_system.select_target_with_priority(killable, hp_map)
	assert_eq(target, 3, "Lowest HP among killable (15)")

func test_no_killable_falls_back_to_threat() -> void:
	_brain.threat_system.add_damage_threat(1, 100)  # 10.0
	_brain.threat_system.add_damage_threat(2, 50)   # 5.0
	_brain.threat_system.add_damage_threat(3, 20)   # 2.0
	var target: int = _brain.select_target_with_restraint(
		[1, 2, 3], {1: 80, 2: 60, 3: 50}, [],
		TacticalFormulas.WeaponType.SWORD, {1: 1, 2: 1, 3: 1}
	)
	# No killable, no restraint advantage → highest threat wins
	assert_eq(target, 1, "Highest threat when none killable")


# AC.3.2: Restraint preference

func test_restraint_target_preferred() -> void:
	_brain.threat_system.add_damage_threat(1, 50)  # 5.0 threat
	_brain.threat_system.add_damage_threat(2, 50)  # 5.0 threat
	# Attacker=sword, target 1=spear (restraint), target 2=axe (no restraint)
	var target: int = _brain.select_target_with_restraint(
		[1, 2], {1: 50, 2: 50}, [],
		TacticalFormulas.WeaponType.SWORD,
		{1: TacticalFormulas.WeaponType.SPEAR, 2: TacticalFormulas.WeaponType.AXE}
	)
	assert_eq(target, 1, "Prefers restraint target")

func test_higher_hp_beats_restraint() -> void:
	_brain.threat_system.add_damage_threat(1, 10)  # 1.0 threat, restrainable
	_brain.threat_system.add_damage_threat(2, 100)  # 10.0 threat, not restrainable
	var target: int = _brain.select_target_with_restraint(
		[1, 2], {1: 50, 2: 10}, [],
		TacticalFormulas.WeaponType.SWORD,
		{1: TacticalFormulas.WeaponType.SPEAR, 2: TacticalFormulas.WeaponType.AXE}
	)
	assert_eq(target, 2, "High threat beats restraint when much higher")


# AC.3.3: Skill cooldown fallback

func test_all_cooldown_falls_to_basic() -> void:
	var basic: Dictionary = {"damage": 10, "hit_probability": 1.0, "category": AI.SkillCategory.BASIC_ATTACK}
	var result: Dictionary = _brain.select_action([], basic)
	assert_eq(result["action"], "basic_attack")

func test_no_skills_no_basic_waits() -> void:
	var result: Dictionary = _brain.select_action([], {})
	assert_eq(result["action"], "wait")

func test_skills_available_uses_best() -> void:
	var skills: Array[Dictionary] = [
		{"damage": 80, "hit_probability": 1.0, "category": AI.SkillCategory.DAMAGE},
	]
	var result: Dictionary = _brain.select_action(skills, {"damage": 10})
	assert_eq(result["damage"], 80, "Uses best available skill")
