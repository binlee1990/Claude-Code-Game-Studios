# Resource Menu Evidence

**Date**: 2026-04-23  
**Scope**: `UI-002`  
**Status**: Automated evidence complete; manual walkthrough pending

## Automated Evidence

- `tests/integration/ui/battle_hud_test.gd`
  - resource HUD updates from inventory events
  - menu overlay opens / closes
  - inventory tab content updates

- `tests/integration/ui/save_load_integration_test.gd`
  - UI preference persistence verified

## Implementation Notes

- Top HUD now shows core resources
- Menu overlay provides character / inventory / save-load / settings tabs
- Save and load actions are wired through `SaveManager`

## Pending Manual Verification

- Full keyboard-navigation walkthrough
- Menu usability pass during live play
