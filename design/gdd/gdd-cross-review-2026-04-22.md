# GDD Cross-Review Report

> **Date**: 2026-04-22
> **Reviewer**: Opus automated review
> **Scope**: All 23 system GDDs
> **Mode**: full (consistency + design theory)
> **Registry Baseline**: `design/registry/entities.yaml` (7 entities, 11 formulas, 17+ constants)

---

## Verdict: FAIL → PASS (after blocker fixes)

> **Update**: 2026-04-23 — All 4 blocking issues resolved. Remaining warnings are non-blocking.

4 blocking issues were resolved on 2026-04-23. Remaining warnings are advisory.

| Category | BLOCKER | WARNING | INFO |
|----------|---------|---------|------|
| Cross-GDD Consistency | 3 | 5 | 2 |
| Game Design Holism | 1 | 3 | 0 |
| Cross-System Scenarios | 0 | 2 | 2 |

---

## GDDs Flagged for Revision (10/23)

| GDD | Issue IDs | Severity |
|-----|-----------|----------|
| class-system.md | C-01 | BLOCKER |
| fog-of-war-system.md | C-01 | BLOCKER |
| tactical-mechanism.md | C-02, W-03 | BLOCKER |
| worldbuilding-narrative.md | C-02 | BLOCKER |
| resource-economy.md | C-03, D-01 | BLOCKER |
| equipment-system.md | C-03, W-02 | BLOCKER |
| SRPG 核心模块设计总纲.md | W-06 | WARNING |
| systems-index.md | W-06 | WARNING |
| boss-system.md | W-04 | WARNING |
| attribute-growth-system.md | W-07 | WARNING |

---

## Phase 2: Cross-GDD Consistency

### BLOCKING

#### C-01: Missing Class — 侦察兵

```
fog-of-war-system.md: "侦察兵 class gets +3 vision range"
class-system.md: Defines 6 basic + 6 advanced + 3 special classes
→ 侦察兵 does not exist in any category.
→ class-system also states: "未列出的职业初始化为战士"
   This means fog-of-war's intended vision bonus silently fails at runtime.
```

**Fix**: Add 侦察兵 to class-system.md (basic or advanced tier) with defined vision bonus, OR change fog-of-war to grant vision bonus through a different mechanism (skill, equipment, or attribute).

---

#### C-02: Element Count Mismatch — 4 vs 5

```
tactical-mechanism.md: Defines 4 elements: 火/水/风/土
worldbuilding-narrative.md: Defines 5 elements (五行): 火/水/风/土/金
→ Two canonical sources disagree on the element system.
→ 金 (Metal) exists in narrative but has no tactical expression.
```

**Fix**: Either align narrative to 4 elements (remove 金, or fold it into another), or add 金 to tactical mechanism with defined interactions. Requires creative decision — which document is authoritative?

---

#### C-03: Enhancement Tuning Knob Dual Ownership

```
resource-economy.md: TK-RE-04 defines enhancement gold costs per tier
equipment-system.md: TK-EQ-01 defines enhancement success rates per tier
→ Both GDDs own enhancement parameters. Previous consistency check scoping
   resolved gold cost → resource-economy, success rate → equipment-system.
→ However, both still carry tuning knobs for the same system.
   Future editors won't know which is authoritative without reading the review report.
```

**Fix**: Remove enhancement tuning knobs from one GDD entirely. Add explicit cross-reference: "Enhancement gold costs: see resource-economy.md TK-RE-04" in equipment-system.md.

---

### WARNINGS

#### W-01: Dependency Asymmetry — difficulty-system

```
difficulty-system.md: Lists AI system and resource-economy as downstream deps
ai-system.md: Does NOT reference difficulty-system
resource-economy.md: Does NOT reference difficulty-system
→ Difficulty multipliers silently modify AI threat weights and resource rewards,
   but those systems don't know they're being modified.
```

**Recommendation**: Add "influenced by: difficulty-system" to ai-system and resource-economy Dependencies sections.

---

#### W-02: Map Size Tier Mismatch

