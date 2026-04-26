class_name GuardStance
extends RefCounted

## Guard stance damage share system.
## When an NPC (王秀) is attacked and has an adjacent ally (guardian),
## damage is split between NPC and guardian per guard_transfer_ratio.
##
## Belongs to: Story CH2-c-003
## GDD: design/gdd/chapter-02.md §3.4, §4.2

## Default guard transfer ratio (30%). Loaded from chapter_02_config.json.
const DEFAULT_GUARD_TRANSFER_RATIO: float = 0.30

var _guard_transfer_ratio: float = DEFAULT_GUARD_TRANSFER_RATIO

## Load config from external data.
func load_config(config: Dictionary) -> void:
	_guard_transfer_ratio = config.get("guard_transfer_ratio", DEFAULT_GUARD_TRANSFER_RATIO)

## Result struct for guard stance calculation.
class GuardResult:
	var npc_damage: int
	var guardian_damage: int
	var guardian: Object
	var was_guard_active: bool

## Evaluates and returns the guard stance result.
## Callers should apply npc_damage to the NPC and guardian_damage to the guardian.
func evaluate(incoming_damage: int, has_guardian: bool, guardian_speed_rank: int = 0) -> GuardResult:
	var result := GuardResult.new()
	result.guardian_damage = 0

	if not has_guardian or incoming_damage <= 0:
		result.npc_damage = incoming_damage
		result.was_guard_active = false
		return result

	result.was_guard_active = true
	result.guardian_damage = int(roundf(incoming_damage * _guard_transfer_ratio))
	result.npc_damage = incoming_damage - result.guardian_damage
	return result
