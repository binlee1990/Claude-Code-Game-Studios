# Sprint-008 QA Evidence

Date: 2026-04-27
Scope: `production/sprints/sprint-008.md`
QA Plan: `production/qa/qa-plan-sprint-8.md`

## Automated Verification

| Check | Result |
|-------|--------|
| Godot check-only | PASS |
| Full GUT scene runner | PASS — `Total: 879 | Pass: 879 | Fail: 0` |
| Windows export | PASS — `builds/windows/SRPG.exe` |
| Export artifact | 124,334,616 bytes |
| Export SHA256 | `A472CE209E17ABEB74D8281E4CEEA8B099665FA4026F4FE1E3C568A76DF2FD64` |
| Packaged smoke | PASS |

Packaged smoke payload:

```json
{
  "b3_gate_route": "ren",
  "chapter3_act_b": true,
  "chapter3_finale": true,
  "chapter3_complete": true,
  "decompose_materials": 10,
  "finale_boss_phase": 3,
  "finale_variant": "civilian_evacuation",
  "reroll_preserved_level": 7,
  "success": true
}
```

## Story Evidence

| Story | Evidence |
|-------|----------|
| CH3-c-002 | `tests/unit/chapter03/battle_2_pressure_test.gd`; `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd` |
| CH3-c-003 | `tests/unit/chapter03/b3_gate_evaluator_test.gd`; `tests/integration/chapter03/b3_gate_persistence_test.gd` |
| EQUIP-UI-001 | `tests/unit/equipment/decomp_reroll_test.gd`; `tests/integration/equipment/decomp_reroll_ui_test.gd`; packaged smoke decompose/reroll fields |
| CH3-c-004 | `tests/unit/chapter03/finale_route_variant_test.gd`; `tests/integration/chapter03/finale_boot_test.gd` |
| ARCH-CONCERN-001 | `docs/architecture/architecture.md` v0.3 covers ADR-001~009, Base flow, Ch.3 flow, and no premature `trigger_combo_skill` interface |
| BOND-COMBO-DESIGN | `design/gdd/bond-system.md` Sprint-008 combo spec |
| FOG-GDD | `design/gdd/fog-of-war-system.md` Sprint-008 MVP-ready spec |

## Manual / External Notes

The sprint excludes public release sign-off, screenshot capture, and human playtest. UI behavior is covered by integration tests and packaged smoke. B3-GATE player comprehension playtest remains external human QA, not a blocker for automated Sprint-008 completion.
