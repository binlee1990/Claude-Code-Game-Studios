# Attack

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (damage formula reads Unit stats, returns result; Attack owns no state)

## Overview

Attack 是 SRPG 骨架中「Move+Attack」打包动作的后半部分 —— 也是玩家的决策兑现时刻。一个单位移动（或跳过移动）后, 系统读取其 `RNG` 属性, 在棋盘上高亮所有可攻击的敌方单位; 玩家悬停目标预览伤害数字, 点击确认, 伤害公式 `max(ATK − DEF, 1)` 立即结算 —— HP 减少, 若归零则单位死亡。整个过程是确定性的: 无命中率、无暴击、无反击。Attack 系统本身不持有任何状态 —— 它从 Unit 读取属性, 通过 Map 验证距离, 执行纯数学判定, 然后将结果写回 Unit 的 `take_damage()` 接口。没有 Attack 系统, 棋盘上的两个阵营将永远无法消灭对方 —— 移动失去了战略意义, 胜利条件永远无法触发。

## Player Fantasy

Attack 是「Move+Attack」打包动作的 **兑现时刻**。Movement 回答了"我去哪里?" — Attack 回答"谁死?" 

悬停一个在射程内的敌方目标, 伤害数字立刻浮现在单位上方。没有骰子, 没有祈祷, 没有隐藏数学 —— 只有 `ATK − DEF`, 在你悬停之前就可以心算出来。数字是一个承诺。点击让它成真。HP 下降。如果数字足够大, 单位从棋盘上消失。你为此做了定位。你赢得了这个结果。棋盘更干净了, 因为你的选择是正确的。

锚定时刻: **悬停一个残血敌人, 看到击杀数字出现, 点击, 看着它从棋盘上消失。**

确定性是区分点。在一类被显示命中率背叛了几十年的游戏中, 这个 Attack 系统直接说真话。没有"为什么会这样?"的时刻。情感回报不是兴奋 —— 是兑现。你知道会发生什么, 你让它发生了。

## Detailed Design

### Core Rules

1. **Attack Preconditions**: A unit may attack when:
   - `unit.is_alive == true`
   - `unit.faction == active_faction` (enforced by Input, not Attack)
   - `unit.action_state in [SELECTED, MOVED]` (per Unit GDD `can_attack()`)
   - `unit.has_acted_this_turn == false`

2. **Range**: Attack range is computed via Manhattan distance from the attacker's tile to the target's tile:
   
   `in_range(attacker_pos, target_pos) = |attacker.row − target.row| + |attacker.col − target.col| ≤ attacker.rng`
   
   The attacker's own tile (distance 0) is excluded — a unit cannot attack itself. RNG=1 means 4 adjacent tiles (N/S/E/W). RNG=2 means 12 tiles. RNG=3 means 24 tiles. This matches the Movement BFS's 4-neighbor spatial metaphor.

3. **Target Validation**: A tile contains a valid attack target when all of the following hold:
   - `Map.get_unit_at(tile) != null` — a unit exists at that tile
   - `target.is_alive == true` — the target is not dead
   - `target.faction != attacker.faction` — opposite faction only
   - `manhattan(attacker.grid_position, target.grid_position) ≤ attacker.rng` — within range

4. **Damage Formula**: `damage = max(attacker.atk − target.def, 1)` — deterministic, no RNG, no crit, floor at 1. Applied via `target.take_damage(damage)`. Formula defined fully in Section D (Formulas).

5. **Attack Execution**: When the player confirms an attack on a valid target:
   - Compute damage via `max(attacker.atk − target.def, 1)`
   - Call `target.take_damage(damage)`
   - Set `attacker.has_acted_this_turn = true`
   - Set `attacker.action_state = ACTED` (Unit GDD state machine)
   - All four operations are synchronous — no animation delay at MVP

6. **Attack Flow — Direct (from SELECTED)**: If the player clicks an enemy within RNG range while the unit is in SELECTED state:
   - Unit skips movement (equivalent to skip-move, Movement GDD Rule 5)
   - Attack executes immediately per Rule 5
   - Unit state: SELECTED → ACTED (via attack execution)
   - This is the standard "attack without moving" SRPG behavior

7. **Attack Flow — Post-Move (from MOVED)**: After unit enters MOVED state (Movement GDD Rule 6), the Input system automatically transitions to attack targeting:
   - `AttackRangeResolver` computes `get_valid_targets(unit, map)` — the list of all enemy units within RNG
   - UI highlights valid target tiles (distinct color from move highlights)
   - Player hovers a valid target → damage preview displayed
   - Player clicks a valid target → attack executes per Rule 5
   - Player right-clicks or presses Escape → skip attack, unit enters ACTED without dealing damage (Rule 8)

8. **Skip-Attack**: A unit in attack targeting mode (SELECTED or MOVED) may decline to attack:
   - Right-click or Escape clears attack highlights
   - `unit.has_acted_this_turn = true` — the action is still consumed
   - `unit.action_state = ACTED` — the unit's turn ends
   - No damage is dealt, no target is required

9. **No Counter-Attack (MVP)**: When a unit attacks, the defender does NOT retaliate. This is a deliberate MVP exclusion per game-concept.md. The interface slot for counter-attack is reserved — Attack emits a `damage_dealt(attacker, target, damage)` signal after execution; a future Tier 2 system could connect to this signal to trigger a counter-attack without modifying Attack internals.

10. **Attack is a Pure Computation**: `AttackResolver` is a `RefCounted` with a single entry point `execute_attack(attacker: Unit, target: Unit) -> AttackResult`. It owns no state, holds no references, and produces no side effects beyond the damage applied via `target.take_damage()`. The `AttackResult` is an immutable RefCounted containing `{damage: int, killed: bool, attacker: Unit, target: Unit}`. This follows the same pattern as Movement's `MovementResult` and Map's `GridSpace`.

