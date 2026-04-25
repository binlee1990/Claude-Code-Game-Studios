# Windows Build Smoke Test — 2026-04-25

## Metadata
- **Date**: 2026-04-25
- **Build source**: branch `0.0.1`, working tree after Production gate sync
- **Export preset**: `Windows Desktop`
- **Artifact**: `builds/windows/SRPG.exe`
- **Artifact size**: 104,919,240 bytes
- **Status**: PASS — process launch smoke

## Checks
- [x] Local Godot export preset exists.
- [x] Windows release export command exits with code 0.
- [x] `builds/windows/SRPG.exe` is generated.
- [x] Exported executable starts as a Windows process.
- [x] Smoke process can be closed cleanly after launch.

## Notes
- `export_presets.cfg` and `builds/` are intentionally git-ignored local/build artifacts.
- This smoke test only proves that the exported executable starts. It does not replace a full manual clean-directory playthrough.

## Next
- Run a full manual packaged-build playthrough: main menu -> battle -> Auto/manual action -> save -> load -> return to main menu.
