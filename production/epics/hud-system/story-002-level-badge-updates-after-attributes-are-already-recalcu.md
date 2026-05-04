# Story 002: level badge updates after attributes are already recalculated

> **Epic**: HUD 系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/hud-system.md`
**Requirement**: `TR-hud-system-001` — HUD displays MVP resources, level/realm, zone, combat, and offline summaries using EventBus and NumberFormatter.

**ADR Governing Implementation**: ADR-0011: UI 屏幕管理架构
**ADR Decision Summary**: Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0011 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Build UI screens as Godot `Control` scenes managed by UIManager** — source: ADR-0011
- Required: **Test both mouse and keyboard/gamepad focus paths under Godot 4.6 dual-focus behavior** — source: ADR-0011, ADR-0012
- Required: **Use EventBus subscriptions and read-only queries for display state** — source: ADR-0011
- Required: **Route player actions through explicit command methods on owning systems** — source: ADR-0011
- Forbidden: **Never let UI directly mutate ResourceSystem or AttributeSystem state** — source: ADR-0011
- Forbidden: **Never let UI/HUD/DebugConsole implement duplicate BigNumber formatting** — source: ADR-0014
- Forbidden: **Never ship active DebugConsole UI, listeners, or `_process` work in Release exports** — source: ADR-0012
- Guardrail: **HUD/UI**: coalesce or throttle high-frequency resource/attribute refreshes — source: ADR-0011
- Guardrail: **Lists**: virtualize large logs, inventory, and bestiary rows — source: ADR-0011
- Guardrail: **NumberFormatter**: 1000 formatting calls target <= 1 ms — source: ADR-0014

---

## Acceptance Criteria

*From GDD `design/gdd/hud-system.md`, scoped to this story:*

- [ ] GIVEN: `level.changed` includes entity_id player, **WHEN** HUD handles it, **THEN** level badge updates after attributes are already recalculated.
- [ ] GIVEN: 50 resource events in one frame, **WHEN** HUD updates, **THEN** only one layout refresh occurs.

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

- Must build screens as Godot `Control` scenes managed by UIManager.
- Must test both mouse and keyboard/gamepad focus paths in Godot 4.6.
- Must use EventBus subscriptions and read-only queries for display state.
- Must route player actions through explicit command methods on owning systems.
- Must format every BigNumber through NumberFormatter.
- Must coalesce or throttle high-frequency resource/HUD refreshes.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: `level.changed` includes entity_id player, **WHEN** HUD handles it, **THEN** level badge updates after attributes are already recalculated.
  - Setup: `level.changed` includes entity_id player
  - Verify: HUD handles it
  - Pass condition: level badge updates after attributes are already recalculated

- **Manual check**: GIVEN: 50 resource events in one frame, **WHEN** HUD updates, **THEN** only one layout refresh occurs.
  - Setup: 50 resource events in one frame
  - Verify: HUD updates
  - Pass condition: only one layout refresh occurs

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/level-badge-updates-after-attributes-are-already-recalcu-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
