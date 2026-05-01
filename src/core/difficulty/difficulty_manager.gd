class_name DifficultyManager
extends Node

const PHASE_TUTORIAL: int = 1
const PHASE_GROWTH: int = 2
const PHASE_CHALLENGE: int = 3
const PHASE_CLIMAX: int = 4

const UNAFFECTED_SYSTEMS: Array[String] = ["bond", "belief", "attribute_growth", "save"]

var _phase_curve: Dictionary = {}
var _ng_multiplier: float = 1.0
var _current_chapter: int = 1


func _ready() -> void:
	_load_phase_curve()


func _load_phase_curve() -> void:
	var file: FileAccess = FileAccess.open("res://assets/data/difficulty/phase_curve.json", FileAccess.READ)
	if file:
		var text: String = file.get_as_text()
		file.close()
		var json: Variant = JSON.parse_string(text)
		if json != null and json is Dictionary and (json as Dictionary).has("phases"):
			_phase_curve = json


func _set_phase_curve_for_test(data: Dictionary) -> void:
	_phase_curve = data


func get_profile(chapter: int = -1) -> Dictionary:
	var ch: int = chapter if chapter >= 1 else _current_chapter
	var phase: int = _chapter_to_phase(ch)
	var phases: Array = _phase_curve.get("phases", [])
	for p: Variant in phases:
		var entry: Dictionary = p as Dictionary
		if entry.get("phase", 0) == phase:
			return {
				"phase": phase,
				"enemy_stat_mult": float(entry.get("enemy_stat_mult", 1.0)) * _ng_multiplier,
				"exp_mult": float(entry.get("exp_mult", 1.0)),
				"resource_mult": float(entry.get("resource_mult", 1.0)),
				"ai_strategy_level": int(entry.get("ai_strategy_level", 0)),
			}
	return _default_profile()


func _chapter_to_phase(chapter: int) -> int:
	if chapter <= 2:
		return PHASE_TUTORIAL
	elif chapter <= 5:
		return PHASE_GROWTH
	elif chapter <= 8:
		return PHASE_CHALLENGE
	else:
		return PHASE_CLIMAX


func _default_profile() -> Dictionary:
	return {"phase": PHASE_GROWTH, "enemy_stat_mult": 1.0, "exp_mult": 1.0, "resource_mult": 1.0, "ai_strategy_level": 0}


func scale_enemy_stat(base_value: float) -> float:
	return base_value * get_enemy_stat_multiplier()


func get_enemy_stat_multiplier() -> float:
	return float(_get_current_profile().get("enemy_stat_mult", 1.0))


func get_exp_multiplier() -> float:
	return float(_get_current_profile().get("exp_mult", 1.0))


func get_resource_multiplier() -> float:
	return float(_get_current_profile().get("resource_mult", 1.0))


func get_ai_strategy_level() -> int:
	return int(_get_current_profile().get("ai_strategy_level", 0))


func set_current_chapter(chapter: int) -> void:
	_current_chapter = chapter


func _get_current_profile() -> Dictionary:
	return get_profile(_current_chapter)


func is_system_affected(system_name: String) -> bool:
	return system_name not in UNAFFECTED_SYSTEMS


func get_ng_multiplier() -> float:
	return _ng_multiplier
