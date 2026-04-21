# Architecture Traceability Matrix

> 版本: v0.1 | 日期: 2026-04-20

本文档追踪架构决策与GDD需求的对齐关系。

---

## Foundation Layer Traceability

| Architecture Component | ADR | GDD Requirements | Coverage |
|---------------------|-----|------------------|----------|
| Event Bus | ADR-001 | 所有GDD系统的解耦通信需求 | ✅ Complete |
| Scene Management | ADR-002 | camera-map-system.md (场景切换), ui-system.md (UI层分离) | ✅ Complete |
| Save System | ADR-003 | 所有GDD系统的持久化需求 | ✅ Complete |

---

## Core Systems Traceability

| GDD System | Architecture Components | Coverage |
|------------|------------------------|----------|
| attribute-growth-system.md | AttributeSystem (Foundation) | ✅ Defined |
| class-system.md | ClassSystem (Gameplay) | ✅ Defined |
| skill-system.md | SkillSystem (Gameplay) | ✅ Defined |
| equipment-system.md | EquipmentSystem (Gameplay) | ✅ Defined |
| tactical-mechanism.md | CombatSystem (Gameplay) | ✅ Defined |
| turn-based-mode.md | CombatSystem.turn_manager | ✅ Defined |
| battle-settlement.md | CombatSystem + SaveSystem | ✅ Defined |
| ai-system.md | AISystem (Gameplay) | ✅ Defined |
| resource-economy.md | ResourceManager (Foundation) | ✅ Defined |
| bond-system (in character-management.md) | BondSystem (Gameplay) | ✅ Defined |
| camera-map-system.md | SceneManager + Camera3D | ✅ Defined |
| ui-system.md | UIRoot (Presentation) | ✅ Defined |
| character-management.md | UnitManager + SaveSystem | ✅ Defined |

---

## Requirements Not Covered

| Requirement | Status | Notes |
|------------|--------|-------|
| 网络多人模式 | ⬜ Future | 多人模式架构未设计 |
| DLC内容架构 | ⬜ Future | DLC架构未设计 |
| Mod支持 | ⬜ Future | Mod API未设计 |

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
```

---

## Validation Checklist

- [x] 所有Foundation层ADR有GDD需求追踪
- [x] 所有MVP GDD系统有架构组件映射
- [ ] 所有架构组件有实现验证计划
- [x] 无循环依赖（已验证ADR-001→002→003无环）
- [ ] 所有开放问题有跟踪
