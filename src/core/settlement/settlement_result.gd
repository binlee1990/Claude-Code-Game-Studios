class_name SettlementResult
extends RefCounted

## Result of a battle settlement trigger. Downstream reward systems
## (exp, evaluation, drops) read `type` and enrich this result; this class
## holds only the core outcome.
##
## Implements: Story BS-001 (Settlement Trigger & Flow)
## GDD Reference: design/gdd/battle-settlement.md — Section C.1, E.1, E.5

enum SettlementType { VICTORY, DEFEAT, RETREAT }

## The outcome category. Drives downstream reward pipelines.
var type: int = SettlementType.VICTORY

## Surviving player units at settlement time. Used by downstream EXP
## distribution (GDD D.1 — exp = total / surviving count).
var surviving_players: Array = []

## Surviving enemy units (empty on victory, possibly >0 on retreat or early defeat).
var surviving_enemies: Array = []

## True only for VICTORY — unlocks full reward pipeline (exp, gold, materials, eval).
## Implements GDD C.1: defeat and retreat skip the full reward pipeline.
var rewards_enabled: bool = false


## Returns a plain Dictionary for serialization or cross-system transport.
func to_dict() -> Dictionary:
	return {
		"type": type,
		"rewards_enabled": rewards_enabled,
		"surviving_player_ids": _unit_ids(surviving_players),
		"surviving_enemy_ids": _unit_ids(surviving_enemies),
	}


func _unit_ids(units: Array) -> Array:
	var out: Array = []
	for u in units:
		out.append(String(u.unit_id))
	return out
