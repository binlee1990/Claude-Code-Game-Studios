# Epics Index

Last Updated: 2026-05-01
Engine: Godot 4.6.2

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| attribute-system | Core | 属性与成长 | attribute-growth-system.md | 7 stories (6 Logic, 1 Integration) | Complete |
| class-system | Core | 职业系统 | class-system.md | 6 stories (5 Logic, 1 Integration) | Complete |
| resource-economy | Core | 资源经济 | resource-economy.md | 7 stories | Complete |
| tactical-mechanism | Core | 战术机制 | tactical-mechanism.md | 5 stories (4 Logic, 1 Integration) | Complete |
| ai-system | Core | AI系统 | ai-system.md | 6 stories (5 Logic, 1 Integration) | Complete |
| skill-system | Core | 技能系统 | skill-system.md | 7 stories (6 Logic, 1 Integration) | Complete |
| turn-based-mode | Core | 回合制模式 | turn-based-mode.md | 7 stories (6 Logic, 1 Integration) | Complete |
| equipment-system | Feature | 装备系统 | equipment-system.md | 13 stories | Complete / Sprint-008 UI Complete |
| character-management | Feature | 角色管理 | character-management.md | 3 stories (2 Logic, 1 Integration) | Complete |
| battle-settlement | Feature | 战斗结算 | battle-settlement.md | 5 stories (4 Logic, 1 Integration) | Complete |
| camera-map-system | Presentation | 视角与地图 | camera-map-system.md | 3 stories (2 Visual/Feel, 1 Integration) | Complete |
| ui-system | Presentation | UI系统 | ui-system.md | 3 stories (2 UI, 1 Integration) | Complete |
| chapter-02 | Content | Ch.2 内容 | chapter-02.md | 6 stories (Logic) | Complete / Ready for Playtest |
| chapter-03 | Content | Ch.3 内容 | chapter-03.md | 4 stories | Complete / Sprint-008 Playable Path Complete |
| localization | Foundation | 多语言管理 | localization-system.md | 3 stories (1 Integration, 1 UI, 1 Integration) | Complete |
| bond-system | Feature | 羁绊系统 MVP | bond-system.md | 4 stories + 1 GDD（Sprint-008）| Sprint-008 Combo GDD Complete |
| base-system | Feature | 基地系统 Phase 1 | base-system.md | 4 stories | Complete |
| fog-of-war | Feature | 战争迷雾 MVP | fog-of-war-system.md | 4 stories | Sprint-009 Must Have |
| difficulty-system | Meta | 难度系统 | difficulty-system.md | 2 stories | Sprint-009 Must Have |
| boss-system | Feature | Boss战系统 | boss-system.md | 2 stories | Sprint-009 Must Have |

## Summary

- **Core**: 7 epics (attribute, class, resource, tactical, AI, skill, turn-based)
- **Feature**: 7 epics (equipment, character, battle-settlement, bond-system, base-system, fog-of-war, boss-system)
- **Presentation**: 2 epics (camera-map, UI)
- **Foundation**: 1 epic (localization)
- **Meta**: 1 epic (difficulty-system)
- **Content**: 2 epics (chapter-02, chapter-03)

## Known Gaps

- Sprint-004 `BASE-004` human Ch.2 playtest remains backlog; non-human scope is complete.
- Sprint-004 screenshot/sign-off evidence remains human-only and is not a Sprint-005 blocker.
- Sprint-006 is complete: Bond runtime MVP, equipped-item enhancement UI/cost/round-trip, Base AP + Intel, economy cost config, Ch.3 GDD, and packaged smoke coverage are implemented and verified.
- Sprint-007 is complete: Ch.3 battle 1 boots/victories, Base Tavern/Upgrade, Tavern affinity, Equipment +6~+10 risk zone, architecture full review, export, and packaged smoke are verified.
- Sprint-008 is complete: Ch.3 battle 2, B3-GATE runtime activation, Ch.3 finale boss, equipment decomp/reroll UI, architecture.md fixups, Bond combo GDD, Fog GDD, GUT, export, and packaged smoke are verified.
- Sprint-009 (COMPLETE 2026-05-02): Fog-of-war MVP, Bond combo skill, Difficulty data model + integration, Boss data model + action pattern. 12/12 stories done, 1021/1021 PASS.
- Sprint-010 (COMPLETE 2026-05-02): 治理收口 + 里程碑审查 — retrospective batch / gate re-check / changelog / regression suite / test helpers / launch checklist / design review batch / perf baseline / retro template. 12/12 stories done.
- Remaining gap: event-system, new-game-plus, hp-system, chapter-04 Alpha epics not yet created.
