# AI-Automated Evidence — Sprint-009/010 Hardening

> **Date**: 2026-05-02
> **Status**: AI-solvable items complete

## Completed Automatically

| Area | Result | Evidence |
|---|---|---|
| Difficulty autoload blocker | RESOLVED | Removed the conflicting script `class_name DifficultyManager`; packaged smoke starts without autoload errors |
| Strict packaged smoke gate | COMPLETE | `tools/package_windows_release.ps1` fails on missing smoke PASS, smoke FAIL, `SCRIPT ERROR`, or `ERROR:` |
| Full GUT gate in package script | COMPLETE | Package script waits for full summary and parsed `Total=1037 Pass=1037 Fail=0` |
| Equipment +11+ extreme-risk | COMPLETE | Real success rates and protection symbol costs apply above +10; insufficient symbols block mutation |
| Invalid save handling | COMPLETE | Invalid/corrupt save resource returns false without pending loaded data |
| Fog save/targeting contract | COMPLETE | Restored explored cells stay explored; only currently visible cells are targetable |
| Sprint-010 governance gaps | COMPLETE | Quick specs, level index, balance index, bug tracking, regression suite, launch checklist, and gate review updated |

## Verification

| Command | Result |
|---|---|
| `godot --headless --check-only project.godot` | PASS, exit 0 |
| `godot --headless res://tests/test_runner.tscn` | PASS, `Total: 1037 | Pass: 1037 | Fail: 0` |
| `powershell -ExecutionPolicy Bypass -File tools\package_windows_release.ps1` | PASS, full GUT summary + export + strict packaged smoke |

## Artifact

| Artifact | Value |
|---|---|
| Windows build | `builds/windows/SRPG.exe` |
| Bytes | `124407080` |
| SHA256 | `3530468C51EE43725DC5F54B2A3540351671711EC5DE4D40A5626C463CBE0E6A` |

## Still Human-Only

Visual readability screenshots, three-player Ch.2 playtest, BGM loop listening, release sign-off, and subjective difficulty/equipment feel remain in `production/sprints/sprint-人工.md`.
