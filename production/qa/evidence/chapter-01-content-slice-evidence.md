# Chapter 1 Content Slice Evidence — 2026-04-25

## Scope

Production-phase content/presentation batch for the formal battle path.

Implemented coverage:

- `main_menu -> battle` now loads `chapter_01_tutorial`
- battle definition drives map id, objective, resources, units, reserves, equipment, classes, difficulty, and story progress
- tutorial difficulty scales enemy HP and attributes
- player class skills are initialized from declared classes
- Skill action is exposed in the battle action bar
- Boss phase threshold creates a visible checkpoint and story progress payload
- equipment, roster, Boss, inventory, save, and settings are visible in the battle menu
- movement, attacks, hit flashes, damage numbers, and death fade have lightweight feedback
- SaveManager persists story progress, battle definition id, difficulty profile, Boss checkpoint, roster, equipment, inventory, camera/UI prefs, and battle history
- victory now generates settlement summary data and applies EXP, gold, materials, and equipment rewards

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

Result: PASS, exit code 0. Exported artifact size: 104,959,592 bytes.

Process launch smoke:

- Artifact: `builds/windows/SRPG.exe`
- Started successfully: yes
- Closed by smoke script after launch: yes

## Regression Coverage Added

- `tests/integration/prototypes/battle_arena_entry_test.gd`
  - formal battle path loads Chapter 1 content
  - tutorial difficulty scales enemies
  - content classes initialize correct class skills
  - Boss phase checkpoint updates below half HP
  - victory updates story progress and applies settlement rewards
- `tests/integration/ui/battle_hud_test.gd`
  - action bar includes Skill
  - save tab exposes story and difficulty
  - equipment, roster, and Boss tabs expose production systems
  - Settlement tab exposes a pre-result empty state
  - Skill action consumes MP and damages target
- `tests/integration/save/battle_save_manager_integration_test.gd`
  - SaveManager restores story progress
  - Boss checkpoint restores through battle state
  - roster class and class skills restore
  - battle state persists tutorial difficulty profile
  - post-battle settlement rewards persist through SaveManager

## Remaining Product Risks

- Full manual packaged-build playthrough was not rerun after this specific batch.
- Battle settlement rewards are visible in the battle result label and Settlement menu, but not yet a polished dedicated reward screen with player confirmation/animation.
- Chapter 1 currently has one tutorial encounter; follow-up encounter pacing is still future Production work.