```
tactical-mechanism.md: 2 tiers — standard 15x15, large 25x25
equipment-system.md: 3 tiers — standard 15x15, large 20x20, super-large 25x25
camera-map-system.md: 3 tiers — standard 15x15, large 20x20, super-large 25x25
→ Tactical only defines 2 tiers, but camera and equipment reference 3.
→ The 20x20 tier exists in 2/3 documents.
```

**Recommendation**: Align tactical-mechanism to 3-tier system (add 20x20), or collapse camera/equipment to 2-tier.

---

#### W-03: Crush Multiplier Stacking — Potential Balance Break

```
tactical-mechanism.md: Weapon triangle gives ×1.25 advantage
  Crush threshold (30 stat difference) adds ×1.5 on top
  Combined: ×1.25 × ×1.5 = ×1.875 (not ×1.25 + ×1.5)
  Max theoretical: ×1.25 × ×1.5 × ×1.2 (height) = ×2.25
→ The stacking is multiplicative, not additive.
→ At ×2.25, a moderately strong unit one-shots equal-level enemies.
→ No diminishing returns or cap documented.
```

**Recommendation**: Add a hard cap (e.g., max ×2.0 combined multiplier) or switch to additive stacking. Document the interaction explicitly.

---

#### W-04: Boss Phase Skip — Undefined Behavior

```
boss-system.md: Phase thresholds at 50% and 25%
  If player deals enough damage to skip past 50% threshold in one hit
  (e.g., from 55% to 20%), the behavior is undefined.
→ Does the boss transition through phase 2 instantly?
→ Does phase 2's mechanic fire at all?
→ If phase 2 grants the boss new abilities, skipping it could be exploitable.
```

**Recommendation**: Define explicit behavior for threshold overshoot (e.g., "boss transitions through all intermediate phases in sequence, each triggering its phase mechanic once").

---

#### W-05: Bond Proximity Range — 3 Cells Not Defined

```
bond-system.md: "Proximity range for bond activation: 3 cells"
tactical-mechanism.md: No definition of cell adjacency rules for "3 cells"
→ Is it Manhattan distance? Chebyshev? Euclidean with rounding?
→ 3 cells Manhattan = up to 6 tiles away diagonally via path
→ 3 cells Chebyshev = 5x5 diamond/square
→ The bond combo skill trigger area depends on this definition.
```

**Recommendation**: Explicitly define distance metric in tactical-mechanism.md. Bond system should reference it: "proximity range: 3 cells (Manhattan distance, per tactical-mechanism.md)".

---

#### W-06: Stale Systems Index

```
systems-index.md: Shows "0 Reviewed", "0 Vertical Slice Designed"
→ All 23 GDDs are complete. The tracker is stale.
→ The 总纲 (game concept doc) has 11 TBD items, at least 5 already resolved
   in child GDDs.
```

**Recommendation**: Update systems-index.md tracker to reflect current state. Update 总纲 TBD items that are now resolved.

---

### INFO

#### I-01: SOU (灵魂强度) Effect Undefined

```
attribute-growth-system.md: SOU listed as one of 9 attributes
→ No GDD defines what SOU mechanically does.
→ Referenced in attribute growth but has no downstream consumer.
```

**Recommendation**: Define SOU's mechanical effect (likely: magic defense, special skill scaling, or spiritual resistance) or remove it.

---

#### I-02: Auto-Battle AI Budget

```
turn-based-mode.md: Auto-battle mode delegates to AI system
ai-system.md: No mention of auto-battle mode or how AI behavior differs
   when controlling player units vs enemy units.
→ The AI for friendly auto-battle may need different decision weights.
```

**Recommendation**: Add auto-battle AI profile to ai-system.md or clarify that the same threat model is used for both sides.

---

## Phase 3: Game Design Holism

### BLOCKING

#### D-01: Gold Economy Severe Imbalance

