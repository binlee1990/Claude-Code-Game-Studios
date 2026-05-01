# Architecture Traceability Matrix

> 版本: v1.0 | 日期: 2026-05-01

本文档追踪架构决策与GDD需求的对齐关系。

---

## Foundation Layer Traceability

| Architecture Component | ADR | GDD Requirements | Coverage |
|---------------------|-----|------------------|----------|
| Event Bus | ADR-001 | 所有GDD系统的解耦通信需求 | Complete |
| Scene Management | ADR-002 | camera-map-system.md (场景切换), ui-system.md (UI层分离) | Complete |
| Save System | ADR-003 | 所有GDD系统的持久化需求 | Complete |

---

## Core Systems Traceability

| GDD System | ADR(s) | Status |
|------------|--------|--------|
| attribute-growth-system.md | ADR-006 | Complete |
| class-system.md | ADR-001 | Complete |
| skill-system.md | ADR-001 | Complete |
| equipment-system.md | ADR-001, ADR-009 | Complete |
| tactical-mechanism.md | ADR-001, ADR-004 | Complete |
| turn-based-mode.md | ADR-001, ADR-004 | Complete |
| battle-settlement.md | ADR-001, ADR-004 | Complete |
| ai-system.md | ADR-005 | Complete |
| resource-economy.md | ADR-001, ADR-008 | Complete |
| hp-system.md | ADR-006 (partial) | Needs dedicated ADR |

---

## Feature/Meta Systems Traceability

| GDD System | ADR(s) | Status |
|------------|--------|--------|
| character-management.md | ADR-001, ADR-003 | Complete |
| bond-system.md | ADR-001, ADR-003, ADR-011 | Complete |
| fog-of-war-system.md | ADR-003, ADR-004, ADR-010 | Complete |
| difficulty-system.md | ADR-004, ADR-005, ADR-012 | Complete |
| boss-system.md | ADR-003, ADR-004, ADR-005, ADR-012, ADR-013 | Complete |
| base-system.md | ADR-003, ADR-008 | Complete |
| camera-map-system.md | ADR-002 | Complete |
| ui-system.md | ADR-001, ADR-002 | Complete |

---

## Unaddressed Systems (No ADR)

| GDD System | Priority | Notes |
|------------|----------|-------|
| event-system.md | Alpha | 事件系统依赖 ADR-001 (Event Bus)，但自身无独立 ADR |
| new-game-plus-system.md | Alpha | 多周目点数和难度倍率选择需 ADR |
| audio-system.md | Alpha | 音频架构（FMOD/内置/第三方）未决策 |
| localization-system.md | MVP (Complete) | 实现完成但无架构决策记录 |
| art-style.md | Foundation | 美术方向已通过 art-bible 覆盖，不需独立 ADR |
| worldbuilding-narrative.md | Foundation | 非技术架构范畴 |

---

## ADR Dependencies

```
ADR-001 (Event Bus)
    ├── Enables: ADR-002 (Scene Management)
    ├── Enables: ADR-003 (Save System)
    └── Enables: 所有Gameplay层系统

ADR-002 (Scene Management)
    └── Depends On: ADR-001

ADR-003 (Save System)
    └── Depends On: ADR-001, ADR-002

ADR-004 (Combat System)
    └── Depends On: ADR-001

ADR-005 (AI Behavior)
    └── Depends On: ADR-001, ADR-004

ADR-006 (Attribute Data Model)
    └── Depends On: ADR-001

ADR-007 (Belief Branch System)
    └── Depends On: ADR-001, ADR-003

ADR-008 (Resource Economy)
    └── Depends On: ADR-001, ADR-003

ADR-009 (Equipment Upgrade Scope)
    └── Depends On: ADR-008, ADR-003, ADR-001

ADR-010 (Fog-of-War)
    └── Depends On: ADR-004, ADR-003, ADR-005
	
ADR-011 (Bond Combo Skill)
    └── Depends On: ADR-004, ADR-003, ADR-001, ADR-006
	
ADR-012 (Difficulty System)
    └── Depends On: ADR-004, ADR-005, ADR-008
	
ADR-013 (Boss System)
    └── Depends On: ADR-012, ADR-005, ADR-004, ADR-003
```

---

## Validation Checklist

- [x] 所有Foundation层ADR有GDD需求追踪
- [x] MVP GDD系统全部有架构组件映射
- [x] Vertical Slice 系统 (fog/bond-combo/difficulty/boss) 全部有 ADR 覆盖
- [x] Sprint-009 新 TR (fog/bond/diff/boss) 全部注册到 tr-registry.yaml
- [ ] 4 个 Alpha 系统 (event/ng+/audio/localization) 待 ADR
- [ ] 所有开放问题有跟踪（ADR OQ 仍分散在各 ADR/GDD 中）
