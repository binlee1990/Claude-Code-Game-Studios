# Launch Checklist — SRPG

> **Generated**: 2026-05-02
> **Project Stage**: Production
> **Target Platform**: PC (Steam)
> **Scope**: Indie solo-dev — 标记为 "indie exempt" 的项不适用

---

## 1. Code / Build

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| C01 | `godot --check-only` exit 0 | ✅ PASS | Sprint-009 verified | CI |
| C02 | GUT full suite ≥1021 PASS | ✅ PASS | Sprint-009 baseline | CI |
| C03 | Windows export exit 0 | ✅ PASS | Sprint-009 verified | CI |
| C04 | Packaged .exe launches without errors | ⏳ | MAN-012 pending | Human |
| C05 | No debug prints in release build | ⏳ | 待检查 | Agent |
| C06 | No hardcoded file paths (uses res:// or user://) | ✅ PASS | Architecture ADR-002/003 | — |
| C07 | Asset bundle loads without missing dependency warnings | ⏳ | 待 packaged smoke | Human |
| C08 | No ObjectDB leak warnings on quit | ✅ PASS | Sprint-009 verified | CI |

## 2. Content

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| CT01 | Ch.1 playable from new game to settlement | ✅ PASS | Sprint-008 packaged smoke | CI |
| CT02 | Ch.2 playable (3 battles + B2-GATE + finale) | ✅ PASS | Sprint-008 packaged smoke | CI |
| CT03 | Ch.3 playable (3 battles + B3-GATE + finale) | ✅ PASS | Sprint-008 packaged smoke | CI |
| CT04 | Fog-of-war enabled battle playable | ⏳ | MAN-012 pending | Human |
| CT05 | Bond combo skill triggerable in battle | ⏳ | MAN-012 pending | Human |
| CT06 | All battle definitions load without parse errors | ✅ PASS | godot --check-only | CI |
| CT07 | Save/Load round-trip across all 3 chapters | ✅ PASS | Integration tests | CI |
| CT08 | Difficulty multipliers apply correctly | ⏳ | MAN-010 pending | Human |

## 3. UI / UX

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| UI01 | Main menu: New Game / Load / Credits / Settings / Quit all functional | ✅ | MAN-DONE-001 | Human |
| UI02 | Battle HUD: HP/status/speed/skills visible and correct | ✅ | MAN-DONE-001 | Human |
| UI03 | Character management: tabs switch, equipment equip/unequip | ✅ | Sprint-004 | Agent |
| UI04 | Base hub: all areas accessible from hub | ✅ | Sprint-007 | Agent |
| UI05 | Language switch: immediate UI refresh | ✅ | Sprint-005 | Agent |
| UI06 | Credits screen: all contributors visible | ✅ | Sprint-005 | Agent |
| UI07 | Keyboard navigation: all menus reachable by keyboard | ⏳ | 待 UX review | Human |
| UI08 | Gamepad: menus navigable, battle actions selectable | ⏳ | 无手柄测试 | Human |
| UI09 | UI text not truncated at any supported resolution | ⏳ | 待 visual sign-off | Human |
| UI10 | Fog overlay visually distinguishable (3 states) | ⏳ | MAN-008 pending | Human |
| UI11 | Combo button active/disabled states clear | ⏳ | MAN-009 pending | Human |
| UI12 | Boss name/phase/telegraph visible in battle | ⏳ | MAN-011 pending | Human |

## 4. Audio

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| AU01 | Main menu BGM autoplays on launch | ✅ | Sprint-002 Lane B | Human |
| AU02 | Battle BGM autoplays on battle start | ✅ | Sprint-002 Lane B | Human |
| AU03 | BGM loops seamlessly (no gap/pop) | ⏳ | MAN-006 pending | Human |
| AU04 | Volume does not clip and is at comfortable level | ⏳ | MAN-006 pending | Human |
| AU05 | Audio does not cause performance stutter | ✅ | Sprint-002 verified | Agent |

## 5. Save / Persistence

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| SV01 | Save creates valid file on disk | ✅ | Sprint-008 | Agent |
| SV02 | Load restores all game state (battle/mgmt/base/locale) | ✅ | Integration tests | Agent |
| SV03 | Corrupted save handled gracefully (no crash) | ⏳ | 待测试 | Agent |
| SV04 | Multiple save slots functional | ✅ | SaveManager supports slots | Agent |
| SV05 | Save preview (slot summary) shows correct data | ✅ | Sprint-002 | Agent |

## 6. Performance

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| PF01 | Battle at 25×25 grid runs ≥30 FPS | ⏳ | 待 perf test | Agent |
| PF02 | Main menu idle <5% CPU | ⏳ | 待 perf test | Agent |
| PF03 | Memory usage stable over 1-hour play session | ⏳ | 待 soak test | Agent |
| PF04 | Asset loading does not cause frame spikes >100ms | ⏳ | 待 perf test | Agent |
| PF05 | Fog rendering on 25×25 grid ≤2ms | ⏳ | 待 perf test | Agent |

## 7. Release Packaging

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| RP01 | `.pck` or exported `.exe` includes all assets | ✅ | Sprint-008 verified | Agent |
| RP02 | Export does not include `.import` cache or editor-only files | ✅ | Godot export config | — |
| RP03 | Icon set correctly in project settings | ⏳ | 待配置 | Human |
| RP04 | App metadata (name/version/company) set | ⏳ | 待配置 | Human |
| RP05 | License/credits file bundled in release | ⏳ | 待配置 | Agent |

## 8. Store Readiness (Steam) — indie exempt unless shipping

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| ST01 | Store page created | 🚫 | indie exempt — not shipping yet | Human |
| ST02 | Capsule art (460×215, 231×87, 616×353, 374×448) | 🚫 | indie exempt | Human |
| ST03 | Screenshots (≥5) | 🚫 | indie exempt | Human |
| ST04 | Description (short + long) | 🚫 | indie exempt | Human |
| ST05 | Tags / genre / category set | 🚫 | indie exempt | Human |

## 9. Community — indie exempt unless active

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| CM01 | Patch notes ready for first public build | ⏳ | `changelog-player.md` exists | Agent |
| CM02 | Known issues list compiled | ⏳ | 待 bug tracking 激活 | Agent |
| CM03 | Feedback channel established | 🚫 | indie exempt | Human |

## 10. Legal — indie exempt unless publishing

| # | Check | Status | Evidence | Owner |
|---|-------|--------|----------|-------|
| LG01 | All third-party assets have verifiable licenses | ✅ | OFL fonts, CC-BY 3.0 BGM | Agent |
| LG02 | Credits include all required attributions | ✅ | Credits 已在主菜单 | Agent |
| LG03 | No copyrighted material in assets | ✅ | All free/open assets | Agent |
| LG04 | Privacy policy if collecting any data | 🚫 | No data collection | — |

---

## Summary

| Department | Pass | Pending | Exempt | Score |
|------------|------|---------|--------|-------|
| Code/Build | 6 | 2 | 0 | 75% |
| Content | 6 | 2 | 0 | 75% |
| UI/UX | 6 | 6 | 0 | 50% |
| Audio | 2 | 3 | 0 | 40% |
| Save/Persistence | 4 | 1 | 0 | 80% |
| Performance | 0 | 5 | 0 | 0% |
| Release Packaging | 2 | 3 | 0 | 40% |
| Store | 0 | 0 | 5 | N/A |
| Community | 1 | 2 | 1 | 33% |
| Legal | 3 | 0 | 1 | 100% |
| **Total** | **30** | **24** | **7** | **56%** |

**Release readiness**: 不推荐现在发布。需完成 PERF 测试、UI/UX 人工 sign-off、音频听感确认。
