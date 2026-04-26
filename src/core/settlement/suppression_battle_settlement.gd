class_name SuppressionBattleSettlement
extends RefCounted

## Suppression battle (Ch.2-2B) special settlement logic.
## Handles flee count, kill count comparison, and partial failure.
##
## Belongs to: Story CH2-c-004
## GDD: design/gdd/chapter-02.md §3.5, §5.9

const DEFAULT_FLEE_LIMIT: int = 4

var _flee_limit: int = DEFAULT_FLEE_LIMIT
var _player_kill_count: int = 0
var _npc_kill_count: int = 0
var _flee_count: int = 0

func load_config(config: Dictionary) -> void:
	_flee_limit = config.get("suppression_flee_limit", DEFAULT_FLEE_LIMIT)

## Record a fleeing civilian (civilian unit exits map edge).
func record_flee() -> void:
	_flee_count += 1

## Record player unit defeating an enemy.
func record_player_kill() -> void:
	_player_kill_count += 1

## Record NPC ally defeating an enemy.
func record_npc_kill() -> void:
	_npc_kill_count += 1

## Get flee count for this battle.
func get_flee_count() -> int:
	return _flee_count

## Returns true if flee count exceeds the limit (partial failure).
func is_partial_failure() -> bool:
	return _flee_count > _flee_limit

## Settlement result struct.
class Settlement:
	var belief_yi_delta: int
	var belief_zhi_delta: int
	var settlement_type: String  # "victory" | "partial_failure"

## Evaluates and returns the settlement result.
func evaluate() -> Settlement:
	var result := Settlement.new()
	result.belief_yi_delta = 0
	result.belief_zhi_delta = 0

	if is_partial_failure():
		result.settlement_type = "partial_failure"
		result.belief_yi_delta = -5  # 镇压失败：义-5
		return result

	result.settlement_type = "victory"
	if _player_kill_count > _npc_kill_count:
		result.belief_yi_delta = 3
		result.belief_zhi_delta = 2
	elif _npc_kill_count > _player_kill_count:
		result.belief_yi_delta = 10
		result.belief_zhi_delta = -5
	else:
		# Tie (including both 0): default to player advantage branch
		result.belief_yi_delta = 3
		result.belief_zhi_delta = 2

	return result

## Resets all counters for a new battle.
func reset() -> void:
	_player_kill_count = 0
	_npc_kill_count = 0
	_flee_count = 0
