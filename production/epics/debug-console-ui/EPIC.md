# Debug Console UI Epic

Status: Done on 2026-05-05 via Sprint 11 completion pass.

## Scope

Expose the existing debug console command service through a visible Control overlay in debug builds.

## Stories

| Story | Status | Evidence |
|-------|--------|----------|
| S11-014-debug-console-ui | Done | `screenshots/debug_console.png` |

## Verification

- Visual smoke opens the debug console and runs `help`.
- `reports/report_21/results.xml`: debug console unit tests remain passing.
