# Story 006: Speed-Up Mode

> **Epic**: Turn-Based Mode
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: AC.4.1-4.3 (speed tiers: 1x/2x/3x)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: Normal mode = 1× animation speed, AI delay 0.5-1.5s
- [ ] AC.4.2: Fast mode = 2× animation speed, AI delay 0.2-0.5s
- [ ] AC.4.3: Max speed = 3× animation speed, AI delay 0s

---

## Implementation Notes

From GDD C.6: Three speed tiers affect animation playback rate and AI decision delay. Speed multiplier applies to all visual feedback (movement, attacks, skills). AI delay reduced proportionally. From E.6: At max speed, animations can be skipped — only show results (damage numbers remain visible). Combat outcomes are identical regardless of speed tier — only presentation changes.

---

## Out of Scope

- Speed toggle UI buttons
- Animation system implementation

---

## QA Test Cases

- **AC.4.1**: Normal speed
  - Given: Speed tier = normal (1×)
  - When: Combat runs
  - Then: Animation speed multiplier = 1.0, AI delay ∈ [0.5, 1.5]s

- **AC.4.2**: Fast speed
  - Given: Speed tier = fast (2×)
  - When: Combat runs
  - Then: Animation speed multiplier = 2.0, AI delay ∈ [0.2, 0.5]s

- **AC.4.3**: Max speed
  - Given: Speed tier = max (3×)
  - When: Combat runs
  - Then: Animation speed multiplier = 3.0, AI delay = 0s
  - Edge cases: Switching speed mid-combat → applies immediately to next action

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/speed_up_mode_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (combat flow provides the action loop)
- Unlocks: Story 007 (save/load persists speed setting)
