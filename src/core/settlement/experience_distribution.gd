class_name ExperienceDistribution
extends RefCounted

## Pure math for battle-exp distribution (Story BS-002).
## GDD battle-settlement.md C.2, D.1, D.2, E.4.
## All methods are deterministic and stateless. No signals, no mutations of external state.
## Evaluation bonus is provided as a float by the caller (BS-003 is out of scope here).

# ---------------------------------------------------------------------------
# Enemy EXP table (GDD C.2)
# ---------------------------------------------------------------------------

## Standard enemy EXP tiers (GDD C.2).
enum EnemyTier { NORMAL, ELITE, HARD, BOSS }

## EXP awarded per defeated enemy by tier (GDD C.2).
## Tuning knob: safe ranges documented in battle-settlement.md Tuning Knobs section.
const ENEMY_EXP_TABLE: Dictionary = {
	EnemyTier.NORMAL: 50,
	EnemyTier.ELITE:  150,
	EnemyTier.HARD:   300,
	EnemyTier.BOSS:   1000,
}

## Evaluation bonus floats (GDD C.5, D.2). Mirrors the values BS-003 will output.
## Defeat (rewards_enabled=false) never reaches this distributor.
const EVAL_BONUS: Dictionary = {
	"perfect":   0.5,
	"excellent": 0.2,
	"normal":    0.0,
}

# ---------------------------------------------------------------------------
# AC.2.1 — EXP computation (GDD D.1)
# ---------------------------------------------------------------------------

## Compute total base EXP from a list of defeated enemy tiers.
## [param enemy_tiers] Array of EnemyTier int values. Unknown tiers contribute 0.
static func compute_total_exp(enemy_tiers: Array) -> int:
	var total: int = 0
	for tier in enemy_tiers:
		if ENEMY_EXP_TABLE.has(tier):
			total += ENEMY_EXP_TABLE[tier]
	return total


## Distribute EXP equally among surviving units (GDD D.1: integer floor division).
## Returns 0 when surviving_count <= 0 — caller must not invoke on defeat.
static func per_unit_exp(total_exp: int, surviving_count: int) -> int:
	if surviving_count <= 0:
		return 0
	return total_exp / surviving_count

# ---------------------------------------------------------------------------
# AC-E1 — Evaluation bonus (GDD D.2)
# ---------------------------------------------------------------------------

## Apply evaluation bonus to base EXP. GDD D.2: final = floor(base × (1 + bonus)).
## Returns 0 when base_exp <= 0.
static func apply_evaluation_bonus(base_exp: int, evaluation_bonus: float) -> int:
	if base_exp <= 0:
		return 0
	return int(floor(float(base_exp) * (1.0 + evaluation_bonus)))

# ---------------------------------------------------------------------------
# Orchestration helper
# ---------------------------------------------------------------------------

## Full pipeline: enemy_tiers + eval_bonus + surviving_count → per-unit EXP.
## Evaluation bonus is applied to the total pool before per-unit division (GDD D.2).
## [param enemy_tiers] Array of EnemyTier int values.
## [param surviving_count] Number of surviving player units (GDD D.1).
## [param evaluation_bonus] Float bonus from BS-003 (0.0, 0.2, or 0.5).
static func distribute(enemy_tiers: Array, surviving_count: int, evaluation_bonus: float) -> int:
	var base: int = compute_total_exp(enemy_tiers)
	var boosted: int = apply_evaluation_bonus(base, evaluation_bonus)
	return per_unit_exp(boosted, surviving_count)

# ---------------------------------------------------------------------------
# AC-E2 — Overflow / consecutive level-up helper (GDD E.4)
# ---------------------------------------------------------------------------

## Apply [param incoming] EXP to a unit at [param current] progress within a level
## of size [param cap], computing cascading level-ups and residual (GDD E.4).
##
## This is a pure math helper; it does NOT mutate ClassComponent or any scene node.
## The caller is responsible for applying the result.
##
## Returns a Dictionary:
##   "applied"   : int  — incoming EXP consumed (equals [param incoming] unless cap<=0)
##   "overflow"  : int  — residual EXP at the final level (< cap); same as "current"
##   "level_ups" : int  — number of whole levels gained
##   "current"   : int  — final in-level progression value (< cap)
##
## Precondition: cap > 0. When cap <= 0 returns a defensive all-zero dict.
## When incoming <= 0 returns a no-op dict preserving [param current].
##
## Example: current=900, cap=1000, incoming=500 → {applied:500, overflow:400, level_ups:1, current:400}
## Example: current=0,   cap=100,  incoming=250 → {applied:250, overflow:50,  level_ups:2, current:50}
static func apply_with_overflow(current: int, cap: int, incoming: int) -> Dictionary:
	if cap <= 0:
		return {"applied": 0, "overflow": 0, "level_ups": 0, "current": current}
	if incoming <= 0:
		return {"applied": 0, "overflow": 0, "level_ups": 0, "current": current}
	var total: int = current + incoming
	var level_ups: int = total / cap
	var residual: int = total % cap
	return {
		"applied":   incoming,
		"overflow":  residual,
		"level_ups": level_ups,
		"current":   residual,
	}
