# 角色管理

> **Status**: Designed (MVP runtime logic implemented)
> **Author**: user + agents
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 系统互锁——角色管理是编队和退场的基础

## Overview

角色管理系统负责玩家的角色编队和退场管理——它决定了"我带谁上场"和"谁退场休息"。

游戏允许玩家管理多名角色，战斗中最多上场4名角色。角色可以因剧情原因退场（故事退场式），也可以通过特定任务重新召回。这种设计让角色管理既有策略性（编队选择），又有叙事价值（退场角色的命运）。

## Player Fantasy

玩家在角色管理中的核心感受是**"我和我的队伍是一个整体"**——不是冷冰冰的数据，而是有故事、有情感的角色。

**编队的策略感**带来的是**决策的重量**。当玩家在4个上场名额中选择时，当玩家意识到"带了这个角色就意味着放弃另一个"时——这种**选择即放弃**的重量感是SRPG角色管理的核心情感。

**退场的叙事感**带来的是**故事的真实性**。当角色因剧情退场，当玩家看到角色的退场动画时——这种**角色的命运与故事绑定**的感觉让游戏超越了单纯的数值游戏。

**具体锚点：**
- "这个Boss需要更多输出，我应该带弓手而不是牧师" → 编队的策略感
- "这个角色退场了，但可以通过任务召回" → 退场的叙事感

## Detailed Design

### Core Rules

**C.1 编队规则**

| 参数 | 值 | 说明 |
|------|------|------|
| 最大上场人数 | 4人 | 每场战斗最多4人 |
| 队伍总人数 | 6-8人 | 可用角色总数 |

编队规则：
- 从可用角色中选择最多4人上场
- 未上场的角色保留在后备
- 可以随时在战斗外调整编队

**C.2 退场类型**

| 类型 | 触发方式 | 是否可召回 |
|------|---------|----------|
| 故事退场 | 剧情触发 | 可召回（通过任务） |
| 战败退场 | HP归零 | 自动恢复 |

**C.3 召回机制**

故事退场的角色可以通过完成召回任务重新加入队伍。

召回任务：
- 触发条件：完成特定剧情任务
- 消耗资源：无
- 召回后角色等级和装备保留

## Formulas

### F.1 编队合法性判断

