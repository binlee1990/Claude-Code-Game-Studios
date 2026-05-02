# BUG-001: DifficultyManager autoload emitted startup errors in packaged smoke

- **Severity**: HIGH
- **System**: difficulty-system
- **Reported**: 2026-05-02
- **Reporter**: Codex audit
- **Status**: RESOLVED

## Reproduction

1. Export or run `builds/windows/SRPG.exe`.
2. Run `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke`.
3. Observe the packaged smoke log.

## Expected

Packaged smoke reports `PACKAGED_PLAYTHROUGH_SMOKE PASS` without engine or script startup errors.

## Actual

The smoke payload reported PASS, but the same run emitted:

```text
Class "DifficultyManager" hides an autoload singleton.
Failed to instantiate an autoload, script 'res://src/core/difficulty/difficulty_manager.gd' does not inherit from 'Node'.
```

## Resolution

Removed the script-level `class_name DifficultyManager` registration and kept `DifficultyManager` as the project autoload singleton name. The package script now treats `SCRIPT ERROR`, `ERROR:`, or smoke FAIL output as a hard failure.

## Verification

- `godot --headless --check-only project.godot`: PASS
- `godot --headless res://tests/test_runner.tscn`: `Total: 1037 | Pass: 1037 | Fail: 0`
- `powershell -ExecutionPolicy Bypass -File tools\package_windows_release.ps1`: PASS; strict packaged smoke reports PASS without the DifficultyManager startup error after re-export
