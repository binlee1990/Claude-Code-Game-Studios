class_name SkillComponent
extends Node

## Per-unit skill container integrating progression, class skills, and persistence.

signal trait_selection_requested(skill_id: StringName, level: int, available_traits: Array)
signal skill_unlocked(skill_id: StringName)
signal skill_rank_advanced(skill_id: StringName, old_rank: int, new_rank: int)

var _owner_unit: Unit = null
var _class_component: ClassComponent = null
var _skills: Dictionary = {}

## Bind this component to a unit and its class component.
func bind_to_unit(unit: Unit, class_component: ClassComponent) -> void:
	_owner_unit = unit
	_class_component = class_component
	if not _class_component.class_changed.is_connected(_on_class_changed):
		_class_component.class_changed.connect(_on_class_changed)
	_unlock_class_skills(_class_component.get_class_id())

## Learn a normal skill by id. Returns false for unknown or class-only skills.
func learn_normal_skill(skill_id: StringName) -> bool:
	var def: Dictionary = SkillDefinitions.get_definition(skill_id)
	if def.is_empty() or def["source_type"] != SkillDefinitions.SourceType.NORMAL:
		return false
	return _ensure_skill(skill_id) != null

## Return the mutable SkillData for the given skill id.
func get_skill(skill_id: StringName) -> SkillData:
	return _skills.get(skill_id)

## Return all skill ids currently owned by the unit.
func get_skill_ids() -> Array:
	return _skills.keys()

## Return every current SkillData as an Array.
func get_all_skills() -> Array:
	var out: Array = []
	for skill_id in _skills:
		out.append(_skills[skill_id])
	return out

## Return active skills that are currently not on cooldown and have enough MP.
func get_available_active_skills(mp_available: int = 9999) -> Array:
	var out: Array = []
	for skill_id in _skills:
		var skill: SkillData = _skills[skill_id]
		if skill.is_available(mp_available):
			out.append(skill.serialize())
	return out

## Apply battle proficiency gain to a skill.
func apply_battle_proficiency(skill_id: StringName, base_proficiency: int, synergy_bonus: float = 0.0, talent_bonus: float = 0.0) -> Dictionary:
	var skill: SkillData = get_skill(skill_id)
	if skill == null:
		return {"gained": 0, "levels_gained": 0, "trait_triggers": []}
	var result: Dictionary = skill.apply_proficiency_gain(base_proficiency, synergy_bonus, talent_bonus)
	for trigger in result.get("trait_triggers", []):
		trait_selection_requested.emit(skill_id, trigger["level"], trigger["available_traits"])
	return result

## Attempt to advance the rank of a skill.
func advance_skill_rank(skill_id: StringName, hidden_attr_value: int = 0, challenge_passed: bool = false) -> bool:
	var skill: SkillData = get_skill(skill_id)
	if skill == null:
		return false
	var old_rank: int = skill.rank
	if not skill.advance_rank(hidden_attr_value, challenge_passed):
		return false
	skill_rank_advanced.emit(skill_id, old_rank, skill.rank)
	return true

## Select one trait for a milestone level on a skill.
func select_trait(skill_id: StringName, level: int, trait_id: String) -> bool:
	var skill: SkillData = get_skill(skill_id)
	if skill == null:
		return false
	return skill.select_trait(level, trait_id)

## Calculate skill damage using the owner unit's current relevant attribute.
func calculate_skill_damage(skill_id: StringName) -> int:
	var skill: SkillData = get_skill(skill_id)
	if skill == null:
		return 0
	var bonus: float = _get_attribute_bonus_for_skill(skill)
	return skill.calculate_damage(bonus)

## Mark a skill as used so its cooldown begins and GameEvents broadcasts it.
func use_skill(skill_id: StringName, targets: Array = []) -> bool:
	var skill: SkillData = get_skill(skill_id)
	if skill == null:
		return false
	skill.trigger_cooldown()
	GameEvents.skill_used.emit(_owner_unit, String(skill_id), targets)
	return true

## Tick cooldowns for all skills by one turn and emit readiness events.
func tick_cooldowns() -> void:
	for skill_id in _skills:
		var skill: SkillData = _skills[skill_id]
		var was_cooling: bool = skill.cooldown_remaining > 0
		skill.tick_cooldown()
		if was_cooling and skill.cooldown_remaining == 0:
			GameEvents.skill_cooldown_ready.emit(_owner_unit, String(skill_id))

## Serialize the entire skill inventory for persistence.
func get_data() -> Dictionary:
	var out: Dictionary = {}
	for skill_id in _skills:
		out[String(skill_id)] = (_skills[skill_id] as SkillData).serialize()
	return out

## Restore skill state from serialized data.
func load_data(data: Dictionary) -> void:
	_skills.clear()
	for skill_id_str in data:
		var entry: Dictionary = data[skill_id_str]
		_skills[StringName(skill_id_str)] = SkillData.deserialize(entry)

## Replace current skills with the class skills for an initial content setup.
func reset_to_class_skills(class_id: int) -> void:
	_skills.clear()
	_unlock_class_skills(class_id)

func _on_class_changed(old_class: int, new_class: int) -> void:
	_freeze_class_skills(old_class, new_class)
	_unlock_class_skills(new_class)

func _freeze_class_skills(old_class: int, new_class: int) -> void:
	var new_skill_ids: Array = SkillDefinitions.get_class_skill_ids(new_class)
	for skill_id in SkillDefinitions.get_class_skill_ids(old_class):
		var skill: SkillData = get_skill(skill_id)
		if skill == null:
			continue
		skill.frozen = not new_skill_ids.has(skill_id)

func _unlock_class_skills(class_id: int) -> void:
	for skill_id in SkillDefinitions.get_class_skill_ids(class_id):
		var skill: SkillData = _ensure_skill(skill_id)
		if skill == null:
			continue
		skill.frozen = false

func _ensure_skill(skill_id: StringName) -> SkillData:
	if _skills.has(skill_id):
		return _skills[skill_id]
	var def: Dictionary = SkillDefinitions.get_definition(skill_id)
	if def.is_empty():
		return null
	var skill := SkillData.new(def)
	_skills[skill_id] = skill
	skill_unlocked.emit(skill_id)
	if _owner_unit != null:
		GameEvents.skill_learned.emit(_owner_unit, String(skill_id))
	return skill

func _get_attribute_bonus_for_skill(skill: SkillData) -> float:
	if _owner_unit == null:
		return 0.0
	match skill.damage_type:
		SkillDefinitions.DamageType.PHYSICAL:
			return float(_owner_unit.get_effective_attribute(AttributeNames.Attribute.STR)) * 0.01
		SkillDefinitions.DamageType.MAGIC:
			return float(_owner_unit.get_effective_attribute(AttributeNames.Attribute.INT)) * 0.01
		_:
			return 0.0
