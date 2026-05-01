# Launch Checklist — Draft

> **Version**: v0.1 (Draft)
> **Date**: 2026-05-01
> **Target**: PC / Steam
> **Status**: 初期草案 — 大部分项目需在 Polish 阶段验证

---

## 1. Build & Export

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1.1 | Windows .exe export succeeds | PASS | Sprint-008 verified, ~124MB |
| 1.2 | macOS export | NOT TESTED | 需 macOS 环境 |
| 1.3 | Linux export | NOT TESTED | 需 Linux 环境 |
| 1.4 | Export templates current (Godot 4.6.2) | PASS | |
| 1.5 | No export warnings/errors | PASS | |
| 1.6 | Build size within budget | TBD | 124MB, 后续美术/音频资产会显著增加 |

---

## 2. Performance

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | 60 FPS target in 25×25 grid battles | TBD | 需性能测试 |
| 2.2 | Fog overlay 性能预算 | NOT TESTED | Sprint-009 实现后验证 |
| 2.3 | Memory usage baseline | TBD | |
| 2.4 | No resource leaks on scene change | PASS | Sprint-005 BGM leak fixed |
| 2.5 | Load time < 5s | TBD | |

---

## 3. Save/Load

| # | Item | Status | Notes |
|---|------|--------|-------|
| 3.1 | Save slot create/load/delete | PASS | SaveManager 产品化 |
| 3.2 | Multi-slot support | PASS | |
| 3.3 | Save on battle checkpoint | TBD | Boss 检查点系统未实现 |
| 3.4 | Save data backward compat | TBD | 版本升级迁移未设计 |
| 3.5 | Corrupted save detection + recovery | NOT IMPLEMENTED | |

---

## 4. Content

| # | Item | Status | Notes |
|---|------|--------|-------|
| 4.1 | Tutorial/Ch.1 complete | PASS | |
| 4.2 | Ch.2 complete | PASS | |
| 4.3 | Ch.3 complete | PASS | |
| 4.4 | Ch.4+ | NOT STARTED | Alpha 优先级 |
| 4.5 | All boss battles playable | PARTIAL | Ch.1~3 bosses done; VS Boss 系统待 Sprint-009 |
| 4.6 | All skills functional | PASS | |
| 4.7 | All classes unlockable | PASS | |

---

## 5. UI/UX

| # | Item | Status | Notes |
|---|------|--------|-------|
| 5.1 | Keyboard navigation (all menus) | PASS | Control Manifest 要求 |
| 5.2 | Gamepad support (partial) | PARTIAL | 菜单导航可用，战斗待完善 |
| 5.3 | Font rendering correct (中/英) | PASS | ZCOOL XiaoWei + Noto Serif SC |
| 5.4 | Text scaling / accessibility | NOT TESTED | `design/ux/accessibility-requirements.md` 未验证 |
| 5.5 | Colorblind mode | NOT IMPLEMENTED | |
| 5.6 | All UI has visual feedback on interaction | PASS | GOLD focus stylebox |
| 5.7 | Credits screen | PASS | Sprint-005 |

---

## 6. Audio

| # | Item | Status | Notes |
|---|------|--------|-------|
| 6.1 | Main menu BGM | PASS | 1 track (CC-BY 3.0) |
| 6.2 | Battle BGM | PASS | 1 track (CC-BY 3.0) |
| 6.3 | SFX (attack, skill, death, menu) | NOT IMPLEMENTED | Alpha 优先级 |
| 6.4 | Boss-specific BGM | NOT IMPLEMENTED | |
| 6.5 | Volume control / mute | PARTIAL | |
| 6.6 | Audio doesn't overlap on scene switch | PASS | |

---

## 7. Localization

| # | Item | Status | Notes |
|---|------|--------|-------|
| 7.1 | Chinese (zh-CN) | PASS (native) | 源码中 hardcode |
| 7.2 | English (en-US) | PARTIAL | 切换框架就位，翻译不完整 |
| 7.3 | String extraction from source | NOT DONE | 字符串仍在 .gd 中 hardcode |
| 7.4 | Font supports all locales | PASS | Noto Serif SC covers Latin + CJK |

---

## 8. Store Page (Steam)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | Store description (CN) | NOT STARTED | |
| 8.2 | Store description (EN) | NOT STARTED | |
| 8.3 | Screenshots (min 5) | NOT STARTED | |
| 8.4 | Trailer | NOT STARTED | |
| 8.5 | Capsule art (header/library/icon) | NOT STARTED | |
| 8.6 | Tags / genre selection | NOT STARTED | |
| 8.7 | Age rating | NOT STARTED | |

---

## 9. Legal & Compliance

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Font licenses (OFL) | PASS | ZCOOL XiaoWei + Noto Serif SC |
| 9.2 | BGM licenses (CC-BY 3.0) | PASS | 2 tracks from archive.org |
| 9.3 | No unlicensed assets | TBD | 需最终审计 |
| 9.4 | Privacy policy (if applicable) | NOT STARTED | |
| 9.5 | EULA / Terms of Service | NOT STARTED | |

---

## 10. Release Day

| # | Item | Status | Notes |
|---|------|--------|-------|
| 10.1 | Build uploaded to Steam | NOT STARTED | |
| 10.2 | Steamworks settings configured | NOT STARTED | |
| 10.3 | Depot / branch setup | NOT STARTED | |
| 10.4 | Press kit ready | NOT STARTED | |
| 10.5 | Community hub configured | NOT STARTED | |
| 10.6 | Launch announcement prepared | NOT STARTED | |

---

## Summary

| Section | Ready | Not Ready |
|---------|-------|-----------|
| Build & Export | 4/6 | 2 |
| Performance | 1/5 | 4 |
| Save/Load | 3/5 | 2 |
| Content | 5/7 | 2 |
| UI/UX | 5/7 | 2 |
| Audio | 3/6 | 3 |
| Localization | 2/4 | 2 |
| Store Page | 0/7 | 7 |
| Legal | 2/5 | 3 |
| Release Day | 0/6 | 6 |
| **Total** | **25/58** | **33** |

**Readiness**: 43% — 大部分在 Polish/Release 阶段才需要的项目尚未开始。当前 Production 阶段基线健康。

---

## Next Actions

| Priority | Action | Phase |
|----------|--------|-------|
| P1 | 性能测试基础设施 | Polish 入口 |
| P1 | 安全审计（防作弊/存档篡改） | Polish |
| P2 | 字符串提取 + 翻译完善 | Polish |
| P2 | Steam 商店页素材准备 | Release |
| P2 | 法律/许可最终审计 | Release |
