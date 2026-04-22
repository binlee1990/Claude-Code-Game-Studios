# Vertical Slice — Battle Prototype

> Status: Playable
> Created: 2026-04-23
> Hypothesis: Core combat loop (turn order → move/attack → victory/defeat) is fun and strategically interesting

## How to Run

1. Open Godot 4.6.2
2. FileSystem → `prototypes/vertical-slice/vs_battle.tscn`
3. Right-click → **Play Scene** (F6)

Or headless:
```bash
godot --headless res://prototypes/vertical-slice/vs_battle.tscn
```

## What It Tests

| Feature | Status |
|---------|--------|
| Speed-based turn order (AGI sorting) | ✅ Implemented |
| Click-to-select unit flow | ✅ Implemented |
| Click-to-move (range 3) | ✅ Implemented |
| Click-to-attack (range 2) | ✅ Implemented |
| HP bars + damage calculation | ✅ Implemented |
| Enemy AI (move toward nearest, attack) | ✅ Implemented |
| Victory/defeat conditions | ✅ Implemented |
| Turn order display | ✅ Implemented |

## Setup

- 8×8 grid (simplified, no terrain)
- 2 player units (blue): Swordsman, Archer
- 2 enemy units (red): Dark Knight, Dark Mage
- Turn order sorted by AGI attribute

## Controls

| Input | Action |
|-------|--------|
| Click blue unit | Select current actor |
| Click blue cell | Move selected unit |
| Click red cell | Attack enemy in range |
| 1 | Select/Move mode |
| 2 | Attack mode |
| 3 | Standby (end turn) |
| 4 | End turn |

## Files

| File | Purpose |
|------|---------|
| `vs_battle.gd` | Main controller — all battle logic |
| `vs_battle.tscn` | Scene file — attaches script |
| `README.md` | This file |

## Dependencies (existing src/)

- `src/core/combat/combat_system.gd` — CombatSystem
- `src/core/combat/action_system.gd` — ActionSystem
- `src/core/combat/damage_calculation.gd` — DamageCalculation
- `src/core/autoload/game_events.gd` — GameEvents
- `src/core/unit.gd` — Unit
- `src/core/attributes/attribute_names.gd` — AttributeNames

## Acceptance Criteria

- [ ] Battle starts with 4 units visible on grid
- [ ] Turn order displayed correctly
- [ ] Current unit highlighted in gold
- [ ] Player can move selected unit within range
- [ ] Player can attack enemies in range
- [ ] HP bars update on damage
- [ ] Dead units visually grayed out
- [ ] Victory shown when all enemies die
- [ ] Defeat shown when all players die
- [ ] Enemy AI acts automatically

## Playtest Log

| Session | Date | Tester | Verdict | Notes |
|---------|------|--------|---------|-------|
| 1 | 2026-04-23 | — | PENDING | — |
| 2 | — | — | PENDING | — |
| 3 | — | — | PENDING | — |

## Findings

_To be updated after playtesting._