11. **AttackRangeResolver**: A companion RefCounted with entry point `get_valid_targets(unit: Unit, map: Map) -> Array[Unit]`. Iterates all alive enemy units (`target.faction != unit.faction AND target.is_alive`), filters by Manhattan distance ≤ `unit.rng`. Returns the list sorted by distance (closest first), then by lowest HP (for tie-breaking at equal distance). The sorted list enables UI to prioritize display order and the future BasicAI to select the "best" target trivially.

12. **Damage Preview (resolve_damage)**: `AttackResolver.resolve_damage(atk: int, def: int) -> int` is a pure static method that computes `max(atk − def, 1)` without executing an attack. Used by UI/Input for hover damage preview. Takes raw stats, not Unit references — no side effects, no state read, no write.

13. **Constraints**:
    - Attacker must be alive. Dead units cannot attack.
    - Target must be alive. Dead units cannot be targeted (their tile is vacant per Map occupancy rules — `Map.get_unit_at()` returns null, so Rule 3 catches this naturally).
    - Same-faction targeting is rejected by Rule 3 faction check.
    - Range is Manhattan distance only — no diagonal attacks, no line-of-sight check at MVP.
    - Attack cannot target tiles beyond map bounds (Manhattan distance uses in-bounds coords; out-of-bounds units don't exist).
    - Attack is single-target only at MVP — no AoE/multi-target.

### States and Transitions

The Attack system operates within the Unit GDD state machine, adding the SELECTED → ACTED direct path:

| From | Trigger | To | Effect |
|------|---------|----|--------|
| `SELECTED` | Player clicks valid enemy target within RNG | `ACTED` | Direct attack — damage applied, `has_acted = true`, `damage_dealt` signal emitted |
| `SELECTED` (targeting) | Player right-clicks or presses Escape | `ACTED` | Skip-attack from SELECTED — no move, no attack, action consumed |
| `MOVED` (targeting) | Player clicks valid enemy target within RNG | `ACTED` | Post-move attack — damage applied, `has_acted = true`, `damage_dealt` signal emitted |
| `MOVED` (targeting) | Player right-clicks or presses Escape | `ACTED` | Skip-attack — no damage, `has_acted = true` |

Targeting mode is not a formal state in the state machine — it is a UI mode entered when a unit is in SELECTED or MOVED and has at least one valid target. The formal states remain IDLE / SELECTED / MOVED / ACTED / DEAD as defined in Unit GDD.

> Note: The Unit GDD state machine table currently shows IDLE → SELECTED → MOVED → ACTED. The SELECTED → ACTED direct path (attack without moving) and the cancel-from-targeting paths are additions. Unit GDD's state machine table should be updated to reflect these — flagged in Open Questions.

Turn System auto-advance reads `unit.has_acted_this_turn` (set by Attack Rules 5/8), not `action_state`. Attack does not need to notify Turn System — Turn polls this flag after each action.

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Map** | Upstream (reads) | Attack queries unit positions | `Map.get_unit_at(coord) → Unit` — target validation. Attack does NOT call `get_neighbors()` — range is Manhattan, not BFS-based. |
| **Unit** | Upstream (reads) | Attack reads attacker and defender stats | `attacker.atk: int`, `attacker.rng: int`, `attacker.grid_position: Vector2i`, `attacker.faction: Faction.Type`, `attacker.is_alive: bool`, `attacker.action_state`; same fields for target (`def`, `hp`, `faction`, `is_alive`) |
| **Unit** | Downstream (writes) | Attack applies damage | `target.take_damage(damage: int)` — damage computed by Attack, applied via Unit's interface |
| **Unit** | Downstream (writes) | Attack marks action consumed | `attacker.has_acted_this_turn = true`, `attacker.action_state = ACTED` |
| **Turn System** | Indirect | Attack completion feeds auto-advance | Turn polls `unit.has_acted_this_turn` after each action. Attack does not call Turn directly. |
| **UI / Input** | Downstream (data) | Attack provides target list and damage preview | `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]` — for highlight rendering. `AttackResolver.resolve_damage(atk, def) → int` — for hover damage preview (does not execute attack, pure computation) |
| **UI / Input** | Upstream (call) | Input triggers attack execution | Input calls `AttackResolver.execute_attack(attacker, target)` on click confirmation. Input owns the click-handling and hover preview. |
| **Movement** | Indirect | Attack phase follows movement phase | Unit enters MOVED state after movement → Input auto-enters attack targeting. Movement has no direct Attack dependency — Input is the coordinator. |
| **Victory** | Indirect (signal) | Death triggers victory check | `target.take_damage()` emits `unit_died` if HP ≤ 0. Turn System listens and evaluates faction elimination. Victory listens to `match_ended`. Attack does not call Victory directly. |
| **AI** | Reserved (Tier 2) | AI chooses attack target | `AttackRangeResolver.get_valid_targets()` provides the target list. `AttackResolver.execute_attack()` executes. AI GDD will define the selection strategy. |

> **Design note — Map GDD erratum**: The Map GDD's interaction table currently lists "`get_neighbors()` — range ring computation" as Attack's dependency on Map. This was an early inference made before Manhattan distance was confirmed. Attack uses Manhattan distance (pure coordinate math, formula owned by Movement GDD F2) + `get_unit_at()` (point query), not neighbor expansion. This erratum should be corrected in the Map GDD during the next consistency-check pass.

## Formulas

### F1: Damage Formula

The damage formula is defined as:

`damage = max(attacker.atk − target.def, 1)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Attacker ATK | atk | int | [3, 8] | Attacker's Attack stat from UnitStats |
| Defender DEF | def | int | [0, 5] | Defender's Defense stat from UnitStats |
| Raw difference | raw | int | [-5, 8] | Intermediate: atk − def, before floor clamp |
| Damage | damage | int | [1, 8] | Final damage dealt. Floor at 1 guarantees progress. |

**Output Range:** [1, 8] for MVP stat caps. Unbounded in principle — if Tier 2 raises ATK/DEF ceilings, the range expands but the floor stays at 1.

**Extreme Behavior:**
- **ATK ≤ DEF** (e.g., ATK 3 vs DEF 5): `raw = -2`, `damage = 1`. Every attack deals exactly 1 damage — the floor prevents stall.
- **ATK >> DEF** (e.g., ATK 8 vs DEF 0): `damage = 8`. Maximum kill power — one-shots any unit with HP ≤ 8.
- **DEF = 0** (no mitigation): `damage = atk`. Raw attack value passes through unmodified.

**Examples:**

| Scenario | ATK | DEF | Raw | Damage | Note |
|----------|-----|-----|-----|--------|------|
| Low vs High | 3 | 5 | -2 | **1** | Floor prevents zero damage |
| Default match | 5 | 2 | 3 | **3** | ~4 hits to kill vs HP 10 |
| Glass cannon | 8 | 0 | 8 | **8** | One-shots HP ≤ 8 units |
| Tank soak | 4 | 4 | 0 | **1** | ATK = DEF clamped to 1 |
| Squishy fight | 3 | 0 | 3 | **3** | Both sides fragile |

**Hits-to-Kill (HTK) Matrix** (damage values by ATK vs DEF; HTK = `ceil(max_hp / damage)`):

```
       DEF: 0  1  2  3  4  5
ATK 3:      3  2  1  1  1  1
ATK 4:      4  3  2  1  1  1
ATK 5:      5  4  3  2  1  1
ATK 6:      6  5  4  3  2  1
ATK 7:      7  6  5  4  3  2
ATK 8:      8  7  6  5  4  3
```

For HP=10 (default): HTK ranges from **2** (ATK 8 vs DEF 0) to **10** (ATK 3 vs DEF 5). The default stat line (ATK 5, DEF 2, HP 10) produces damage 3 → 4 HTK — healthy middle ground.

**Degenerate Combinations (designer awareness, not code fix):**
- ATK 3 vs DEF 3+: 1 damage, 10+ HTK at HP=10. Two such units fighting may hit the turn cap before either dies. Designers should avoid pairing max-DEF units against min-ATK units.
- ATK 8 vs DEF ≤ 2, HP ≤ 8: 1 HTK. Fast lethality is acceptable for tactics games, but fielding multiple ATK 8 glass cannons may shorten matches below the 5-minute floor.

### F2: Range Check (Manhattan Distance)

The range check formula is defined as:

`in_range = |attacker.row − target.row| + |attacker.col − target.col| ≤ attacker.rng`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Attacker position | (a_r, a_c) | Vector2i | in-bounds tile | Attacker's grid_position |
| Target position | (t_r, t_c) | Vector2i | in-bounds tile | Target's grid_position |
| Manhattan distance | dist | int | [1, map_cols + map_rows] | Grid distance between the two tiles |
| Attack range | rng | int | [1, 3] | Attacker's RNG stat from UnitStats |

**Output Range:** `true` when distance ≤ RNG and ≥ 1. The attacker's own tile (distance 0) always returns `false` — a unit cannot attack itself.

**Extreme Behavior:**
- RNG=1, adjacent target: `|1−0| + |0−0| = 1 ≤ 1` → `true`.
- RNG=1, diagonal target: `|1−0| + |1−0| = 2 > 1` → `false`. No diagonal attacks at RNG=1.
- RNG=3, target across map: check against Manhattan ≤ 3.

**Example:** Attacker at (5, 3) with RNG=2. Target at (5, 5): `|5−5| + |5−3| = 2 ≤ 2` → `true`. Target at (3, 5): `|3−5| + |5−3| = 4 > 2` → `false`.

> **Ownership**: Manhattan distance (`|dr| + |dc|`) is defined in Movement GDD F2. Attack references it, does not redefine it. The range check `≤ rng` is Attack's own addition.

### F3: Valid Target Count (per tile)

The number of attack-reachable tiles from a position at given RNG is defined as:

`attackable_tiles(rng) = 2 × rng × (rng + 1)` for an open field (no map boundary clipping)

| RNG | Max Tiles (open) | Typical on 16×12 Map (center) | On 8×8 Map (corner) |
|-----|------------------|------------------------------|---------------------|
| 1 | 4 | 4 | 2 |
| 2 | 12 | 12 | 5 |
| 3 | 24 | 23 | 10 |

These are *potential* attackable tiles. Actual valid targets are the subset of these tiles that contain a living enemy unit — typically far fewer. UI highlight cost per frame is dominated by the ≤24 tile polygon, well within budget.

### F4: resolve_damage (Preview)

`resolve_damage(atk: int, def: int) = max(atk − def, 1)`

Pure static function. Identical to F1 but takes raw integers instead of Unit references. Used by UI for hover damage preview — computes what the damage *would be* without executing an attack. No side effects, no state reads, no writes. Enables the player to see damage before committing.

### F5: Hits-to-Kill Estimation (Analytic)

`htk = ceil(target.hp / max(attacker.atk − target.def, 1))`

Not a formal API method — an analytic formula for designers to sanity-check stat combinations. Given HP=10, ATK=5, DEF=2: `htk = ceil(10 / 3) = 4`. This sanity check should hold: `htk < turn_cap` for all deployed archetypes — if any unit requires more turns to kill than the turn cap allows, the match cannot resolve by that engagement alone.

## Edge Cases

### Damage Resolution

- **If target's HP reaches 0 from damage**: `take_damage()` handles death — emits `unit_died`, Map removes occupancy. Attack does not need a special case. `attacker.has_acted` is still set to `true`. `AttackResult.killed = true`.

- **If damage equals exactly the target's remaining HP**: `take_damage(amount)` where `amount == hp` → hp becomes 0 via `clamp(hp − amount, 0, max_hp)`. `unit_died` emitted. `AttackResult.killed = true`. No special case needed — `clamp` naturally produces 0.

- **If damage exceeds remaining HP (overkill)**: `clamp` floors at 0. Overkill amount is discarded. `AttackResult.damage` records the raw damage value, not the HP actually subtracted. The kill is valid. No special handling.

- **If damage computes to 0 (floor check)**: The `max(..., 1)` floor guarantees damage ≥ 1. Even ATK 3 vs DEF 5 produces damage 1. Zero damage is impossible at MVP.

### Target Validation Guards

- **If attack is attempted on a tile with no unit or a dead unit**: `Map.get_unit_at(tile)` returns `null` for dead units (Map removes occupancy on death signal). Target validation Rule 3 rejects `null` targets. `execute_attack()` asserts `target != null` as a second defense.

- **If attack is attempted on a same-faction unit**: Target validation Rule 3 rejects (`target.faction != attacker.faction`). Input should never offer same-faction units as targets. `execute_attack()` guards this as a defense-in-depth check: if bypassed, the attack is rejected and returns `AttackResult.INVALID`.

- **If attacker has already acted this turn**: `has_acted_this_turn == true` → precondition fails. Input should not enter attack targeting for acted units. `execute_attack()` guards at entry and returns `AttackResult.INVALID` if bypassed.

### Impossible-at-MVP (Reserved Guards)

- **If attacker dies between target selection and execution**: Not possible at MVP — no delayed damage, no traps, no reactive abilities. Attack execution is synchronous. If Tier 2 adds these mechanics, add `if not attacker.is_alive: return AttackResult.INVALID` at `execute_attack()` entry.

- **If target position changes between selection and execution**: Not possible at MVP — no forced movement, no pushback, no teleport. If Tier 2 adds displacement, `execute_attack()` should re-validate Manhattan distance at execution time.

### Degenerate Input States

- **If no valid targets exist (empty target list)**: `AttackRangeResolver.get_valid_targets()` returns `[]`. UI should immediately transition to ACTED without entering targeting mode — no need to show an empty attack option. This avoids a dead UI state.

- **If `get_valid_targets()` is called on a unit that has already acted**: Returns the list of enemy units in range regardless. `get_valid_targets()` does NOT check `has_acted` — Input owns precondition enforcement. The resolver is a pure query, consistent with the "pure computation" pattern.

- **If skip-attack is triggered when no targets are in range**: Valid. The unit may choose not to attack even if targets exist, or may skip when no targets exist (though empty-list auto-skip makes the latter a no-op). `has_acted` is consumed either way.

### Data Integrity

- **If `resolve_damage()` is called with out-of-range stats**: Returns `max(atk − def, 1)` unconditionally — pure math, no validation. If a caller passes ATK=999 or DEF=-5, the function computes correctly. Stat-range validation is Unit's responsibility (Unit GDD F4).

- **If `execute_attack()` receives a null attacker or target**: Asserts both are non-null with descriptive messages (`"execute_attack: attacker is null"` / `"execute_attack: target is null"`). Returns `AttackResult.INVALID` in release builds. No crash, no silent failure.

- **If Manhattan distance computation overflows**: Impossible. Map bounds [8, 32] per axis → max Manhattan distance = `(32−1) + (32−1) = 62`. Fits in `int` trivially.

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map** | Hard | `get_unit_at(coord) → Unit` | Target validation — confirms a unit exists at the target tile. Attack does NOT call `get_neighbors()` — range is Manhattan, not BFS-based. |
| **Unit** | Hard | `atk: int`, `def: int`, `rng: int`, `hp: int`, `max_hp: int`, `faction`, `is_alive`, `has_acted_this_turn`, `action_state`, `grid_position`, `take_damage(amount)`, `unit_died` signal | Reads stats for damage computation and target validation. Writes via `take_damage()`, `has_acted`, `action_state`. |
| **Movement** | Indirect | Manhattan distance formula F2 | Manhattan distance is defined in Movement GDD F2. Attack references it for range computation (F2), does not redefine it. Attack has no runtime dependency on MovementResolver. |

### Downstream Dependencies

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **UI / Input** | Hard | `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]`; `AttackResolver.resolve_damage(atk, def) → int`; `AttackResolver.execute_attack(attacker, target) → AttackResult` | UI reads target list for highlight rendering and damage preview. Input calls `execute_attack()` on click confirmation. |
| **AI** | Hard (Tier 2) | Same interfaces as UI/Input | AI GDD will define target selection strategy using the same `get_valid_targets()` list. The interface is designed to support both human and AI consumers without modification. |
| **Turn System** | Indirect | `unit.has_acted_this_turn` toggle | Turn polls this flag for auto-advance. Attack sets it to `true` on execution or skip. Attack does not call Turn directly. |
| **Victory** | Indirect | `unit_died` signal chain | `take_damage()` → `unit_died` → Turn System evaluates elimination → `match_ended` → Victory processes winner. Attack is three steps removed from Victory. |

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `AttackResolver` (RefCounted) | Code | Pure damage computation + execution. Created by Game scene (composition root), DI-injected into Input. Follows GridSpace/MovementResolver pattern. |
| `AttackRangeResolver` (RefCounted) | Code | Enemy-in-range query. Iterates units, filters by faction + distance. Created by Game scene, DI-injected into Input. |
| `AttackResult` (RefCounted) | Code | Immutable result wrapper: `{damage: int, killed: bool, attacker: Unit, target: Unit}`. Follows MovementResult pattern. |
| `Faction.Type` enum | Code | Defined in `src/core/faction.gd` (Unit GDD). Attack reads for target validation. |

## Tuning Knobs

Most tuning values that affect Attack are owned by the Unit GDD (UnitStats.tres). They are listed here for cross-reference, not as duplicates.

### Attack-Owned Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `damage_floor` | AttackResolver (constant) | {0, 1} | 0: DEF can fully negate ATK — ATK ≤ DEF deals 0 damage, creating immortal matchups | N/A — cap is 1 | Locked at 1 for MVP. Floor=0 is reserved for Tier 2 if a separate "pierce" mechanic is introduced. |
| `rng_metric` | AttackResolver (constant) | {manhattan, chebyshev} | N/A | N/A | Locked at `manhattan` for MVP. Consistent with Movement's 4-neighbor BFS. Reserved for Tier 2 if diagonal attacks are introduced. |

### Unit-Owned Knobs (Attack Consumer)

| Knob | Location | Safe Range | Effect on Attack | Notes |
|------|----------|------------|------------------|-------|
| `unit.atk` | UnitStats.tres | [3, 8] | Raw damage before DEF reduction. Every +1 ATK = +1 damage vs same DEF. | Defined in Unit GDD. Raising ATK globally makes DEF less meaningful. |
| `unit.def` | UnitStats.tres | [0, 5] | Flat damage reduction. Each +1 DEF neutralizes 1 ATK. | Defined in Unit GDD. At DEF=5, only ATK ≥ 7 deals >2 damage. |
| `unit.rng` | UnitStats.tres | [1, 3] | Attack reach in Manhattan tiles. RNG=1: 4 adjacent tiles only. RNG=3: 24 tiles. | Defined in Unit GDD. RNG=3 from center nearly covers a 7×7 diamond. |
| `unit.max_hp` | UnitStats.tres | [5, 20] | Survivability ceiling. Determines hits-to-kill (HTK) per the damage matrix in F1. | Defined in Unit GDD. HP=5 with ATK 8 → 1 HTK. HP=20 with ATK 3 vs DEF 5 → 20 HTK. |

### Knob Interactions

- **Lethality**: `HTK = ceil(max_hp / max(atk − def, 1))`. Raising `atk` or lowering `def` both decrease HTK. The designer must check that the shortest HTK in the worst-case matchup is not 1 (one-shot) unless intended, and that the longest HTK is not ≥ `turn_cap` (unresolvable engagement).
- **Threat radius**: `threat = mov + rng`. A unit with MOV 6 + RNG 3 projects threat 9 tiles — nearly the full 16×12 map width. Noted in Unit GDD; Attack's role is the `rng` component.
- **damage_floor vs DEF stacking**: Floor=1 means even ATK 3 vs DEF 5 deals 1 damage. If Tier 2 introduces DEF stacking beyond 5, the floor prevents true invulnerability. Raising the floor to 2 would make low-ATK units too effective vs tanks.

## Visual/Audio Requirements

Per Programmer Art Functional anchor. No audio at MVP.

### Attack Targeting Highlight

| Element | Color | Description |
|---------|-------|-------------|
| Valid target highlight | Red (`#EF4444`, enemy faction red) | Highlight on tiles containing valid attack targets. Uses the enemy faction color — natural association: red = hostile = attackable. |
| Cursor/hover target | Brighter red or red with border | Distinct from non-hovered targets. Signals "this is the currently selected target." |