```
Resource analysis — Gold:

SOURCES (per battle):
  - base_reward: ~50 gold
  - damage bonus: ~20 gold (floor(damage × 0.1))
  - kill bonus: ~30 gold
  - Average per battle: ~100 gold
  - Battles per chapter: ~5-8
  - Per chapter income: ~500-800 gold

SINKS:
  - Equipment enhancement (full set to +9): ~19,000 gold
  - Base upgrades: ~5,000 gold
  - Consumable stock: ~1,000 gold
  - Total per playthrough: ~25,000+ gold

  Total income (30 chapters × 700 avg): ~21,000 gold
  Deficit: ~4,000+ gold (conservative estimate)

→ Even with generous estimates, gold sinks exceed sources.
→ At 100 gold/battle, +9 enhancement on a single weapon costs ~190 battles.
→ Players will be perpetually gold-starved, making enhancement feel
   like a trap rather than a progression system.
```

**Fix options**:
1. Increase gold rewards (2-3× current)
2. Reduce enhancement costs (especially safe zone +1~+5)
3. Add non-combat gold sources (base income, quest rewards, selling)
4. Rebalance the entire gold economy from scratch

---

### WARNINGS

#### D-02: Cognitive Load — 5 Simultaneous Active Systems in Combat

```
During a typical combat encounter, the player actively manages:

1. Turn order / speed sequencing (turn-based-mode) — ACTIVE
2. Weapon triangle + elemental matching (tactical-mechanism) — ACTIVE
3. Height/positioning (tactical-mechanism) — ACTIVE
4. Bond proximity for combo skills (bond-system) — ACTIVE
5. Resource management (MP, HP, items) (resource-economy) — ACTIVE

Plus passive awareness of:
6. Fog of war (fog-of-war-system)
7. AI threat assessment (ai-system)
8. Boss phase transitions (boss-system, when applicable)

→ 5 active systems in combat. Research suggests 3-4 is comfortable.
→ Weapon triangle + elemental + height is 3 spatial/tactical considerations
   alone, before resource or bond management.
```

**Recommendation**: Consider simplifying combat turns: make bond bonuses passive (auto-apply when in range), reduce elemental considerations to weapon-embedded effects, or add a "tactical overlay" UI that surfaces only the most relevant system for the current action.

---

#### D-03: Dominant Strategy — Safe Zone Enhancement

```
equipment-system.md: Enhancement +1 to +5 is 100% success (safe zone)
  +6+ has escalating failure rates

→ There is no decision to make in the safe zone. Every player enhances
   to +5 on every piece of equipment immediately.
→ The "choice" only begins at +6, where risk/reward kicks in.
→ This means the safe zone is pure power inflation with no gameplay value.
```

**Recommendation**: Either add resource cost to safe zone enhancement (so it competes with other gold uses), or reduce the safe zone to +3 and make +4/+5 low-risk but not guaranteed. The current design has a dominant strategy: "always enhance to +5 on everything."

---

#### D-04: No Catch-Up Mechanism for Gold Deficit

```
Related to D-01: If a player spends gold suboptimally early
  (e.g., enhancing wrong equipment), there is no way to recover:
  - No equipment selling prices defined
  - No repeatable gold farming activity documented
  - No gold loan/trade system
→ Suboptimal early spending permanently weakens the player.
→ Combined with D-01's deficit, this creates potential unrecoverable states.
```

**Recommendation**: Define equipment resale value (e.g., 50% of investment), add repeatable side activities for gold, or implement a bankruptcy safety net.

---

## Phase 4: Cross-System Scenario Walkthrough

### Scenario 1: First Boss Encounter (Chapters 3-4)

**Systems involved**: boss-system, tactical-mechanism, resource-economy, bond-system, turn-based-mode

