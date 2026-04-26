class_name BossPhaseController
extends RefCounted

## Boss three-phase state machine with checkpoint and reinforcement logic.
## Designed for Boss·陈朗 (Ch.2-3) but reusable for any multi-phase boss.
##
## Belongs to: Story CH2-c-005
## GDD: design/gdd/chapter-02.md §3.6 / design/gdd/boss-system.md F1/F2

signal phase_changed(old_phase: int, new_phase: int)
signal checkpoint_saved(phase: int, boss_hp: int)
signal reinforcements_triggered(turn: int)

enum Phase {
	PHASE_1,  # 飞骑先锋 (100%–65%)
	PHASE_2,  # 狂骑突阵 (64%–30%)
	PHASE_3,  # 孤注一掷 (29%–0%)
	DEFEATED,
}

## Chen Lang specific thresholds (GDD §3.6). Data-driven via load_config.
var _phase_thresholds: Array[float] = [0.65, 0.30]
var _checkpoint_hp_ratio: float = 0.15
var _reinforce_trigger_turn: int = 12
var _reinforce_phase3_early_turn: int = 10

var _current_phase: Phase = Phase.PHASE_1
var _boss_max_hp: int = 130
var _boss_current_hp: int = 130
var _current_turn: int = 1

## Checkpoint stack: [{phase, boss_hp, player_units_snapshot}]
var _checkpoints: Array[Dictionary] = []

## Reinforcement state
var _reinforcements_spawned: bool = false
var _reinforcement_scheduled_turn: int = 12

## Load config from external data (chapter_02_config.json).
func load_config(config: Dictionary) -> void:
	var raw_thresholds: Array = config.get("boss_phase_thresholds", [0.65, 0.30])
	_phase_thresholds.clear()
	for v in raw_thresholds:
		_phase_thresholds.append(float(v))
	_checkpoint_hp_ratio = config.get("checkpoint_retained_hp_ratio", 0.15)
	_reinforce_trigger_turn = config.get("reinforce_trigger_turn", 12)
	_reinforce_phase3_early_turn = config.get("reinforce_phase3_early_turn", 10)
	_reinforcement_scheduled_turn = _reinforce_trigger_turn
	if config.has("boss_max_hp"):
		_boss_max_hp = config["boss_max_hp"]
		_boss_current_hp = _boss_max_hp

## Initialize with boss HP. Call before battle starts.
func init(max_hp: int, start_turn: int = 1) -> void:
	_boss_max_hp = max_hp
	_boss_current_hp = max_hp
	_current_turn = start_turn
	_current_phase = Phase.PHASE_1
	_checkpoints.clear()
	_reinforcements_spawned = false
	_reinforcement_scheduled_turn = _reinforce_trigger_turn

## Call when boss takes damage. Checks phase transitions.
## Returns array of phase transitions that occurred (may be >1 if HP skips thresholds).
func on_boss_hp_changed(new_hp: int) -> Array[Dictionary]:
	_boss_current_hp = maxi(new_hp, 0)
	var hp_pct: float = float(_boss_current_hp) / float(_boss_max_hp)
	var transitions: Array[Dictionary] = []

	# Check each threshold from current phase onward
	while _current_phase != Phase.DEFEATED and _current_phase != Phase.PHASE_3:
		var next_phase_idx: int = _current_phase + 1
		if next_phase_idx > Phase.PHASE_3:
			break
		var threshold: float
		if next_phase_idx == Phase.PHASE_2:
			threshold = _phase_thresholds[0]  # 0.65
		elif next_phase_idx == Phase.PHASE_3:
			threshold = _phase_thresholds[1]  # 0.30
		else:
			break

		if hp_pct > threshold:
			break

		# Phase transition
		var old_phase: Phase = _current_phase
		_current_phase = next_phase_idx
		_save_checkpoint(old_phase)
		transitions.append({
			"old_phase": old_phase,
			"new_phase": _current_phase,
		})
		phase_changed.emit(old_phase, _current_phase)

		# Phase 3 special: schedule early reinforcements
		if _current_phase == Phase.PHASE_3 and _current_turn < _reinforce_phase3_early_turn:
			_reinforcement_scheduled_turn = _reinforce_phase3_early_turn

	# Check defeat
	if _boss_current_hp <= 0 and _current_phase != Phase.DEFEATED:
		var old_phase: Phase = _current_phase
		_current_phase = Phase.DEFEATED
		transitions.append({"old_phase": old_phase, "new_phase": Phase.DEFEATED})
		phase_changed.emit(old_phase, Phase.DEFEATED)

	return transitions

## Call at the start of each round to check reinforcement spawn.
func on_round_start(turn: int) -> Dictionary:
	_current_turn = turn
	if _reinforcements_spawned:
		return {"spawn": false}
	if turn >= _reinforcement_scheduled_turn:
		_reinforcements_spawned = true
		reinforcements_triggered.emit(turn)
		return {"spawn": true, "turn": turn, "count": 2}
	return {"spawn": false}

## Restore boss to last checkpoint. Returns checkpoint data.
func restore_last_checkpoint() -> Dictionary:
	if _checkpoints.is_empty():
		# No checkpoint: restart from full HP, phase 1
		return {
			"boss_hp": _boss_max_hp,
			"phase": Phase.PHASE_1,
			"player_snapshot": {},
		}
	var cp: Dictionary = _checkpoints[-1]
	_boss_current_hp = int(float(_boss_max_hp) * _checkpoint_hp_ratio)
	_current_phase = cp["phase"]
	return cp

## Get current phase.
func get_current_phase() -> Phase:
	return _current_phase

## Get current phase as int.
func get_current_phase_index() -> int:
	return _current_phase

## Get boss current HP.
func get_boss_hp() -> int:
	return _boss_current_hp

## Get boss max HP.
func get_boss_max_hp() -> int:
	return _boss_max_hp

## Check if reinforcements have been spawned.
func are_reinforcements_spawned() -> bool:
	return _reinforcements_spawned

## Get scheduled reinforcement turn.
func get_reinforcement_turn() -> int:
	return _reinforcement_scheduled_turn

func _save_checkpoint(from_phase: Phase) -> void:
	var cp := {
		"phase": from_phase,
		"boss_hp": _boss_current_hp,
		"turn": _current_turn,
		"player_snapshot": {},  # Filled by combat system integration
	}
	_checkpoints.append(cp)
	checkpoint_saved.emit(from_phase, _boss_current_hp)
