# Chapter 1 Complete Release Evidence — 2026-04-25

## Scope

Final agent-verifiable production pass for the current Chapter 1 slice.

Implemented coverage:

- Chapter 1 now has three formal battles:
  - `chapter_01_tutorial`
  - `chapter_01_crossroads`
  - `chapter_01_finale`
- The third battle adds watchtower pacing, a deployed reserve Rogue, new terrain, final Boss phase behavior, and final Chapter 1 story flags.
- The battle scene has an independent campaign readiness screen with Rewards, Camp, Party, and Equipment tabs.
- The main menu and management labels now use a lightweight runtime localization catalog.
- The battle path now plays generated runtime audio cues for menu, camp, attack, save/error, and victory feedback.
- Release packaging is captured in `tools/package_windows_release.ps1` and `production/release/release-manifest-2026-04-25.md`.
- Exported builds support `--srpg-playthrough-smoke`, which runs the packaged exe through the Chapter 1 path, management screen, save, and load without scene-path override.

## Automated Evidence

Commands run from `D:\work\Games\SRPG`:

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --check-only project.godot
```

Result: PASS, exit code 0.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless res://tests/test_runner.tscn
```

Result: PASS — `Total: 686 | Pass: 686 | Fail: 0`.

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --export-release 'Windows Desktop' 'builds/windows/SRPG.exe'
```

Result: PASS, exit code 0.

Packaged scripted playthrough:

```powershell
& 'builds/windows/SRPG.exe' --headless --srpg-playthrough-smoke
```

Result: PASS, exit code 0.

Process launch smoke:

- Artifact: `builds/windows/SRPG.exe`
- Size: 105,033,016 bytes
- SHA-256: `42EA5D6E6903C04AC1D2A72CC6BA6EC768B8DF4823923BA67A1DA37B8B9CE9A4`
- Started successfully: yes
- Still running after 5 seconds: yes
- Closed by smoke script after launch: yes

## Regression Coverage Added

- `tests/integration/prototypes/battle_arena_entry_test.gd`
  - three-battle Chapter 1 campaign reaches the finale
  - finale briefing, reserve deployment, terrain, Boss, and completion flags are present
- `tests/integration/ui/battle_hud_test.gd`
  - independent management screen exposes Rewards, Camp, Party, and Equipment
  - localization catalog and audio cues are wired
- `tests/integration/save/battle_save_manager_integration_test.gd`
  - management screen visibility and active tab persist through SaveManager

## Remaining External Gates

- Human subjective UI/UX sign-off still requires a person to play and judge feel/readability.
- Generated audio cues and runtime localization catalog are production scaffolds, not final art/audio/localization assets.
- Chapter 2+ content remains future production scope.
