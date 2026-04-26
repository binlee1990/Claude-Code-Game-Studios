# Sprint-005 Packaged Smoke Resource Triage

> Date: 2026-04-27
> Task: TECH-001
> Status: Complete

## Symptom

The pre-Sprint-005 packaged smoke passed functionally but exited with Godot resource warnings:

- `ObjectDB instances leaked at exit`
- `4 resources still in use at exit`
- Verbose output identified `main_menu_bgm.ogg` and `battle_bgm.ogg` AudioStream / OggPacketSequence references.

## Root Cause

The packaged smoke path used the normal main-menu and battle scenes, which initialized BGM players even though the process exits immediately after the automated smoke. The fast quit path left OGG stream playback resources referenced at shutdown.

## Fix

`main_menu.gd` and `battle_arena.gd` now skip BGM initialization when `--srpg-playthrough-smoke` is present, matching the smoke path's non-interactive purpose.

## Verification

Re-exported local Windows build:

```text
godot --headless --export-release "Windows Desktop" builds/windows/SRPG.exe
```

Then ran:

```text
builds/windows/SRPG.exe --headless --verbose --srpg-playthrough-smoke
```

Result:

```text
PACKAGED_PLAYTHROUGH_SMOKE PASS {"battle":"chapter_01_finale","camp_report_present":true,"management_tab":"equipment","success":true}
```

No ObjectDB leak warning and no resources-still-in-use error appeared after the fix.

## Residual Risk

The verbose smoke still prints unrelated controller mapping warnings for `misc2`. These are engine/platform input mapping warnings and do not affect the smoke path.
