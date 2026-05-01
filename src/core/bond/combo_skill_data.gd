class_name ComboSkillData
extends Resource

enum BondType { COMRADE = 0, MENTOR = 1, RIVAL = 2, LOVER = 3 }
enum SkillType { DAMAGE = 0, TEMP_SKILL = 1, BUFF = 2, GUARD = 3 }

@export var skill_id: String = ""
@export var bond_type: int = 0
@export var skill_type: int = 0
@export var ap_cost: int = 2
@export var cooldown_turns: int = 3
@export var range_max: int = 3
@export var effect_params: Dictionary = {}


func get_display_name() -> String:
	match bond_type:
		BondType.COMRADE:
			return "协力一击"
		BondType.MENTOR:
			return "技能传授"
		BondType.RIVAL:
			return "竞争觉醒"
		BondType.LOVER:
			return "誓约守护"
		_:
			return skill_id


func get_default_cooldown() -> int:
	match bond_type:
		BondType.COMRADE:
			return 3
		BondType.MENTOR:
			return 5
		BondType.RIVAL:
			return 4
		BondType.LOVER:
			return 1
		_:
			return cooldown_turns
