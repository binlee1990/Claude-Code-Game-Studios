# Factory helpers for SRPG test suite.
# Preload in test files: const Factory = preload("res://tests/helpers/factory_helpers.gd")

class_name FactoryHelpers
extends RefCounted

## Create a minimal battle unit stub with default values.
static func make_unit(id: String = "test_unit", pos: Vector2i = Vector2i(0, 0), hp: int = 100, team: int = 0) -> Dictionary:
	return {
		"unit_id": id,
		"grid_pos": pos,
		"hp": hp,
		"max_hp": hp,
		"team": team,
		"agility": 60,
		"attack": 10,
		"defense": 5,
	}

## Create a minimal boss profile for testing.
static func make_boss_profile(boss_id: String = "test_boss", boss_type: int = 0) -> Resource:
	const BossProfile = preload("res://src/core/boss/boss_profile.gd")
	var bp := BossProfile.new()
	bp.boss_id = boss_id
	bp.boss_type = boss_type
	bp.display_name = "Test Boss"
	return bp

## Create a boss action pattern with specified parameters.
static func make_action_pattern(pattern_id: String = "test_pattern", cooldown: int = 2, dmg_mult: float = 1.0, targets: int = 0, telegraph: float = 0.7) -> Resource:
	const BossActionPattern = preload("res://src/core/boss/boss_action_pattern.gd")
	var ap := BossActionPattern.new()
	ap.pattern_id = pattern_id
	ap.cooldown_turns = cooldown
	ap.damage_multiplier = dmg_mult
	ap.targets = targets
	ap.telegraph_duration = telegraph
	return ap

## Create a combo skill data stub for testing.
static func make_combo_data(combo_id: String = "test_combo", bond_type: int = 0, ap_cost: int = 1, cooldown: int = 2) -> Resource:
	const ComboSkillData = preload("res://src/core/bond/combo_skill_data.gd")
	var cs := ComboSkillData.new()
	cs.combo_id = combo_id
	cs.bond_type = bond_type
	cs.ap_cost = ap_cost
	cs.cooldown_turns = cooldown
	return cs

## Create a fog state stub for testing.
static func make_fog_state(width: int = 10, height: int = 10) -> Dictionary:
	var cells: Array[Array] = []
	for y in height:
		var row: Array[int] = []
		row.resize(width)
		row.fill(0)
		cells.append(row)
	return {
		"grid_width": width,
		"grid_height": height,
		"cells": cells,
		"explored_cells": cells.duplicate(true),
	}

## Returns a default difficulty config dictionary.
static func make_difficulty_config() -> Dictionary:
	return {
		"phase": 0,
		"enemy_multiplier": 0.7,
		"exp_multiplier": 1.0,
		"drop_multiplier": 1.0,
	}