```
can_deploy = (selected_count <= max_deployed) AND (all_selected_unique) AND (all_selected_status ∈ {AVAILABLE, DEPLOYED}) AND (battle_active = false)
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| selected_count | N_sel | int | 0~6 | 当前选择的上场人数 |
| max_deployed | N_max | int | 4 | 每场战斗最多部署人数 |
| all_selected_unique | U | bool | {true,false} | 选择列表中无重复角色 |
| all_selected_status | S | enum[] | AVAILABLE / DEPLOYED / DEPARTED / DEFEATED | 候选角色当前 roster 状态 |
| battle_active | B | bool | {true,false} | 当前是否处于战斗中 |

**输出**：`true` 时允许提交新编队；否则拒绝。

### F.2 角色状态迁移

```
AVAILABLE --set_party--> DEPLOYED
DEPLOYED --removed_from_party--> AVAILABLE
AVAILABLE --story_departure--> DEPARTED
DEPLOYED --defeat_in_battle--> DEFEATED
DEFEATED --battle_end--> DEPLOYED or AVAILABLE
DEPARTED --recall--> AVAILABLE
```

说明：
- `DEFEATED` 是战斗内临时状态，不会覆盖故事退场。
- 战斗结束后，若角色仍在当前 party 列表中，则回到 `DEPLOYED`；否则回到 `AVAILABLE`。

### F.3 存档负载组成

```
roster_payload = Σ character_entry(unit_data, status, party_index, departure_meta)
```

每个 `character_entry` 至少包含：
- `unit`：完整 `Unit.serialize()` 数据（属性、职业、技能、装备）
- `status`：AVAILABLE / DEPLOYED / DEPARTED / DEFEATED
- `party_index`：若在当前编队中则为 `0..3`，否则为 `-1`
- `departure_type` / `departure_reason`：仅在退场相关状态下记录

**输出**：保存到 `SaveData.party_units`，用于完整恢复 roster 和编队顺序。

## Edge Cases

- **If 玩家选择 5 名角色上场**：拒绝提交，保持原编队不变。原因是 `max_deployed = 4`。
- **If 选择列表中出现重复角色**：拒绝提交。重复角色不能同时占用多个编队位置。
- **If 战斗进行中尝试修改编队**：拒绝提交。战斗外才能调整编队，避免状态机冲突。
- **If 已上场角色收到故事退场事件**：在 MVP 运行时逻辑中阻止立即退场，待战斗结束后再处理，避免战斗中途把活跃单位从战场和 roster 同时剥离。
- **If 角色战败（HP=0）**：标记为 `DEFEATED`；战斗结束时自动恢复到 `DEPLOYED` 或 `AVAILABLE`。
- **If 角色已故事退场且未满足召回条件**：保持 `DEPARTED`，不可重新编队。
- **If 角色被召回**：恢复为 `AVAILABLE`，原有等级、技能和装备不丢失。
- **If 读档时某角色在当前 battle scene 中不存在**：从 `party_units` 负载新建该角色实例并恢复其状态；这允许 reserve/departed 角色不依赖当前战斗场景存在。

## Dependencies

### Upstream Dependencies

| System | Dependency Type | Interface Contract |
|--------|---------------|-------------------|
| **属性与成长系统** | 硬依赖 | 角色管理使用属性数据；退场条件基于HP=0 |
| **回合制模式** | 硬依赖 | 回合制模式调用角色管理进行编队控制 |

## Tuning Knobs

| Knob | Default | Safe Range | Affected Gameplay | Notes |
|------|---------|-----------|------------------|-------|
| **最大编队人数** | 4 | 3~5 | 每场战斗的策略密度 | MVP 固定为 4 |
| **MVP roster 上限** | 6 | 6~8 | 预备角色的轮换空间 | 当前实现固定 6 |
| **故事退场默认可召回性** | true | true / false | 叙事不可逆程度 | MVP 默认可召回 |
| **战败退场恢复时机** | battle_end | turn_end / battle_end | 惩罚强度 | 当前实现为 battle_end |

## Visual/Audio Requirements

MVP 逻辑层不要求专属动画系统，但需要至少满足以下信息表达：

- 编队中角色与后备角色必须能被区分
- 已退场角色必须能被区分
- 当前角色的已装备武器/关键装备应可在角色信息中查看

音频不是当前优先项。若后续进入 presentation 迭代，可增加：
- 编队确认音效
- 角色退场提示音效
- 角色召回确认音效

## UI Requirements

当前最小 UI 合约：

- **Character Tab**
  - 显示当前聚焦角色的名称、HP、MP、主属性、职业
  - 显示当前 party 顺序
  - 显示 reserve 与 departed 数量
  - 显示角色已装备条目摘要
- **Party Management Surface**
  - 战斗外可调整 party
  - 战斗内只读，不允许提交新编队
- **Save/Load**
  - 读档后 party 顺序、reserve/departed 状态、角色装备摘要保持一致

当前 battle runtime 的文字型 menu surface 已满足 MVP 级别的信息暴露，但尚未有专门的编队编辑界面。

## Acceptance Criteria

### AC.1 编队系统

- [ ] **AC.1.1** 玩家可以从可用角色中选择最多4人上场
- [ ] **AC.1.2** 未上场的角色保留在后备
- [ ] **AC.1.3** 编队可以在战斗外随时调整

### AC.2 退场与召回

- [ ] **AC.2.1** 故事退场会把角色从可部署 roster 中移除，并保留角色数据
- [ ] **AC.2.2** 战败退场在战斗结束后自动恢复
- [ ] **AC.2.3** 被召回角色恢复时保留属性、职业、技能和装备

### AC.3 存档集成

- [ ] **AC.3.1** `party_units` 保存完整 roster（含 reserve / departed）
- [ ] **AC.3.2** 当前 party 顺序可跨会话恢复
- [ ] **AC.3.3** reserve / departed 角色即使不在当前战斗场景中，也能通过读档恢复

## Open Questions

### OQ.1 最大队伍人数

**问题**: 玩家最多可以拥有多少可用水浒/角色？
- 当前设计：6-8人
- 备选方案：固定6人

**当前结论**: MVP 阶段固定 6 人；若后续进入 Alpha，可再放宽到 8 人。
