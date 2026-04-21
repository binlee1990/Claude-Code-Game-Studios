class_name AIBrain
extends RefCounted

## AI decision engine: skill selection, position scoring, boss phases.

var ai_type: int = AI.AIType.BALANCED
var threat_system: ThreatSystem
var _boss_phase: int = 0
var _boss_enraged: bool = false
var _boss_phase_thresholds: Array[float] = [AI.BOSS_PHASE_THRESHOLD]

signal boss_phase_changed(boss_id: int, new_phase: int, unlocked_skills: Array)

func _init(type: int = AI.AIType.BALANCED) -> void:
	ai_type = type
	threat_system = ThreatSystem.new()


# Skill selection

## Evaluate skill expected value
func evaluate_skill(skill_data: Dictionary) -> float:
	var category: int = skill_data.get("category", AI.SkillCategory.BASIC_ATTACK)
	var base_damage: int = skill_data.get("damage", 0)
	var hit_prob: float = skill_data.get("hit_probability", 1.0)
	var is_kill: bool = skill_data.get("is_kill", false)
	var kill_bonus: float = 2.0 if is_kill else 1.0

	var category_name: String = AI.SkillCategory.keys()[category].to_lower()
	var type_mult: float = AI.get_type_weight(ai_type, category_name)

	return base_damage * hit_prob * kill_bonus * type_mult

## Select best skill from available options
func select_skill(skills: Array[Dictionary]) -> Dictionary:
	if skills.is_empty():
		return {"action": "wait"}

	var best: Dictionary = {}
	var best_score: float = -1.0
	for skill in skills:
		var score: float = evaluate_skill(skill)
		if score > best_score:
			best_score = score
			best = skill
	best["score"] = best_score
	return best

## Select action with fallback to basic attack
func select_action(skills: Array[Dictionary], basic_attack: Dictionary = {}) -> Dictionary:
	if not skills.is_empty():
		return select_skill(skills)
	if not basic_attack.is_empty():
		basic_attack["action"] = "basic_attack"
		return basic_attack
	return {"action": "wait"}


# Target selection

## Select target with restraint preference
func select_target_with_restraint(
	targets: Array[int],
	hp_map: Dictionary,
	killable_ids: Array[int],
	attacker_weapon: int,
	target_weapons: Dictionary
) -> int:
	# Priority 1: killable targets (lowest HP)
	if not killable_ids.is_empty():
		return threat_system.select_target_with_priority(killable_ids, hp_map)

	# Priority 2: among non-killable, prefer restraint target
	var best_id: int = -1
	var best_score: float = -1.0
	for id in targets:
		var score: float = threat_system.get_threat(id)
		var target_weapon: int = target_weapons.get(id, -1)
		if TacticalFormulas.has_advantage(attacker_weapon, target_weapon):
			score *= 1.5
		var hp: int = hp_map.get(id, 9999)
		score += (9999 - hp) * 0.01  # Slight HP preference
		if score > best_score:
			best_score = score
			best_id = id
	return best_id


# Position scoring

## Calculate position score
func calculate_position_score(
	height: int,
	is_dangerous_element: bool,
	in_support_range: bool,
	distance_score: float
) -> float:
	var h_score: float = AI.get_height_score(height)
	var e_score: float = AI.POS_ELEMENT_DANGEROUS if is_dangerous_element else AI.POS_ELEMENT_NORMAL
	var s_score: float = AI.POS_SUPPORT_IN_RANGE if in_support_range else AI.POS_SUPPORT_OUT_RANGE
	return distance_score * h_score * e_score * s_score

## Select best position from candidates
func select_position(
	positions: Array[Dictionary],
	current_score: float
) -> int:
	var best_idx: int = -1
	var best_score: float = current_score
	for i in positions.size():
		var pos: Dictionary = positions[i]
		var score: float = calculate_position_score(
			pos.get("height", 1),
			pos.get("dangerous", false),
			pos.get("support", false),
			pos.get("distance_score", 0.5)
		)
		if score > best_score:
			best_score = score
			best_idx = i
	return best_idx  # -1 means stay


# Boss AI

## Check if boss should trigger phase switch
func check_boss_phase(current_hp_percent: float, boss_id: int = 0) -> bool:
	if _boss_enraged:
		return false
	if current_hp_percent <= AI.BOSS_PHASE_THRESHOLD:
		_boss_enraged = true
		_boss_phase += 1
		boss_phase_changed.emit(boss_id, _boss_phase, [])
		return true
	return false

## Get boss damage multiplier (enrage bonus)
func get_boss_damage_multiplier() -> float:
	return AI.BOSS_ENRAGE_DAMAGE_MULT if _boss_enraged else 1.0

func is_boss_enraged() -> bool:
	return _boss_enraged

func get_boss_phase() -> int:
	return _boss_phase


# Serialization

func get_data() -> Dictionary:
	return {
		"ai_type": ai_type,
		"threats": threat_system.serialize(),
		"boss_phase": _boss_phase,
		"boss_enraged": _boss_enraged,
	}

func load_data(data: Dictionary) -> void:
	if "ai_type" in data:
		ai_type = data["ai_type"]
	if "threats" in data:
		threat_system.deserialize(data["threats"])
	if "boss_phase" in data:
		_boss_phase = data["boss_phase"]
	if "boss_enraged" in data:
		_boss_enraged = data["boss_enraged"]
