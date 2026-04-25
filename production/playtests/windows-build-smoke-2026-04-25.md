# Windows Build Smoke Test — 2026-04-25

## Metadata
- **Date**: 2026-04-25
- **Build source**: branch `0.0.1`, working tree after Production gate sync
- **Export preset**: `Windows Desktop`
- **Artifact**: `builds/windows/SRPG.exe`
- **Artifact size**: 104,919,240 bytes
- **Status**: PASS — process launch smoke + full packaged-build playthrough

## Checks
- [x] Local Godot export preset exists.
- [x] Windows release export command exits with code 0.
- [x] `builds/windows/SRPG.exe` is generated.
- [x] Exported executable starts as a Windows process.
- [x] Smoke process can be closed cleanly after launch.
- [x] Full manual packaged-build playthrough passes:
  - Main menu opens.
  - Battle starts from the menu.
  - Auto and manual actions are usable.
  - Save works.
  - Load works.
  - Return to main menu works.

## Notes
- `export_presets.cfg` and `builds/` are intentionally git-ignored local/build artifacts.
- Full packaged-build playthrough was reported PASS by the human reviewer.

## Next
- Start UI/UX polish for the battle flow, with emphasis on stronger presentation and less abrupt combat framing.
