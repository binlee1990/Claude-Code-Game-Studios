# ADR-0009: Victory System

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Feature (pure logic, decision table, RefCounted) |
| **Knowledge Risk** | LOW — `RefCounted`, `Dictionary`, enum comparison all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (DI Architecture — VictoryChecker follows RefCounted pattern), ADR-0003 (Unit Interface — reads `faction`, `is_alive`), ADR-0004 (Turn System — TurnManager calls `determine_winner()`) |
| **Enables** | Turn System implementation (consumes VictoryChecker return value for route decision), UI (consumes `match_ended` signal with winner + reason) |
| **Blocks** | Victory epic, Turn System FACTION_PHASE_ENDING routing |
| **Ordering Note** | Must be Accepted ninth (after ADR-0004 and ADR-0008), before Turn System implementation which depends on the `determine_winner()` contract |

## Context

### Problem Statement

Victory is the match-end decider — it determines who wins, why, and when the match terminates. Without a codified Victory ADR, the decision logic (elimination priority, turn cap fallback, draw conditions) would be scattered across Turn System code rather than centralized in a dedicated, testable pure function. VictoryChecker is the single source of truth for `end_reason` (Turn GDD F4 deprecated its own derivation in favor of VictoryChecker). This ADR codifies the complete 7-row decision table, the `alive_count` + `cap_breached` + `determine_winner` formulas, and the player-friendly fallback rule (mutual annihilation → PLAYER wins).

### Constraints

- VictoryChecker must be a pure function — same input, same output, no state across calls
- `end_reason` must have a single source of truth (VictoryChecker.determine_winner())
- Elimination priority > Turn Cap priority
- Both factions eliminated simultaneously → PLAYER wins (fallback)
- Turn Cap draw: `alive_p == alive_e > 0` → winner = NONE, reason = "turn_cap"
- Must handle degenerate cases: empty units array, all units dead, single-faction game

### Requirements

- `determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) → Dictionary{winner: Faction.Type, reason: String}`
- `alive_count(faction) → int` — internal helper
- `cap_breached = (turn_number > turn_cap)`
- 7-row decision table covering all elimination + turn_cap combinations
- `is_instance_valid()` guard for stale unit references

## Decision

**VictoryChecker is a RefCounted pure function with a single entry point `determine_winner(units, turn_number, turn_cap) → {winner, reason}`. It implements a 7-row decision table with elimination priority over turn cap. Both factions eliminated → PLAYER wins (player-friendly fallback). Turn cap with equal alive counts → NONE (draw). The `winner` and `reason` fields are the single source of truth consumed by Turn System's FACTION_PHASE_ENDING routing and emitted via `match_ended` signal.**

### VictoryChecker

```gdscript
# src/victory/victory_checker.gd
class_name VictoryChecker extends RefCounted

func determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary:
    assert(turn_number >= 1, "turn_number must be >= 1, got %d" % turn_number)
    assert(turn_cap >= 1, "turn_cap must be >= 1, got %d" % turn_cap)
    
    var alive_p: int = _alive_count(units, Faction.Type.PLAYER)
    var alive_e: int = _alive_count(units, Faction.Type.ENEMY)
    var cap_breached: bool = (turn_number > turn_cap)
    
    # ── Elimination branch (highest priority) ──
    if alive_p == 0 or alive_e == 0:
        var winner: Faction.Type
        if alive_p == 0 and alive_e == 0:
            winner = Faction.Type.PLAYER    # Mutual annihilation → PLAYER wins
        elif alive_p == 0:
            winner = Faction.Type.ENEMY
        else:
            winner = Faction.Type.PLAYER
        return { "winner": winner, "reason": "elimination" }
    
    # ── Turn cap branch ──
    if cap_breached:
        if alive_p > alive_e:
            return { "winner": Faction.Type.PLAYER, "reason": "turn_cap" }
        elif alive_e > alive_p:
            return { "winner": Faction.Type.ENEMY, "reason": "turn_cap" }
        else:
            return { "winner": Faction.Type.NONE, "reason": "turn_cap" }
    
    # ── No end condition ──
    return { "winner": Faction.Type.NONE, "reason": "" }

func _alive_count(units: Array[Unit], faction: Faction.Type) -> int:
    var count: int = 0
    for unit in units:
        if not is_instance_valid(unit):
            continue
        if unit.faction == faction and unit.is_alive():
            count += 1
    return count
```

### Decision Table (7 Rows)

| alive_p | alive_e | cap_breached | winner | reason |
|---------|---------|-------------|--------|--------|
| >0 | >0 | false | NONE | "" |
| >0 | >0 | true, alive_p > alive_e | PLAYER | "turn_cap" |
| >0 | >0 | true, alive_e > alive_p | ENEMY | "turn_cap" |
| >0 | >0 | true, alive_p == alive_e | NONE | "turn_cap" |
| >0 | 0 | — | PLAYER | "elimination" |
| 0 | >0 | — | ENEMY | "elimination" |
| 0 | 0 | — | PLAYER | "elimination" |

