class_name BattleEvaluation
extends RefCounted

## Pure classifier for battle performance rating (Story BS-003).
## GDD battle-settlement.md C.5.
## Produces a Rating enum and matching evaluation_bonus float compatible
## with ExperienceDistribution.apply_evaluation_bonus.
## All methods are deterministic and stateless. No signals, no external mutations.

# ---------------------------------------------------------------------------
# Rating enum (GDD C.5)
# ---------------------------------------------------------------------------

## Battle performance ratings (GDD C.5).
enum Rating { NORMAL, EXCELLENT, PERFECT, FAIL }

## EXP bonus multiplier per rating (GDD C.5, D.2).
## Tuning knob: adjust values in battle-settlement.md Tuning Knobs section.
## Defeat (FAIL) intentionally yields 0.0 — rewards_enabled=false path skips settlement.
const RATING_BONUS: Dictionary = {
	Rating.NORMAL:    0.0,
	Rating.EXCELLENT: 0.2,
	Rating.PERFECT:   0.5,
	Rating.FAIL:      0.0,
}

# ---------------------------------------------------------------------------
# AC.3.1 / AC.3.2 / AC.3.3 — Classification (GDD C.5)
# ---------------------------------------------------------------------------

## Classify a battle result into a Rating.
## Priority order (GDD C.5): FAIL > NORMAL > PERFECT > EXCELLENT.
## [param deaths] Total player unit deaths during battle (>= 0).
## [param total_damage_taken] Total HP lost across all player units (>= 0).
## [param is_defeat] When true forces FAIL regardless of other inputs.
## Returns a Rating enum int value.
static func classify(deaths: int, total_damage_taken: int, is_defeat: bool = false) -> int:
	if is_defeat:
		return Rating.FAIL
	if deaths > 0:
		return Rating.NORMAL
	if total_damage_taken <= 0:
		return Rating.PERFECT
	return Rating.EXCELLENT


## Return the EXP bonus float for a given Rating int.
## Unknown rating values return 0.0 defensively.
static func bonus_for(rating: int) -> float:
	return RATING_BONUS.get(rating, 0.0)

# ---------------------------------------------------------------------------
# Orchestration helper
# ---------------------------------------------------------------------------

## Classify and return both rating and bonus in one call.
## Returns {"rating": int, "bonus": float}.
## [param deaths] Total player unit deaths during battle (>= 0).
## [param total_damage_taken] Total HP lost across all player units (>= 0).
## [param is_defeat] When true forces FAIL regardless of other inputs.
static func evaluate(deaths: int, total_damage_taken: int, is_defeat: bool = false) -> Dictionary:
	var rating: int = classify(deaths, total_damage_taken, is_defeat)
	return {"rating": rating, "bonus": bonus_for(rating)}
