# Systems Index: SRPG

> **Status**: Draft
> **Created**: 2026-04-16
> **Last Updated**: 2026-04-22
> **Source Concept**: design/gdd/SRPG 核心模块设计总纲.md

---

## Overview

一款以架空中国历史为背景的深度养成 SRPG，核心玩法围绕回合制战术战斗 + 属性驱动的角色养成。玩家通过属性分配、职业选择、技能升级、装备强化、羁绊培养等系统构建独特的角色 Build，在多阶段 Boss 战中验证养成成果，并通过信念值驱动的三路线叙事影响故事走向。游戏以多周目成就点数系统提供重复游玩价值。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 美术风格 | Foundation | Foundation | Designed | design/gdd/art-style.md | — |
| 2 | 存档系统 | Foundation | Foundation | Designed | design/gdd/save-system.md | — |
| 3 | 世界观/叙事 | Narrative | Foundation | Designed | design/gdd/worldbuilding-narrative.md | — |
| 4 | 属性与成长系统 | Core | MVP | Designed | design/gdd/attribute-growth-system.md | — |
| 5 | 职业系统 | Core | MVP | Designed | design/gdd/class-system.md | 属性与成长系统 |
| 6 | AI系统 | Core | MVP | Designed | design/gdd/ai-system.md | 属性与成长系统、战术机制 |
| 7 | 资源经济 | Core | MVP | Designed | design/gdd/resource-economy.md | 属性与成长系统 |
| 8 | 战术机制 | Core | MVP | Designed | design/gdd/tactical-mechanism.md | 属性与成长系统 |
| 9 | 技能系统 | Core | MVP | Designed | design/gdd/skill-system.md | 属性与成长系统、职业系统 |
| 10 | 装备系统 | Feature | MVP | Designed | design/gdd/equipment-system.md | 属性与成长系统、资源经济 |
| 11 | 回合制模式 | Core | MVP | Designed | design/gdd/turn-based-mode.md | AI系统、战术机制 |
| 12 | 羁绊系统 | Feature | Vertical Slice | Designed | design/gdd/bond-system.md | 属性与成长系统、战斗结算 |
| 13 | 角色管理 | Feature | MVP | Designed | design/gdd/character-management.md | 属性与成长系统、回合制模式 |
| 14 | 战斗结算 | Feature | MVP | Designed | design/gdd/battle-settlement.md | 回合制模式、资源经济 |
| 15 | 难度系统 | Meta | Vertical Slice | Designed | design/gdd/difficulty-system.md | 战斗结算 |
| 16 | Boss战 | Feature | Vertical Slice | Designed | design/gdd/boss-system.md | AI系统、战斗结算、难度系统 |
| 17 | 战争迷雾 | Feature | Vertical Slice | Designed | design/gdd/fog-of-war-system.md | AI系统、战术机制 |
| 18 | 视角与地图 | Presentation | MVP | Designed | design/gdd/camera-map-system.md | 美术风格 |
| 19 | 基地系统 | Feature | Alpha | Designed | design/gdd/base-system.md | 资源经济、装备系统 |
| 20 | UI系统 | Presentation | MVP | Designed | design/gdd/ui-system.md | 所有核心系统 |
| 21 | 多周目系统 | Meta | Alpha | Designed | design/gdd/new-game-plus-system.md | 战斗结算、角色管理 |
| 22 | 事件系统 | Narrative | Alpha | Designed | design/gdd/event-system.md | 世界观/叙事、角色管理 |
| 23 | 音效/音乐 | Presentation | Alpha | Designed | design/gdd/audio-system.md | 回合制模式、Boss战 |

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **Foundation** | 游戏运行的基础系统 | 美术风格、存档系统、世界观/叙事 |
| **Core** | 核心玩法系统，其他所有系统依赖于此 | 属性与成长、职业、AI、资源经济、战术机制、技能、回合制 |
| **Feature** | 核心玩法之上的功能系统 | 装备、羁绊、战斗结算、角色管理、Boss战、战争迷雾、基地 |
| **Presentation** | 面向玩家的呈现层 | 视角地图、UI、音效音乐 |
| **Narrative** | 叙事相关系统 | 世界观/叙事、事件系统 |
| **Meta** | 游戏循环之外的元系统 | 难度系统、多周目系统 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | 核心循环可运行的最低系统集 | 首个可玩版本 | Design FIRST |
| **Vertical Slice** | 一个完整、精细的演示区域所需的系统 | 垂直切片/演示 | Design SECOND |
| **Alpha** | 所有功能以粗糙形式存在 | Alpha 里程碑 | Design THIRD |
| **Foundation** | 不属于功能系统但支撑一切 | 所有阶段 | 随时可做 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **美术风格** — 视觉基调，定义游戏的整体美术方向（HD-2D 中国风）
2. **存档系统** — 所有玩家进度的持久化基础
3. **世界观/叙事** — 叙事框架和故事结构定义

### Core Layer (depends on foundation)

