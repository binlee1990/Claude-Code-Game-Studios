# Windows Build Smoke Test — 2026-04-25

## Metadata
- **Date**: 2026-04-25
- **Build source**: branch `0.0.1`, working tree after Production gate sync
- **Export preset**: `Windows Desktop`
- **Artifact**: `builds/windows/SRPG.exe`
- **Artifact size**: 105,033,016 bytes
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
- Production content batch rerun: after Chapter 1 tutorial content/presentation changes, Windows release export exited with code 0, regenerated `builds/windows/SRPG.exe` at 104,959,592 bytes, and process launch smoke passed. Full manual packaged-build playthrough was not rerun for this batch.
- Post-battle settlement rerun: after reward/settlement integration, Windows release export exited with code 0, regenerated `builds/windows/SRPG.exe` at 104,967,496 bytes, and process launch smoke passed. Full manual packaged-build playthrough was not rerun for this patch.
- Campaign/camp/tactics rerun: after Chapter 1 follow-up battle, default camp growth, tactical modifiers, AI target/position selection, and SaveManager provider hardening, Windows release export exited with code 0, regenerated `builds/windows/SRPG.exe` at 105,008,216 bytes, and process launch smoke passed (`still_running_after_5s=True`). Full manual packaged-build playthrough was not rerun for this patch.
- Chapter 1 complete release rerun: after third battle, independent management screen, generated audio cues, localization catalog, and release packaging script, Windows release export exited with code 0, regenerated `builds/windows/SRPG.exe` at 105,033,016 bytes, SHA-256 `42EA5D6E6903C04AC1D2A72CC6BA6EC768B8DF4823923BA67A1DA37B8B9CE9A4`, packaged scripted playthrough exited with code 0, and process launch smoke passed (`still_running_after_5s=True`). Human subjective packaged-build playthrough remains an external sign-off gate.

## Next
- Extend Chapter 2 content and run external human subjective UI/UX release sign-off.
