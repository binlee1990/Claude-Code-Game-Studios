# Campaign, Camp, and Tactics Evidence — 2026-04-25

## Scope

Production-system completion batch for the formal battle path after the tutorial and settlement pass.

Implemented coverage:

- `chapter_01_tutorial` now advances into `chapter_01_crossroads`
- default recommended camp plan runs automatically before the next battle when the player has not already camped
- camp actions can learn baseline skills, add class unlock EXP, use available STR fruit, and enhance equipped gear when resources allow
- battle state persists the current battle definition, story progress, camp report, tactical terrain, difficulty profile, Boss state, roster, inventory, and UI/camera state
- formal battle now uses terrain overrides, high/low ground, weapon triangle, elemental terrain reactions, unit movement/range profiles, and AI target/position selection
- campaign, camp, and tactics tabs expose the newly connected systems in the battle menu
- SaveManager now chooses the most complete active runtime provider and loads saves with cache bypass, preventing stale/empty scene state from overwriting valid battle saves

## Automated Evidence

Commands run from `D:\work\Games\SRPG`:

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --check-only project.godot
```

Result: PASS, exit code 0.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless res://tests/test_runner.tscn
```

Result: PASS — `Total: 682 | Pass: 682 | Fail: 0`.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --export-release 'Windows Desktop' 'builds/windows/SRPG.exe'
```

Result: PASS, exit code 0. Exported artifact size: 105,008,216 bytes.

Process launch smoke:

- Artifact: `builds/windows/SRPG.exe`
- Started successfully: yes
- Still running after 5 seconds: yes
- Closed by smoke script after launch: yes

## Regression Coverage Added

- `tests/integration/prototypes/battle_arena_entry_test.gd`
  - formal battle loads tactical profiles and terrain overrides
  - tutorial victory advances to the second Chapter 1 battle
  - automatic camp plan trains baseline skills before campaign advance
- `tests/integration/ui/battle_hud_test.gd`
  - Campaign, Camp, and Tactics tabs expose production systems
- `tests/integration/save/battle_save_manager_integration_test.gd`
  - SaveManager writes full roster/inventory/progress data
  - SaveManager restores the campaign follow-up battle, camp report, and tactical terrain

## Remaining Product Risks

- The camp and campaign flows are currently menu/report driven with default recommended choices; dedicated management screens are still future UX work.
- Chapter 1 now has two battles, but later encounters and narrative pacing are still content backlog.
- Full manual packaged-build playthrough was not rerun after this patch; automated tests, export, and process launch smoke were rerun.
