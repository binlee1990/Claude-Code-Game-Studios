# Post-Battle Settlement Evidence — 2026-04-25

## Scope

Production-phase reward closure for the formal Chapter 1 battle path.

Implemented coverage:

- `chapter_01_tutorial` defines settlement seed and per-enemy reward metadata
- victory builds a settlement summary from battle result, player damage/deaths, surviving units, defeated enemy tiers, and difficulty profile
- rewards apply to live game state: survivor class EXP, inventory gold/materials, and generated equipment on a surviving player unit
- result label and `Settlement` menu tab expose rating, EXP, gold, materials, equipment, damage taken, deaths, and reward note
- SaveManager captures and restores post-battle settlement summary, rewarded inventory, and victory story progress

## Automated Evidence

Commands run from `D:\work\Games\SRPG`:

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --check-only project.godot
```

Result: PASS, exit code 0.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless res://tests/test_runner.tscn
```

Result: PASS, exit code 0.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --export-release 'Windows Desktop' 'builds/windows/SRPG.exe'
```

Result: PASS, exit code 0. Exported artifact size: 104,967,496 bytes.

Process launch smoke:

- Artifact: `builds/windows/SRPG.exe`
- Started successfully: yes
- Still running after 5 seconds: yes
- Closed by smoke script after launch: yes

## Regression Coverage Added

- `tests/integration/prototypes/battle_arena_entry_test.gd`
  - victory generates settlement rewards
  - EXP/gold/materials/equipment are positive on Chapter 1 victory
  - rewarded inventory and surviving class EXP are updated
  - Settlement menu shows reward details
- `tests/integration/ui/battle_hud_test.gd`
  - Settlement tab shows an empty pre-result state before battle end
- `tests/integration/save/battle_save_manager_integration_test.gd`
  - SaveManager restores post-battle settlement data
  - rewarded inventory and victory story progress survive save/load

## Remaining Product Risks

- Dedicated reward-screen flow is still menu/result-label based; no animated confirmation screen yet.
- Reward equipment is assigned to the first surviving player unit, not to a global inventory/loadout screen.
- Full manual packaged-build playthrough was not rerun after this settlement-specific patch; only export and process launch smoke were rerun.
