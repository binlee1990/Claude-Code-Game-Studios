# S11-005 Progressive Unlock

Status: Done.

Implementation:
- HUD reserves stable positions for status elements and updates from level/realm/zone/combat/offline events.
- The layout avoids reflow when status elements appear.

Evidence:
- `src/ui/shell/top_strip.gd`
- `production/qa/evidence/sprint-11/screenshots/toast_stack.png`

Assets: `res://assets/vfx/level_up_ring.png`.
