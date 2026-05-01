# 项目阶段分析 — 2026-05-01

> **阶段**: Production
> **置信度**: PASS WITH CONCERNS
> **更新原因**: Sprint-005~008 完成 + Sprint-009 PLANNING + 治理缺口补全

---

## Completeness Overview

| 类别 | 完成度 | 详情 |
|------|--------|------|
| Design | 95% | 24/24 系统 Designed, 1 次 cross-review done; 仅 hp-system 有独立 design-review |
| Architecture | 90% | 13 ADRs (ADR-001~013), 3 architecture reviews, control-manifest + traceability 完整 |
| Code | 89% | 46+ 源文件, 18 epic 完成; Ch.1~3 完整可玩路径已验收 |
| Tests | 91% | 93 测试文件, 879 个 test_ 函数; GUT `879 | Pass: 879 | Fail: 0` |
| Production | 82% | Sprint-001~008 全部 COMPLETE, Sprint-009 PLANNING; governance gap fill 2026-05-01 |
| UX | 88% | 8 UX specs, visual readability PASS WITH NOTES; 真人 release sign-off 待完成 |

---

## Sprint-005~008 更新摘要

| Sprint | 系统 | 关键交付 |
|--------|------|---------|
| Sprint-005 | Localization / Credits / Governance | srpg_localization.gd, 语言切换, Credits overlay, ADR-008/009 |
| Sprint-006 | Bond MVP / Equipment Enhancement / Base Phase 1 | BondRegistry, equipment enhancement UI/cost/round-trip, Base AP + Intel, Ch.3 GDD |
| Sprint-007 | Ch.3 Battle 1 / Base Tavern+Upgrade / Equipment Risk Zone | Ch.3 boot, Tavern affinity, +6~+10 risk, architecture full review |
| Sprint-008 | Ch.3 Battle 2/B3-GATE/Finale / Equipment Decomp/Reroll | Ch.3 playable path complete, Bond combo GDD, Fog GDD, 879/879 PASS |

---

## 最新 ADR 状态（as of 2026-05-01）

| ADR | Title | Status | Layer |
|-----|-------|--------|-------|
| ADR-001 | Event Architecture | Accepted | Foundation |
| ADR-002 | Scene Management | Accepted | Foundation |
| ADR-003 | Save System | Accepted | Foundation |
| ADR-004 | Combat System | Accepted | Core |
| ADR-005 | AI Behavior | Accepted | Core |
| ADR-006 | Attribute Data Model | Accepted | Core |
| ADR-007 | Belief Branch System | Accepted | Content |
| ADR-008 | Resource Economy Upgrade Scope | Accepted | Core |
| ADR-009 | Equipment Upgrade Scope | Accepted | Feature |
| ADR-010 | Fog-of-War Architecture | Accepted | Feature |
| ADR-011 | Bond Combo Skill Architecture | Accepted | Feature |
| ADR-012 | Difficulty System Architecture | Accepted | Meta |
| ADR-013 | Boss System Architecture | Accepted | Feature |

---

## 当前 Epic 覆盖（as of 2026-05-01）

| Epic | GDD | Stories | Status |
|------|-----|---------|--------|
| attribute-system | ✓ | 7 | Complete |
| class-system | ✓ | 6 | Complete |
| resource-economy | ✓ | 7 | Complete |
| tactical-mechanism | ✓ | 5 | Complete |
| ai-system | ✓ | 6 | Complete |
| skill-system | ✓ | 7 | Complete |
| turn-based-mode | ✓ | 7 | Complete |
| equipment-system | ✓ | 13 | Complete |
| character-management | ✓ | 3 | Complete |
| battle-settlement | ✓ | 5 | Complete |
| camera-map-system | ✓ | 3 | Complete |
| ui-system | ✓ | 3 | Complete |
| chapter-02 | ✓ | 6 | Complete |
| chapter-03 | ✓ | 4 | Complete |
| localization | ✓ | 3 | Complete |
| bond-system | ✓ | 6 | 4 Complete + 2 Sprint-009 pending |
| base-system | ✓ | 4 | Complete |
| fog-of-war | ✓ | 4 | Sprint-009 pending |
| difficulty-system | ✓ | 2 | Sprint-009 pending |
| boss-system | ✓ | 2 | Sprint-009 pending |

---

## 差距（2026-05-01 更新）

| # | 差距 | 严重度 | 阻塞 gate? |
|---|------|--------|------------|
| 1 | UX Review 未执行 | Low | No |
| 2 | `design/levels/`, `design/balance/` 空 | Info | No |
| 3 | 无 sprint retrospective（8 sprints done） | Medium | No |
| 4 | 人工视觉签收 | Medium | No |
| 5 | 无 formal changelog / launch-checklist | Low | No |
| 6 | 4 个 Alpha 优先级 epic 未创建（event/new-game-plus/chapter-04/hp-system） | Low | No |

---

## Production 起点

| Lane | 目标 | Gate |
|------|------|------|
| Playable build | Windows exe 可试玩包 | Full packaged playthrough PASS |
| Ch.1~3 内容 | 3 章 9+ 战完整可玩 | Sprint-008 验收通过 |
| Vertical Slice 系统 | fog / bond-combo / difficulty / boss | Sprint-009 PLANNING |
| UI/UX polish | 降低简陋感 | 人工截图/试玩确认 |
| Systems productization | 18 epic 完成 | Sprint-008 结束基线 |

---

## 建议路径

1. **Sprint-009 启动前**: P0 治理补全（ADR-010~013 + epic 创建 + QA plan）— DONE 2026-05-01
2. **Sprint-009**: 实现 4 个 Vertical Slice 系统 + 补齐测试
3. **Sprint-009 后**: retrospective batch + changelog + milestone review + gate-check
