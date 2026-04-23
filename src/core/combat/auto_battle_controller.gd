class_name AutoBattleController
extends RefCounted

## Delegates player unit decisions to the AI system when auto-battle is enabled.
## Tracks per-unit manual overrides for the current turn and coordinates with
## AIBrain for target, skill, and position selection.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted after enabled state changes. Listeners use this to update UI state.
signal toggled(enabled: bool)

## Emitted when a player requests manual control for the current unit's turn.
signal manual_override_activated(unit: Unit)

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _enabled: bool = false

## Units that have an active manual override for the current turn.
## Cleared per-unit after their turn ends via clear_override().
var _manual_overrides: Dictionary = {}

## Injected AI decision engine. Must be set before calling delegate_turn().
var _ai_brain: AIBrain

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

## Inject the AIBrain instance used for all AI decisions.
## Dependency injection keeps this class unit-testable without a scene tree.
func _init(brain: AIBrain) -> void:
	_ai_brain = brain

# ---------------------------------------------------------------------------
# Toggle API
# ---------------------------------------------------------------------------

## Enable or disable auto-battle.
## Toggle is immediate: the NEXT unit to begin its turn is affected.
## The unit currently acting finishes its in-flight action uninterrupted.
func set_enabled(on: bool) -> void:
	if _enabled == on:
		return
	_enabled = on
	GameEvents.auto_battle_toggled.emit(on)
	toggled.emit(on)

## Returns true when auto-battle mode is active.
func is_enabled() -> bool:
	return _enabled

# ---------------------------------------------------------------------------
# Override API
# ---------------------------------------------------------------------------

## Grant manual control to a player unit for the current turn only.
## The override is cleared automatically when clear_override() is called
## at the end of that unit's turn, so the next turn reverts to AI control.
func request_manual_override(unit: Unit) -> void:
	_manual_overrides[unit] = true
	GameEvents.manual_override_activated.emit(unit)
	manual_override_activated.emit(unit)

## Remove the manual override for a unit after its turn ends.
## Called by CombatSystem.end_turn() so callers never manage this directly.
func clear_override(unit: Unit) -> void:
	_manual_overrides.erase(unit)

# ---------------------------------------------------------------------------
# Decision gate
# ---------------------------------------------------------------------------

## Returns true if the AI should make decisions for this unit this turn.
## False when: auto-battle is OFF, or the unit has an active manual override.
func should_auto_control(unit: Unit) -> bool:
	if not _enabled:
		return false
	if _manual_overrides.has(unit):
		return false
	return true

# ---------------------------------------------------------------------------
# Delegation
# ---------------------------------------------------------------------------

## Delegate a full unit turn to the AI: chooses action, target, and position.
##
## Parameters match the AIBrain interface directly so callers pass context
## without this class querying the scene:
##   unit            — the acting player unit
##   skills          — available skill dictionaries (may be empty)
##   basic_attack    — basic attack dictionary (may be empty if unavailable)
##   targets         — candidate target unit IDs
##   hp_map          — Dictionary[int -> int] mapping unit ID to current HP
##   killable_ids    — subset of targets that can be killed this turn
##   attacker_weapon — WeaponType enum value for the acting unit
##   target_weapons  — Dictionary[int -> int] mapping target ID to WeaponType
##   positions       — Array of position candidate Dictionaries
##   current_pos_score — score of the unit's current position (stay if no better)
##
## Returns a Dictionary with keys:
##   "action"       — the chosen action Dictionary from AIBrain.select_action()
##   "target_id"    — int, chosen target unit ID (-1 if no targets)
##   "position_idx" — int, index into positions array (-1 means stay put)
##
## Edge case (GDD E.5): if the chosen action cannot be executed (e.g. skill MP
## exhausted, item depleted), the CALLER is responsible for skipping that
## sub-action. This method returns the AI's best-effort decision without
## checking resource availability.
func delegate_turn(
	unit: Unit,
	skills: Array[Dictionary],
	basic_attack: Dictionary,
	targets: Array[int],
	hp_map: Dictionary,
	killable_ids: Array[int],
	attacker_weapon: int,
	target_weapons: Dictionary,
	positions: Array[Dictionary],
	current_pos_score: float
) -> Dictionary:
	# Action selection (skill or basic attack fallback)
	var chosen_action: Dictionary = _ai_brain.select_action(skills, basic_attack)

	# Target selection (-1 when no targets available)
	var chosen_target: int = -1
	if not targets.is_empty():
		chosen_target = _ai_brain.select_target_with_restraint(
			targets, hp_map, killable_ids, attacker_weapon, target_weapons
		)

	# Position selection (-1 means stay at current position)
	var chosen_position: int = _ai_brain.select_position(positions, current_pos_score)

	return {
		"action": chosen_action,
		"target_id": chosen_target,
		"position_idx": chosen_position,
	}

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

## Serialize auto-battle enabled flag.
## Manual overrides are per-turn transient state and are NOT persisted.
## Implements Story 007 (design/gdd/turn-based-mode.md AC-S3).
func serialize() -> Dictionary:
	return {"enabled": _enabled}

## Restore auto-battle state from serialized data.
## Manual overrides are cleared — they are per-turn only and do not survive a load.
## Direct assignment — does NOT emit toggled signal (loading is not a user action).
func deserialize(data: Dictionary) -> void:
	_enabled = data.get("enabled", false)
	_manual_overrides.clear()
