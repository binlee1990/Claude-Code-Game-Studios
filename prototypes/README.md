# SRPG Prototypes

## Vertical Slice Battle Demo

> Status: Active | Date: 2026-04-23
> Hypothesis: The core combat loop (turn order → move/attack → damage → end turn) is enjoyable and strategically interesting

### How to Run

1. Open project in Godot 4.6.2
2. In FileSystem dock, navigate to `prototypes/vertical-slice/vs_battle.tscn`
3. Right-click → **Play Scene** (F6)

Or from command line:
```bash
godot --path . res://prototypes/vertical-slice/vs_battle.tscn
```

### What It Tests

- Speed-based turn order (AGI sorting)
- Click-to-select unit → click-to-move → click-to-attack flow
- HP bars and damage calculation
- Simple enemy AI (move toward nearest player, attack)
- Victory/defeat conditions

### Controls

| Input | Action |
|-------|--------|
| Click blue unit | Select current actor |
| Click blue cell | Move selected unit |
| Click red cell | Attack enemy in range |
| 1 | Select/Move mode |
| 2 | Attack mode |
| 3 | Standby (end turn without attacking) |
| 4 | End turn |

### Setup

- 8x8 grid
- 2 player units (Swordsman, Archer) — blue
- 2 enemy units (Dark Knight, Dark Mage) — red
- Turn order sorted by AGI attribute

### Acceptance Criteria for VS

- [ ] Battle starts with 4 units visible on grid
- [ ] Turn order displayed correctly
- [ ] Current unit highlighted in gold
- [ ] Player can move selected unit within range
- [ ] Player can attack enemies in range
- [ ] HP bars update on damage
- [ ] Dead units visually grayed out
- [ ] Victory displayed when all enemies die
- [ ] Defeat displayed when all players die
- [ ] Enemy AI acts automatically

### Findings

_To be updated after playtesting._
