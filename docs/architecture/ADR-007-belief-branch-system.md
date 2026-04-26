# ADR-007: 信念值与分支系统

> **Status**: Accepted
> **Date**: 2026-04-26
> **Author**: technical-director
> **Supersedes**: N/A
> **Systems Affected**: Save System, Battle Settlement, Narrative Systems

---

## Context

Chapter 2 introduces the first belief-value routing decision (B2-GATE) that splits players
into two distinct battle paths (mercy/suppression). This ADR codifies the belief value
model, branching formula, and persistence requirements so implementation stays consistent
across all affected systems.

The belief system was previously implicit in GDD notes. With Sprint-003 implementing
CH2-c-001 (B2-GATE), formalizing the architecture prevents divergence.

---

## Decision

### 1. Belief Value Model

Three independent belief attributes: `ren` (仁), `yi` (义), `zhi` (智).
Each is a 16-bit integer in range `[0, 100]`.

| Field | Type | Range | Notes |
|-------|------|-------|-------|
| `belief_values.ren` | int | [0, 100] | 仁 — mercy/compassion toward the weak |
| `belief_values.yi` | int | [0, 100] | 义 — order/discipline through strength |
| `belief_values.zhi` | int | [0, 100] | 智 — pragmatism/wisdom through strategy |

All three values are **independent** (not zero-sum). A player can have high ren AND high zhi.

### 2. Clamp Semantics

All belief value changes are clamped to `[0, 100]`. Overflow is silently truncated.
The `BeliefSystem.apply_change()` method returns both the requested delta and the
actual applied delta (may differ due to clamping).

```gdscript
# Example
belief_values.ren = 95
applied = system.apply_change(REN, +10)  # returns +5, value becomes 100
```

### 3. B2-GATE Formula

```
margin = yi - max(ren, zhi)

if margin >= 5:
    branch = "suppression"   # 义路线
else:
    branch = "mercy_default"  # 仁/智 路线（含平局默认）
```

- **Branch threshold**: 5 (safe range [3, 10], gate knob `branch_threshold`)
- **Tie case** (`yi == max && margin == 0`): routes to `mercy_default`
- **Output field**: `progress_data.belief_branch` (string)
- **Permitted values**: `"mercy"`, `"mercy_default"`, `"suppression"`

### 4. Persistence

Belief values and branch result are stored in `SaveData.story_progress`:

```json
{
  "belief_values": {"ren": 0, "yi": 0, "zhi": 0},
  "belief_branch": "mercy_default"
}
```

The `BeliefSystem` class owns load/save for belief values.
The `BeliefGate` class owns B2-GATE evaluation and branch persistence.

### 5. Soft/Hard Lock

| Lock | Trigger | Effect |
|------|---------|--------|
| Soft lock | `abs(yi - max(ren,zhi)) >= 20` | Branch weights ×0.5 / ×1.5; reversible |
| Hard lock | `abs(yi - max(ren,zhi)) >= 40` after Ch.4 | Route fixed;三条线独立内容 |

Soft and hard lock are deferred to Ch.3+ (not implemented in Ch.2).

### 6. Events

`GameEvents.belief_changed(belief: int, delta: int, applied: int, new_value: int)` fires
on every belief value change (including clamped changes).

---

## Consequences

### Positive

- Single source of truth for belief value arithmetic and persistence
- B2-GATE formula is data-driven (threshold configurable via gate knob)
- Clamp semantics explicit — no silent overflow bugs
- Event bus integration enables UI to react to belief changes

### Negative

- Belief values persist indefinitely (no reset between chapters without explicit design)
- `mercy_default` vs `mercy` distinction requires menu script awareness

---

## ADR Dependencies

- **ADR-001** (Event Architecture): `belief_changed` signal via GameEvents
- **ADR-003** (Save System): Belief values stored in `story_progress` namespace
- **ADR-004** (Combat System): B2-GATE triggered by Ch.2-1 battle settlement
- **ADR-005** (AI Behavior): Belief values may influence NPC dialogue in future chapters

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| `clampi()` for int clamping | ✓ |
| `Signal.emit()` typed parameters | ✓ |
| Autoload singleton for GameEvents | ✓ |

---

## GDD Requirements Addressed

- `design/gdd/chapter-02.md` §3.8 (信念值分支节点规则)
- `design/gdd/chapter-02.md` §4.5 (分叉阈值公式)
- `design/narrative/belief-branching.md` §4.1 (B2-GATE 参数)