### Damage Preview (Hover)

| Element | Specification | Description |
|---------|--------------|-------------|
| Text format | `"-N"` (e.g., `"-3"`) | Prefix minus sign, no "+", no "HP" label. Compact and unambiguous. |
| Position | `Vector2(0, -60)` above target unit center | Offset above the HP label (HP is at -40, damage at -60 — stacked vertically). |
| Font | Godot default | No custom font at MVP. |
| Color (normal) | `#F59E0B` (amber/yellow) | Warm neutral — distinct from HP white, faction blue/red, and movement blue. |
| Color (lethal) | `#EF4444` (enemy red) | When `damage ≥ target.hp`, the damage number switches to red — "this hit will kill." One extra color token. |

### Damage Resolution (Post-Click)

| Element | Specification | Description |
|---------|--------------|-------------|
| Damage number linger | 600ms at hover position | Damage number persists above the target for 600ms after click, then fades. Gives the player a beat to confirm the result. |
| HP label update | Instant | Target's HP label updates immediately to `"HP: N/M"` (e.g., `"HP: 7/10"`). No tween — instant numeric change. |
| Surviving target visual | HP number changed, damage lingering | The unit remains at full opacity and faction color. |
| Death | Instant `queue_free()` | Unit node removed from scene tree immediately after `unit_died` signal. No corpse, no fade, no scale tween — consistent with Programmer Art Functional "debug visualizer" ethos. |