```
Trigger: Player enters boss room
→ boss-system: Phase 1 begins, boss AI profile active
→ tactical-mechanism: Weapon triangle applies — boss likely has a weapon type
→ turn-based-mode: Speed sequence determines turn order
→ bond-system: If bonded pair within 3 cells, combo available

Walkthrough:
1. Player positions units around boss
2. Bonded pair moves within 3 cells — combo skill becomes available
3. Player attacks with weapon advantage (+25% damage)
4. Boss HP crosses 50% threshold — Phase 2 triggers
   → boss-system: Boss gains new attack pattern
   ⚠️  W-04: If player dealt enough damage to cross BOTH thresholds
      (50% AND 25%), behavior is undefined
5. Boss uses AoE attack — multiple units damaged
6. Player uses healing items — gold already spent on consumables
   → D-01: Gold deficit means fewer healing items available

FAILURE MODE IDENTIFIED:
  Boss phase skip (W-04) + gold scarcity (D-01) =
  Player who saves gold for enhancement has no healing items for boss.
  Player who spends gold on consumables can't enhance equipment.
  This is a false choice — both paths feel punishing.
```

---

### Scenario 2: Multi-System Level-Up During Combat

**Systems involved**: battle-settlement, skill-system, attribute-growth, resource-economy

```
Trigger: Player kills enemy that provides enough EXP to level up
→ battle-settlement: Awards EXP, checks level threshold
→ attribute-growth: Stats increase based on potential (E-S)
→ skill-system: New skill rank may unlock (every 10 levels)
   Trait selection at levels 10/20/30 pauses combat for choice
→ resource-economy: Level-up may trigger gold reward from achievement

FAILURE MODE IDENTIFIED:
  Skill trait selection (skill-system) pauses mid-combat for a choice.
  → Does the boss AI wait? Does the turn pause?
  → turn-based-mode doesn't define "pause for UI" during enemy turns.
  → If trait selection happens during player's turn, and the player
     levels up from a counter-attack during enemy's turn, the trigger
     timing is ambiguous.

Severity: WARNING — mid-combat level-up UI not fully specified.
```

---

### Scenario 3: NG+ Inheritance Chain

**Systems involved**: new-game-plus, difficulty-system, class-system, save-system

```
Trigger: Player completes route, enters NG+ setup
→ new-game-plus: Accumulated achievement points displayed
→ Player selects: 2× difficulty (100 pts) + special class unlock (2000 pts)
→ difficulty-system: 2× multiplier set for new playthrough
→ class-system: Special class now available in class selection
→ save-system: New playthrough save created in separate slot

Walkthrough (clean):
1. NG+ setup — player allocates 2100 points
2. New game starts — difficulty 2× active, special class available
3. Early combat: enemies have 2× HP/damage
   → skill-system: Player starts at Lv1, no skill advantage
   → attribute-growth: Stats reset, growth potential preserved

CONCERN:
  2× difficulty at Lv1 with reset stats but 2× enemy HP means
  the opening chapter is significantly harder than NG first playthrough.
  This is by design (NG+ = harder), but:
  → No "grace period" documented — does 2× apply from chapter 1?
  → With gold economy deficit (D-01), NG+ 2× means even less gold
     relative to enemy HP pools.
  → Combined difficulty spike could make NG+ chapter 1 feel impossible.

Severity: WARNING — NG+ difficulty scaling at chapter 1 may need grace period.
```

---

### Scenario 4: Bond Combo + Weapon Triangle + Height Stacking

**Systems involved**: bond-system, tactical-mechanism, attribute-growth

```
Trigger: Bonded pair attacks boss from high ground with weapon advantage

Calculation:
  Base damage: 100 (from attribute + weapon)
  Weapon triangle: ×1.25 (advantage)
  Height bonus: ×1.2 (2+ height advantage)
  Bond combo: ×1.5 (A-level bond combo skill)
  Crush threshold: ×1.5 (if stat diff ≥ 30)
  Combined: 100 × 1.25 × 1.2 × 1.5 × 1.5 = 337.5

  This is ×3.375 base damage — can one-shot most non-boss enemies.

CONCERN:
  This stacking is multiplicative. If bond combo is intended to be powerful
  but situational, the multiplication with weapon triangle + height creates
  a spike build that trivializes regular encounters.
  → No diminishing returns on any layer.
  → Only counter: don't let bonded pairs gain height advantage —
     but that's a tactical burden, not a balance mechanism.

Severity: INFO — documented for awareness; may be intentional power fantasy.
```

---

## Phase 5: Priority Fix Order

