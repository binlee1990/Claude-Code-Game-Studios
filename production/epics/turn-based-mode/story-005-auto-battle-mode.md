# Story 005: Auto Battle Mode

> **Epic**: Turn-Based Mode
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: AC.3.1-3.3 (auto-battle AI takeover, toggle, manual override)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: Auto-battle ON → AI controls player unit decisions (target, skill, movement)
- [ ] AC.3.2: Auto-battle can be toggled OFF at any time
- [ ] AC.3.3: Player can manually override during auto-battle (pause auto for current unit)

---

## Implementation Notes

From GDD C.5: Auto-battle uses AI system for player units. AI selects target (threat-based), skill (highest expected value), and position (best scoring). From E.5: If items run out during auto-battle → skip that action, don't interrupt flow. Toggle is immediate — ON means next unit is AI-controlled, OFF means next unit is player-controlled.

---

## Out of Scope

- Auto-battle toggle UI button
- AI decision quality (uses existing AI system logic)

---

## QA Test Cases

- **AC.3.1**: AI takeover
  - Given: Auto-battle ON, player unit's turn
  - When: Unit should act
  - Then: AI selects target, skill, and position automatically
  - Edge cases: Multiple player units → each controlled by AI in sequence

- **AC.3.2**: Toggle off
  - Given: Auto-battle ON mid-combat
  - When: Player toggles OFF
  - Then: Next player unit returns to manual control
  - Edge cases: Toggle during AI decision → current unit finishes AI action, next is manual

- **AC.3.3**: Manual override
  - Given: Auto-battle ON, player unit's turn starting
  - When: Player presses manual override
  - Then: Current unit reverts to manual control for this turn
  - Edge cases: Override only for current unit, next unit is AI again

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/auto_battle_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (combat flow), Cross-epic: AI System Stories 001-003
- Unlocks: Story 007 (save/load persists auto-battle state)