1. **属性与成长系统** — 依赖：美术风格、存档系统；所有养成系统的基础
2. **职业系统** — 依赖：属性与成长系统；职业解锁依赖属性门槛
3. **资源经济** — 依赖：属性与成长系统；双层资源是养成决策的燃料
4. **战术机制** — 依赖：属性与成长系统；克制三角+元素交互+高低差

### Feature Layer (depends on core)

1. **AI系统** — 依赖：属性与成长系统、战术机制；敌人行为是战斗体验的一半
2. **技能系统** — 依赖：属性与成长系统、职业系统；技能是玩家表现的直接体现
3. **装备系统** — 依赖：属性与成长系统、资源经济；装备驱动核心循环
4. **回合制模式** — 依赖：AI系统、战术机制；核心玩法本身
5. **角色管理** — 依赖：属性与成长系统、回合制模式；编队和退场管理
6. **战斗结算** — 依赖：回合制模式、资源经济；战斗的奖励闭环

### Presentation Layer (depends on features)

1. **视角与地图** — 依赖：美术风格；游戏世界的视觉呈现
2. **UI系统** — 依赖：所有核心系统；玩家与所有系统交互的界面
3. **音效/音乐** — 依赖：回合制模式、Boss战；沉浸感的重要组成

### Meta Layer (depends on everything)

1. **难度系统** — 依赖：战斗结算；多周目难度倍率
2. **Boss战** — 依赖：AI系统、战斗结算、难度系统；阶段性验证玩家养成成果
3. **战争迷雾** — 依赖：AI系统、战术机制；特定关卡类型的战术深度
4. **基地系统** — 依赖：资源经济、装备系统；玩家离线养成基地
5. **羁绊系统** — 依赖：属性与成长系统、战斗结算；情感+策略双重投入
6. **多周目系统** — 依赖：战斗结算、角色管理；成就点数兑换新周目开关
7. **事件系统** — 依赖：世界观/叙事、角色管理；叙事驱动的事件触发

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | 属性与成长系统 | MVP | Core | game-designer, systems-designer | M |
| 2 | 职业系统 | MVP | Core | game-designer, systems-designer | M |
| 3 | 资源经济 | MVP | Core | game-designer, economy-designer | M |
| 4 | 战术机制 | MVP | Core | game-designer, systems-designer | M |
| 5 | AI系统 | MVP | Core | game-designer, ai-programmer | L |
| 6 | 技能系统 | MVP | Core | game-designer, systems-designer | L |
| 7 | 装备系统 | MVP | Feature | game-designer, systems-designer | L |
| 8 | 回合制模式 | MVP | Core | game-designer, gameplay-programmer | L |
| 9 | 角色管理 | MVP | Feature | game-designer, systems-designer | M |
| 10 | 战斗结算 | MVP | Feature | game-designer, systems-designer | S |
| 11 | 视角与地图 | MVP | Presentation | level-designer, technical-artist | M |
| 12 | UI系统 | MVP | Presentation | game-designer, ui-programmer | L |
| 13 | Boss战 | Vertical Slice | Meta | game-designer, systems-designer | L |
| 14 | 羁绊系统 | Vertical Slice | Feature | game-designer, narrative-director | L |
| 15 | 难度系统 | Vertical Slice | Meta | game-designer, systems-designer | S |
| 16 | 战争迷雾 | Vertical Slice | Feature | game-designer, systems-designer | S |
| 17 | 基地系统 | Alpha | Feature | game-designer, systems-designer | L |
| 18 | 事件系统 | Alpha | Narrative | narrative-director, game-designer | M |
| 19 | 多周目系统 | Alpha | Meta | game-designer, systems-designer | M |
| 20 | 音效/音乐 | Alpha | Presentation | audio-director, sound-designer | M |

**Effort estimates**: S = 1 session, M = 2-3 sessions, L = 4+ sessions

---

## Circular Dependencies

- **无循环依赖**

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| AI系统 | Technical | 回合制 AI 决策复杂度高，需要在原型阶段验证 | `/prototype` AI 行为模式优先 |
| 羁绊系统 | Design | 羁绊与战斗交互的涌现效应难以提前预判 | 设计阶段明确边界，原型验证核心循环 |
| 属性与成长系统 | Scope | 属性系统复杂度高（果子/壁障/潜质），需要大量调参 | 优先设计 MVP 版本，扩展机制后续迭代 |
| 回合制模式 | Technical | 速度序列制 + 自动/加速模式需要可靠的实现 | 原型阶段验证核心循环 |
| 多周目系统 | Design | 成就点数兑换逻辑与所有系统耦合 | 放在 Alpha 阶段设计，避免影响核心循环 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 23 |
| Design docs started | 1 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 12/12 |
| Vertical Slice systems designed | 0/4 |
| Alpha systems designed | 0/4 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the highest-risk system early (`/prototype [system]`)
- [ ] `/map-systems next` — pick the highest-priority undesigned system automatically