### Design Rationale

**Why elimination wins over turn cap**: The elimination branch executes first regardless of `cap_breached`. If the last ENEMY is killed on the same phase that `turn_number` crosses `turn_cap`, the result is `"elimination"` not `"turn_cap"`. Elimination is the definitive end — turn cap is a deadlock guard. This matches the priority in Turn GDD F4 and Victory GDD Core Rule 3.

**Why mutual annihilation → PLAYER wins**: Victory GDD Core Rule 5 specifies this player-friendly fallback. It's near-impossible in MVP (no counter-attack, no AoE) but the interface must define it. If both factions reach 0 alive simultaneously (future Tier 2 counter-attack or environmental damage), PLAYER wins.

**Why `is_instance_valid()` guard**: Units that have been `queue_free()`d may still be referenced in the `_all_units` array if their `unit_died` signal was bypassed (GDScript edge case). The guard skips stale references rather than crashing. Turn System's normal path removes units from `_all_units` in `_on_unit_died()`, making this guard a safety net.

**Why `NONE` winner with `reason=""` means "continue"**: This is the only case where `reason` is empty and `winner` is `NONE`. Turn System's routing rule is: `winner == NONE AND reason == ""` → continue to next FACTION_PHASE_ACTIVE; `winner != NONE OR reason != ""` → MATCH_ENDED. The Turn System can safely check `victory.winner != Faction.Type.NONE` as the sole routing condition since the only case with `winner == NONE` and `reason == ""` is "continue."

**Why assertions on turn_number/turn_cap**: Turn System guarantees `turn_number >= 1` (starts at 1, never decrements) and `turn_cap >= 1` (TurnConfig validates range [1,99]). The assertions catch caller bugs in dev builds. Invalid inputs produce a clear error message rather than silent wrong results.

## Alternatives Considered

### Alternative 1: VictoryChecker Returns Only winner (Turn Derives reason)

- **Description**: `determine_winner()` returns only `Faction.Type`; Turn System independently computes `end_reason` from context
- **Pros**: Simpler return type
- **Cons**: Two sources of truth for `end_reason` — the exact issue Turn GDD F4 deprecated. If VictoryChecker and Turn disagree on the reason, the `match_ended` signal carries inconsistent data.
- **Rejection Reason**: Victory GDD explicitly makes VictoryChecker the single source of truth for both winner and reason. This eliminates the Turn GDD F4 `end_reason` derivation conflict.

### Alternative 2: VictoryChecker as an Autoload (No DI)

- **Description**: VictoryChecker as an Autoload, accessible globally
- **Pros**: Zero wiring; any system can call `VictoryChecker.determine_winner()`
- **Cons**: Violates ADR-0002 DI pattern; hidden dependency; harder to test with mock units; no explicit dependency declaration
- **Rejection Reason**: ADR-0002 mandates DI for all logic objects. VictoryChecker is a pure function with zero construction cost — one `VictoryChecker.new()` call in Game._ready().

### Alternative 3: Configurable Win Conditions (Strategy Pattern)

- **Description**: `VictoryCondition` interface with `check(units, turn_number, turn_cap) → Result`. MVP uses `EliminationCondition` + `TurnCapCondition` chained by priority.
- **Pros**: Extensible for Tier 2+ alternative win conditions (score victory, escort, capture point)
- **Cons**: Over-engineered for MVP — two win conditions with fixed priority don't need a strategy pattern. The decision table (7 rows) is trivially readable as a single function.
- **Rejection Reason**: Deferred, not rejected. When Tier 2+ adds a third win condition, the 7-row decision table can be refactored into a priority-ordered list of `VictoryCondition` objects — zero API change to the `determine_winner()` return type.

## Consequences

### Positive

- Single source of truth for winner + reason — Turn System reads, doesn't derive
- 7-row decision table is exhaustive and trivially testable (7 unit tests cover all rows)
- `is_instance_valid()` guard prevents crashes on stale unit references
- Pure function — testable without scene tree, DI, or game state
- Same return type works for continue / elimination / turn_cap / draw — no sentinel confusion

### Negative

- `alive_count` iterates all units on every call (O(N) where N ≤ 8 at MVP — negligible)
- VictoryChecker must import `Faction.Type` — a dependency on the Core layer (expected; Victory is Feature layer)

### Risks

