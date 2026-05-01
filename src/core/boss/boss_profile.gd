class_name BossProfile
extends Resource

enum BossType { TUTORIAL = 0, NARRATIVE = 1, APTITUDE = 2, PEAK = 3, HIDDEN = 4 }

const BOSS_TYPE_DEFAULTS: Dictionary = {
	0: {"default_phases": 1, "default_patterns": 2, "hint_level": 2, "label": "tutorial"},
	1: {"default_phases": 2, "default_patterns": 3, "hint_level": 1, "label": "narrative"},
	2: {"default_phases": 2, "default_patterns": 3, "hint_level": 0, "label": "aptitude"},
	3: {"default_phases": 3, "default_patterns": 4, "hint_level": 0, "label": "peak"},
	4: {"default_phases": 4, "default_patterns": 5, "hint_level": 0, "label": "hidden"},
}

@export var boss_id: String = ""
@export var boss_type: int = 0
@export var display_name: String = ""
@export var phases: Array = []
@export var action_patterns: Array = []
@export var checkpoint: Resource = null


func get_type_default(key: String) -> int:
	var defaults: Dictionary = BOSS_TYPE_DEFAULTS.get(boss_type, BOSS_TYPE_DEFAULTS[0])
	return int(defaults.get(key, 0))


func get_label() -> String:
	var defaults: Dictionary = BOSS_TYPE_DEFAULTS.get(boss_type, BOSS_TYPE_DEFAULTS[0])
	return String(defaults.get("label", "tutorial"))