| Priority | Issue ID | Fix Location | Effort | Impact |
|----------|----------|-------------|--------|--------|
| 1 | D-01 | resource-economy.md | HIGH | Economy drives all progression |
| 2 | C-02 | tactical-mechanism.md + worldbuilding-narrative.md | LOW | Canonical element system |
| 3 | C-01 | class-system.md + fog-of-war-system.md | LOW | Missing class |
| 4 | C-03 | resource-economy.md + equipment-system.md | LOW | Tuning knob ownership |
| 5 | W-03 | tactical-mechanism.md | LOW | Stacking cap |
| 6 | W-04 | boss-system.md | LOW | Phase skip behavior |
| 7 | W-02 | tactical-mechanism.md | LOW | Map tier alignment |
| 8 | W-01 | ai-system.md + resource-economy.md | LOW | Dependency symmetry |
| 9 | W-05 | tactical-mechanism.md + bond-system.md | LOW | Distance metric |
| 10 | W-06 | systems-index.md + 总纲 | MED | Stale tracker |
| 11 | D-02 | Multiple | MED | Cognitive load reduction |
| 12 | D-03 | equipment-system.md | LOW | Safe zone no-decision |
| 13 | D-04 | resource-economy.md | LOW | Catch-up mechanism |
| 14 | I-01 | attribute-growth-system.md | LOW | SOU definition |
| 15 | I-02 | ai-system.md | LOW | Auto-battle AI profile |

---

## Summary

The GDD corpus is comprehensive and well-structured. The 23 systems cover the full SRPG experience. However, **4 blocking issues** prevent architecture from proceeding:

1. **Gold economy is broken** — sinks dramatically exceed sources, creating permanent scarcity and potential unrecoverable states
2. **Element count disagreement** — narrative says 5, tactical says 4
3. **Missing class** — fog-of-war references a class that doesn't exist
4. **Dual ownership** — enhancement parameters claimed by two GDDs

Fix the blocking issues, then address warnings in priority order. The design theory issues (cognitive load, dominant strategy, no catch-up) are important but not architecture-blockers — they can be resolved during GDD revision.

**Next step**: Fix blocking issues, then re-run `/review-all-gdds` to verify clean pass before `/gate-check`.

---

## Blocker Fix Log — 2026-04-23

| Issue ID | Fix | Files Modified |
|----------|-----|---------------|
| D-01 | Gold income boosted 3x: base 50→200 (normal), 100→400 (boss), coeff 0.1→0.3, kill bonus 20→50. New 30-chapter income ~46,800 vs sinks ~28,000. | resource-economy.md, battle-settlement.md |
| C-02 | 4-element tactical + 5-element lore coexistence documented. 金 is narrative-only, not in combat. | tactical-mechanism.md, worldbuilding-narrative.md |
| C-01 | Added BASIC_SCOUT (AGI/WIL, vision+3) + ADV_RANGER advanced class. | class-system.md |
| C-03 | Removed success rate/降级/失败 probability knobs from resource-economy. Added explicit cross-reference to equipment-system.md. | resource-economy.md |

### Warning Fix Log — 2026-04-23

| Issue ID | Fix | Files Modified |
|----------|-----|---------------|
| W-01 | Added difficulty-system reference to ai-system and resource-economy Dependencies | ai-system.md, resource-economy.md |
| W-02 | Added 20x20 tier to tactical-mechanism map sizes (now 3-tier: 15/20/25) | tactical-mechanism.md |
| W-03 | Added combined damage multiplier hard cap of ×3.0 (all sources) | tactical-mechanism.md |
| W-04 | Defined phase skip behavior: sequential through all crossed thresholds | boss-system.md |
| W-05 | Defined Manhattan distance as the standard metric; bond-system cross-references tactical | tactical-mechanism.md, bond-system.md |
| D-02 | Bond attribute bonuses marked as passive/auto-apply to reduce combat cognitive load | bond-system.md |
| D-03 | Added design note to equipment safe zone about lack of decision | equipment-system.md |
| D-04 | Added gold catch-up mechanisms: equipment selling, quest rewards, replay | resource-economy.md |