- **Risk**: Tier 2+ third faction (NEUTRAL) not handled by current `alive_count` — only counts PLAYER and ENEMY.
  - **Mitigation**: When a third faction is added, `alive_count` must be extended. The decision table is inherently two-faction — three-faction victory conditions require a redesign, not a patch. Documented in Victory GDD Edge Case ("三方阵营需要重写判定逻辑").

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| victory.md | Core Rule 1: VictoryChecker as RefCounted, DI | `extends RefCounted`, DI via ADR-0002 |
| victory.md | Core Rule 2: determine_winner interface | `determine_winner(units, turn_number, turn_cap) → {winner, reason}` |
| victory.md | Core Rule 3: Elimination > Turn Cap priority | Elimination branch executes first in decision logic |
| victory.md | Core Rule 4: 7-row decision table | All 7 rows implemented in if/else branches |
| victory.md | Core Rule 5: Both factions eliminated → PLAYER wins | `alive_p == 0 and alive_e == 0 → PLAYER` |
| victory.md | Core Rule 6: Turn Cap draw → NONE | `cap_breached and alive_p == alive_e → NONE, "turn_cap"` |
| victory.md | Core Rule 7: end_reason single source of truth | VictoryChecker returns `reason` — Turn reads it, doesn't derive |
| victory.md | F1: alive_count formula | `_alive_count(units, faction) → int`, with `is_instance_valid` guard |
| victory.md | F2: cap_breached formula | `turn_number > turn_cap` |
| victory.md | F3: determine_winner formula | Full decision tree with priority ordering |
| victory.md | All edge cases (empty units, all dead, turn_cap=1, stale references) | Handled by guards + decision table |
| turn.md | F4: end_reason deprecated — VictoryChecker authority | Confirmed: Turn reads `victory.reason` directly |
| game-concept.md | Pillar 2: System Orthogonality | Pure function, no side effects, explicit Unit dependency via parameter |

## Performance Implications

- **CPU**: `_alive_count` iterates all units (≤8 at MVP). O(N) integer comparison + one `is_instance_valid()` check per unit. <1μs. `determine_winner` = 2 × `_alive_count` + 1 comparison + 1 branch. <2μs total.
- **Memory**: One `Dictionary{winner, reason}` return value ≈ 40 bytes. Allocated per FACTION_PHASE_ENDING call (once per phase transition).
- **Load Time**: No impact — VictoryChecker created at Game._ready().

## Migration Plan

Greenfield. Implementation order:
1. Create `src/victory/victory_checker.gd` with `determine_winner()` + `_alive_count()`
2. Wire in Game._ready(): `var victory_checker := VictoryChecker.new()`
3. Inject into TurnManager per ADR-0004
4. Unit test all 7 decision table rows + edge cases (empty units, all dead, turn_cap boundary, stale reference)

## Validation Criteria

- [ ] Row 1: alive_p>0, alive_e>0, cap_breached=false → `{NONE, ""}`
- [ ] Row 2: alive_p>0, alive_e>0, cap_breached=true, alive_p>alive_e → `{PLAYER, "turn_cap"}`
- [ ] Row 3: alive_p>0, alive_e>0, cap_breached=true, alive_e>alive_p → `{ENEMY, "turn_cap"}`
- [ ] Row 4: alive_p>0, alive_e>0, cap_breached=true, alive_p==alive_e → `{NONE, "turn_cap"}`
- [ ] Row 5: alive_p>0, alive_e==0 → `{PLAYER, "elimination"}` regardless of cap_breached
- [ ] Row 6: alive_p==0, alive_e>0 → `{ENEMY, "elimination"}` regardless of cap_breached
- [ ] Row 7: alive_p==0, alive_e==0 → `{PLAYER, "elimination"}`
- [ ] Elimination priority: alive_e==0 AND cap_breached=true → `reason="elimination"` (not "turn_cap")
- [ ] Empty units array → `{PLAYER, "elimination"}` (both counts = 0)
- [ ] Single PLAYER unit alive, no ENEMY → `{PLAYER, "elimination}"`
- [ ] `is_instance_valid()` skips freed reference without crash → count adjusts
- [ ] `turn_number == turn_cap` → cap_breached = false (strict greater-than)
- [ ] `turn_number == turn_cap + 1` → cap_breached = true
- [ ] `turn_number = 0` input → assertion failure
- [ ] `turn_cap = 0` input → assertion failure
- [ ] Same input called 3 times → 3 identical results (pure function determinism)

## Related Decisions

- ADR-0002: Dependency Injection Architecture (VictoryChecker follows RefCounted DI pattern)
- ADR-0003: Unit Public Interface (reads `faction`, `is_alive` — both read-only)
- ADR-0004: Turn System Architecture (TurnManager calls `determine_winner()` in FACTION_PHASE_ENDING step 4)
- `design/gdd/victory.md` — Victory GDD (authoritative design)
- `design/gdd/turn.md` — Turn GDD F4 (end_reason deprecated in favor of VictoryChecker)