### Color Tokens (New)

| Token | Hex | Usage |
|-------|-----|-------|
| `DAMAGE_PREVIEW` | `#F59E0B` (amber) | Hover damage number — normal (non-lethal) |
| `DAMAGE_LETHAL` | `#EF4444` (red) | Hover damage number — lethal (will kill target) |
| `TARGET_HIGHLIGHT` | `#EF4444` (red, same as enemy faction) | Valid attack target tile highlight |

> Token rationale: `DAMAGE_PREVIEW` amber is chosen to be distinct from faction blue (#3B82F6), faction red (#EF4444), path cyan (Movement GDD), reachable blue (Movement GDD), and tile states. `DAMAGE_LETHAL` uses the existing enemy faction red — dangerous things are red, consistent mental model.

### Audio

**None.** Explicitly excluded per game-concept.md Anti-Pillar and MVP scope. No hit SFX, no kill jingle, no UI sounds. The `damage_dealt` signal and `unit_died` signal are the hooks a future audio system can connect to without modifying Attack code.

> 📌 **Asset Spec** — Visual/Audio requirements defined. After art bible approval, run `/asset-spec system:attack` to produce per-asset visual descriptions, dimensions, and generation prompts.

---

## UI Requirements

### Hover Damage Preview

When the player hovers a valid attack target, UI calls `AttackResolver.resolve_damage(attacker.atk, target.def)` and renders the result per Visual/Audio above. The preview is purely informational — no commitment, no state change.

### Target Highlight Rendering

UI reads `AttackRangeResolver.get_valid_targets(unit, map)` and renders a highlight overlay on each returned tile. Highlight color: enemy faction red (#EF4444). The hovered target uses a brighter variant or red-with-border to distinguish selection.

### Attack Confirmation

- **Left-click** on a highlighted target: UI calls `AttackResolver.execute_attack(attacker, target)`. Displays lingering damage number. Updates all HP labels.
- **Right-click / Escape** during targeting: UI clears highlights. Unit transitions to ACTED via skip-attack.

### Post-Attack Cleanup

After attack execution (or skip-attack), UI clears:
- All attack target highlights.
- All movement reachable highlights (if any remain from the movement phase).
- The damage preview text (after linger duration).

### End-to-End UI Flow

```
1. Unit enters SELECTED → Movement range highlights (blue)
2. Player clicks enemy in range → direct attack (skip movement) → ACTED
3. OR: Player clicks move destination → unit moves → MOVED → auto-enter attack targeting
4. Attack targeting → valid targets highlighted (red)
5. Player hovers target → damage preview number appears
6. Player clicks target → damage lingers 600ms → HP updates → unit dies or survives
7. Player Esc/right-click → skip attack → ACTED
8. Post-action → all highlights cleared
```

> 📌 **UX Flag — Attack**: This system contributes attack targeting highlights and damage preview display. These UI elements should be specified in `design/ux/hud.md` as part of the combat HUD layer. In Phase 4 (Pre-Production), run `/ux-design` for the HUD, referencing `AttackRangeResolver` and `AttackResolver` as the data sources for these UI elements.

## Acceptance Criteria

### A. Core Rules

**AC-C01 — All preconditions met → attack allowed** (Logic)
GIVEN a unit with `is_alive==true`, `faction == active_faction`, `action_state == SELECTED`, `has_acted==false`, and a valid enemy target within RNG, WHEN `execute_attack(attacker, target)` is called, THEN the attack succeeds and returns a valid `AttackResult`.

**AC-C02 — Dead attacker rejected** (Logic)
GIVEN a unit with `is_alive == false`, WHEN `execute_attack()` is called, THEN it returns `AttackResult.INVALID`. No damage is dealt.

**AC-C03 — Already-acted attacker rejected** (Logic)
GIVEN a unit with `has_acted_this_turn == true`, WHEN `execute_attack()` is called, THEN it returns `AttackResult.INVALID`.

**AC-C04 — Wrong action_state rejected** (Logic)
GIVEN a unit with `action_state == IDLE`, WHEN `execute_attack()` is called, THEN it returns `AttackResult.INVALID`.

**AC-C05 — Range check: within Manhattan distance** (Logic)
GIVEN attacker at (5,3) with RNG=2, target at (5,5), WHEN range is evaluated, THEN `manhattan = |5−5| + |5−3| = 2 ≤ 2` → `in_range == true`.

**AC-C06 — Range check: outside Manhattan distance** (Logic)
GIVEN attacker at (5,3) with RNG=2, target at (3,5), WHEN range is evaluated, THEN `manhattan = 4 > 2` → `in_range == false`.

**AC-C07 — Range check: self tile excluded** (Logic)
GIVEN attacker at (5,3) with RNG=2, target at (5,3) (same tile), WHEN range is evaluated, THEN `manhattan = 0` → `in_range == false` (cannot attack self).

**AC-C08 — Target validation: null/dead target** (Logic)
GIVEN a valid attacker, WHEN the target tile has `Map.get_unit_at(tile) == null` or `target.is_alive == false`, THEN the attack is rejected.

**AC-C09 — Target validation: same faction rejected** (Logic)
GIVEN a PLAYER attacker, WHEN the target is also PLAYER faction, THEN `execute_attack()` returns `AttackResult.INVALID`. The faction check is a defense-in-depth guard within `execute_attack()`, not just in `get_valid_targets()`.

**AC-C10 — Attack execution: complete state changes** (Integration)
GIVEN attacker at (5,3), target at (5,4) with HP=10 ATK=5 DEF=2, WHEN `execute_attack(attacker, target)` is called, THEN damage=3, `target.hp` becomes 7 (take_damage called), `attacker.has_acted_this_turn` becomes `true`, `attacker.action_state` becomes `ACTED`.

**AC-C11 — Direct attack from SELECTED: no movement** (Integration)
GIVEN unit in SELECTED at (2,2), enemy at (2,3) within RNG=1, WHEN player clicks enemy, THEN attack executes, unit.grid_position remains (2,2), state becomes ACTED.

**AC-C12 — Post-move attack from MOVED** (Integration)
GIVEN unit moved to (4,4), now in MOVED state, enemy at (4,5) within RNG=1, WHEN player clicks enemy, THEN attack executes, state becomes ACTED.

**AC-C13 — Skip-attack: action consumed, no damage** (Logic)
GIVEN unit in SELECTED or MOVED with targeting active, WHEN player presses Escape or right-clicks, THEN `has_acted_this_turn == true`, `action_state == ACTED`, no `take_damage()` called on any unit, highlight cleared.

**AC-C14 — damage_dealt signal emitted** (Logic)
GIVEN a successful attack with damage=3, WHEN `execute_attack()` completes, THEN the signal `damage_dealt(attacker, target, 3)` is emitted exactly once with correct parameters.

**AC-C15 — AttackResult field completeness** (Logic)
GIVEN a successful attack, WHEN `execute_attack()` returns, THEN `AttackResult.damage` equals the computed damage, `AttackResult.killed` equals `true` iff target HP reached 0, `AttackResult.attacker` and `AttackResult.target` reference the correct units.

**AC-C16 — AttackResolver architecture** (Logic)
GIVEN the `AttackResolver` class, WHEN inspected, THEN it extends `RefCounted`, owns no instance state between calls, and `execute_attack()` produces no side effects beyond `take_damage()` and unit state writes.

**AC-C17 — No counter-attack** (Logic)
GIVEN attacker with HP=10 and target with ATK=5, WHEN attacker executes an attack on target, THEN attacker's HP remains 10 — no damage is dealt to the attacker.

**AC-C18 — Single target only** (Logic)
GIVEN attacker at (5,3), two enemies at (5,4) and (5,5) both in range, WHEN attacker attacks (5,4), THEN only that target's HP changes; the unit at (5,5) is unaffected.

### B. AttackRangeResolver

**AC-C19 — Returns only valid enemies** (Logic)
GIVEN a map with 3 PLAYER units and 2 ENEMY units (both alive), attacker is PLAYER at (5,5) with RNG=3, WHEN `get_valid_targets(attacker, map)` is called, THEN only the 2 ENEMY units within Manhattan distance ≤ 3 are returned. Same-faction and dead units are excluded.

**AC-C20 — Sorted by distance, then HP** (Logic)
GIVEN attacker at (0,0) RNG=3, Enemy A at (0,2) HP=8, Enemy B at (0,1) HP=10, Enemy C at (0,2) HP=5, WHEN `get_valid_targets()` is called, THEN order is: [B(d=1), C(d=2, HP=5), A(d=2, HP=8)]. Closest first; equal distance → lowest HP first.

**AC-C21 — Empty target list** (Logic)
GIVEN a unit with no enemy units on the map, WHEN `get_valid_targets()` is called, THEN returns `[]`.

**AC-C22 — Pure query on acted unit** (Logic)
GIVEN a unit with `has_acted==true`, WHEN `get_valid_targets()` is called, THEN it still returns enemies in range — the function does NOT gate on `has_acted`. Caller (Input) owns gating.

### C. Formulas

**AC-F01 — F1: Standard damage** (Logic)
GIVEN ATK=5, DEF=2, WHEN F1 is evaluated, THEN `damage = max(5−2, 1) = 3`.

**AC-F02 — F1: Floor at 1 (ATK ≤ DEF)** (Logic)
GIVEN ATK=3, DEF=5, WHEN F1 is evaluated, THEN `damage = max(3−5, 1) = 1`. The floor prevents zero damage. Verified for all 10 ATK ≤ DEF combinations in the stat range.

**AC-F03 — F1: Maximum damage** (Logic)
GIVEN ATK=8, DEF=0, WHEN F1 is evaluated, THEN `damage = max(8−0, 1) = 8`.

**AC-F04 — F2: Range check Manhattan** (Logic)
GIVEN attacker at (0,0) RNG=2, WHEN range is checked for targets at (0,1), (0,2), (1,0), (1,1), THEN `in_range` is `true` for all four. WHEN checked for (0,3) and (2,2), THEN `false`.

**AC-F05 — F4: resolve_damage pure static** (Logic)
GIVEN ATK=5, DEF=2, WHEN `resolve_damage(5, 2)` is called, THEN returns `3`. WHEN called twice with same args, THEN returns same value. No state read, no side effects. The function accepts raw integers, not Unit references.

### D. Edge Cases

**AC-E01 — Kill: HP reaches 0** (Integration)
GIVEN target with HP=1, attacker ATK=5, target DEF=2, WHEN `execute_attack()` deals damage=3, THEN `target.take_damage(3)` is called, target HP becomes 0, `unit_died` signal is emitted by Unit, `AttackResult.killed == true`.

**AC-E02 — Exact kill vs overkill** (Logic)
GIVEN target HP=3, ATK=5, DEF=2 (damage=3), WHEN attack executes: `damage == hp` → exact kill, HP=0, `killed=true`. GIVEN target HP=2 (damage=3), WHEN attack executes: `damage > hp` → overkill, HP=0, `killed=true`. Both produce the same result — overkill amount is discarded by `clamp()` in `take_damage()`.

**AC-E03 — Empty target list → no targeting mode** (Logic)
GIVEN a unit with `get_valid_targets()` returning `[]`, WHEN Input checks the target list, THEN the unit skips directly to ACTED — no targeting mode entered, no highlight rendered.

**AC-E04 — Null attacker/target guard** (Logic/Instrumented)
GIVEN `execute_attack(null, target)` OR `execute_attack(attacker, null)`, WHEN called, THEN in debug builds: assertion fires with descriptive message. In release builds: returns `AttackResult.INVALID`. Requires separate test configurations.

**AC-E05 — Zero damage impossible** (Logic)
GIVEN all 36 valid ATK×DEF combinations in [3,8]×[0,5], WHEN `max(atk−def, 1)` is computed for each, THEN every result ≥ 1. Spot-check the 10 combos where ATK ≤ DEF — all return exactly 1.

**AC-E06 — resolve_damage with out-of-range stats** (Logic)
GIVEN `resolve_damage(999, -5)`, WHEN called, THEN returns `max(999−(−5), 1) = 1004`. The function does NOT validate stat ranges — it is pure math. Stat validation is Unit's responsibility.

### E. State Machine Transitions

**AC-S01 — SELECTED + click enemy in range → ACTED** (Logic)
GIVEN unit in SELECTED at (2,2), enemy in range at (2,3), WHEN player clicks enemy, THEN `action_state` transitions SELECTED → ACTED, `has_acted = true`, damage applied.

**AC-S02 — SELECTED + Esc → ACTED (skip)** (Logic)
GIVEN unit in SELECTED with targeting active, WHEN player presses Escape, THEN `action_state` transitions SELECTED → ACTED, `has_acted = true`, no damage.

**AC-S03 — MOVED + click enemy in range → ACTED** (Logic)
GIVEN unit in MOVED at (4,4), enemy in range at (4,5), WHEN player clicks enemy, THEN `action_state` transitions MOVED → ACTED, `has_acted = true`, damage applied.

**AC-S04 — MOVED + Esc → ACTED (skip)** (Logic)
GIVEN unit in MOVED with targeting active, WHEN player presses Escape, THEN `action_state` transitions MOVED → ACTED, `has_acted = true`, no damage.

### F. Untestable / Reserved

**AC-U01 — Attacker dies mid-targeting** (UNTESTABLE — RESERVED_TIER2)
GIVEN an attack targeting phase, WHEN the attacker dies between selection and execution (e.g., delayed damage, reactive trap), THEN `execute_attack()` guards with `if not attacker.is_alive: return AttackResult.INVALID`. Not testable at MVP — no delayed damage sources exist. Reserved guard; AC activates when Tier 2 introduces the relevant mechanic.

**AC-U02 — Target position changes mid-targeting** (UNTESTABLE — RESERVED_TIER2)
GIVEN an attack targeting phase, WHEN the target moves between selection and execution (e.g., forced movement, pushback), THEN `execute_attack()` re-validates Manhattan distance at execution time and rejects if out of range. Not testable at MVP — no displacement mechanics exist.

**AC-U03 — F5 HTK analytic formula** (UNTESTABLE — ANALYTIC_ONLY)
HTK is not implemented in code — it is a designer-facing spreadsheet sanity check. Verified during balance review, not by automated test.

**AC-U04 — F3 attackable tile count** (UNTESTABLE — DESIGN_REFERENCE)
`2*rng*(rng+1)` is a mathematical property of Manhattan rings on an open grid. No runtime code computes it — it is a reference value for UI capacity estimation. Optional manual visual verification.

### Summary

| Category | Count | Logic | Integration | Gate | UNTESTABLE |
|----------|-------|-------|-------------|------|------------|
| Core Rules (18) | 18 | 15 | 3 | BLOCKING (18) | 0 |
| RangeResolver (4) | 4 | 4 | 0 | BLOCKING (4) | 0 |
| Formulas (5) | 5 | 5 | 0 | BLOCKING (5) | 0 |
| Edge Cases (6) | 6 | 5 | 1 | BLOCKING (6) | 0 |
| State Transitions (4) | 4 | 4 | 0 | BLOCKING (4) | 0 |
| Untestable/Reserved | 4 | 0 | 0 | ADVISORY | 4 |
| **Total** | **41** | **33** | **4** | — | **4** |

Gate: 37 criteria are BLOCKING and require automated tests. 4 are UNTESTABLE at MVP (documented, not blocking). Logic tests live in `tests/unit/attack/`. Integration tests live in `tests/integration/attack/`.

## Open Questions

- **OQ1 — Map GDD erratum (Attack's Map dependency)**: The Map GDD interaction table currently lists `get_neighbors()` for "range ring computation" as Attack's dependency on Map. This GDD confirms Attack uses Manhattan distance + `get_unit_at()`, not `get_neighbors()`. → Flagged in this GDD's Dependencies section. Map GDD correction is a consistency-check action item, not a blocker for Attack.

- **OQ2 — Unit GDD state machine: SELECTED → ACTED path**: The Unit GDD state machine table currently only shows IDLE → SELECTED → MOVED → ACTED. Attack GDD adds SELECTED → ACTED (direct attack without moving) and cancel-from-targeting paths. → Unit GDD's `can_attack()` and Core Rule 7 (`action_state` in `[SELECTED, MOVED]`) already support the mechanic. The state machine table is descriptive, not prescriptive. Consistency-check should verify bidirectional alignment.

- **OQ3 — Manhattan distance ownership**: Movement GDD OQ2 asked whether Manhattan distance should live in Movement or Attack. → Resolved: Movement GDD F2 owns the formula definition. Attack GDD F2 references it. Movement GDD's F2 boundary note can be updated to record this resolution.

- **OQ4 — `damage_floor` = 0 reserved for Tier 2**: If a future Tier 2 system introduces damage floor = 0 (allowing DEF to fully negate ATK), should this be a per-unit property, a global constant, or a status-effect override? → Defer to Tier 2 design. The `damage_floor` is currently a constant in `AttackResolver` (value: 1) and is trivially parameterizable.

- **OQ5 — Counter-attack signal wiring**: `damage_dealt` signal is emitted by Attack and reserved for Tier 2 counter-attack. Which system owns the counter-attack logic? → Defer to Tier 2 design. Attack's responsibility is to emit the signal with correct parameters. The counter-attack system connects without modifying Attack.

- **OQ6 — `AttackResult.INVALID` sentinel**: Currently `AttackResult.INVALID` is a distinct sentinel value returned on precondition failure. Should this be a dedicated `AttackResult.is_valid() → bool` method, or a null-return pattern? → Resolve during implementation (implementation detail, not a design concern).
