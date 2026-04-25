# Windows Build Smoke Test — 2026-04-26

## Metadata
- **Date**: 2026-04-26
- **Sprint**: sprint-002 closure smoke
- **Build source**: branch `0.0.1`, working tree post Sprint-002 lane A/B/C delivery
- **Export preset**: `Windows Desktop`
- **Artifact**: `builds/windows/SRPG.exe`
- **Artifact size**: 124,023,824 bytes (~118 MB; +13 MB vs 2026-04-25 build, accounted for by 2 OFL fonts + 2 OGG BGM tracks ≈ 21 MB minus PCK compression)
- **Artifact SHA-256**: `1ff5000d4bb0727ae1b8a18f96f6f3c1464af172eb3eeecca1439f15356025e8`
- **Status**: **PASS** — packaged scripted playthrough exited 0 with full success report

## Pre-Smoke Issues Resolved

| Issue | Resolution |
|-------|-----------|
| Initial export failed: `重命名临时文件 'builds/windows/SRPG.tmp' 失败` | Removed stale `SRPG.exe` + `SRPG.tmp` artifacts in `builds/windows/`; re-ran export, exited 0 |
| 2 stale `SRPG.exe` processes (PID 45856 / 75168) from 2026-04-25 | Did not interfere with re-export after artifact removal; left for user cleanup if desired |

## Checks
- [x] `export_presets.cfg` exists locally
- [x] Windows release export command exits with code 0
- [x] `builds/windows/SRPG.exe` is regenerated (124 MB)
- [x] Packaged scripted playthrough smoke exits with code 0
- [x] Playthrough success report includes:
  - `battle`: `chapter_01_finale` (third battle reached)
  - `management_tab`: `equipment` (independent management screen visible)
  - `camp_report_present`: `true` (campaign state restored after save/load round-trip)
  - `success`: `true`

## Stdout Highlights

```
Godot Engine v4.6.2.stable.official.71f334935
Vulkan 1.4.329 - Forward+ - NVIDIA GeForce RTX 4090
PACKAGED_PLAYTHROUGH_SMOKE PASS {"battle":"chapter_01_finale","camp_report_present":true,"management_tab":"equipment","success":true}
```

## Sprint-002 Asset Validation Coverage (Implicit)

The packaged scripted playthrough exercises the full Ch.1 path (tutorial → crossroads → finale) with:
- Main menu instantiation → triggers `_setup_bgm()` → loads `assets/audio/bgm/main_menu_bgm.ogg` from PCK
- Battle scene instantiation → triggers `_setup_battle_bgm()` → loads `assets/audio/bgm/battle_bgm.ogg` from PCK
- Theme application → loads `assets/fonts/zcool_xiaowei.ttf` + `assets/fonts/noto_serif_sc.otf` from PCK
- Save/load round-trip → exercises `SaveManager.peek_save` only-read path indirectly via existing flows

A failure to bundle any of those resources would have produced `ERROR: No loader found for resource: ...` in stdout (as seen in dev mode before `--editor` import scan was run on 2026-04-26). The PASS result confirms `.import` files are bundled correctly into the PCK.

## Notes
- `export_presets.cfg` and `builds/` remain git-ignored.
- This run does NOT replace the human-subjective UI/UX release sign-off, which remains a separate gate before any public-facing distribution.
- Kevin MacLeod (CC-BY 3.0) attribution string MUST be displayed in `design/ux/credits-screen.md` (TODO Sprint-003) before any public build.
- License audit trail: `assets/audio/bgm/LICENSE.md` + `assets/fonts/LICENSE.md` + `design/ux/credits.md`.

## Next
- Human visual sign-off (截图归档至 `production/qa/evidence/sprint-002-presentation-p0.md`)
- Sprint-003 planning (建议主题：内容扩展 Ch.3 + 管理屏 Beta 目标 + ADR-007/008/009 + 6 系统 epic 化)
