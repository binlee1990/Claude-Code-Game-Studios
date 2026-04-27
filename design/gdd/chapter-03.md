# Chapter 3 关卡设计文档

> 版本: v1.0 | 日期: 2026-04-27 | 状态: Sprint-006 Full GDD / Ready for Sprint-007 implementation
> 文件路径: design/gdd/chapter-03.md
> Sprint: 006 / CH3-DESIGN-001

---

## 1. Overview

第三章承接 Ch.2 的 B2-GATE 结果，以“边境救援后的第一场政治压力”为主题。玩家已经经历 Ch.1 三战闭环、Ch.2 信念分叉和基地整备，本章的目标不是立即 hard lock 三条路线，而是让玩家第一次看见“仁 / 义 / 智”倾向正在改变战场目标、NPC 态度和战后情报。

章节结构保持三战制：

| 战斗编号 | 战斗 ID | 类型 | 核心机制 | 信念节点 |
|---|---|---|---|---|
| Ch.3-1 | `chapter_03_act_a` | 救援 + 防守突破 | 基地整备成果检查、Bond/装备强化软提示 | B3-N1 |
| Ch.3-2 | `chapter_03_act_b` | 分队推进 | 行为结果累积、NPC 站位受 B3-N1 影响 | B3-N2 |
| Ch.3 Gate | `chapter_03_act_b` 结算后 | branch_gate / soft_lock | 首次路线 soft-lock 候选判断 | B3-GATE |
| Ch.3-3 | `chapter_03_finale` | 首领压制 | 章节终结选择，预告 Ch.4 hard lock | B3-N3 |

Sprint-006 只交付本 GDD，不实现 Ch.3 runtime。

---

## 2. Player Fantasy

- 玩家从基地情报室读到下一战态势，带着行动点训练、装备强化和早期 Bond 关系进入战场。
- 玩家感到 Ch.2 的立场不是文本结算，而是会改变 NPC 是否信任、敌人是否急进、目标是否偏向救援或歼灭。
- 玩家开始理解 B3-GATE 是 Ch.4 hard lock 的预告：仍可调整，但已经有明显路线惯性。

---

## 3. Detailed Rules

### 3.1 Ch.3-1 `chapter_03_act_a`

**标题**：破营前夜
**地图**：18x18 山口营地，西南为我方出入口，中央为难民围栏，东北为敌方军帐。
**胜利条件**：8 回合内击败敌方队长，或救出 3 名平民并撤至西南安全区。
**失败条件**：我方全灭；平民阵亡超过 2；第 10 回合敌方援军封路。

**地图布局**

| 区域 | 坐标范围 | 地形 | 设计意图 |
|---|---|---|---|
| 西南坡道 | x1-5, y11-16 | grass + highland | 我方出生点，有高低差优势但推进慢 |
| 中央围栏 | x7-12, y7-12 | obstacle + mud | 平民区域，阻挡直线攻击，鼓励绕行 |
| 东北军帐 | x13-17, y2-6 | normal + obstacle | 敌方队长与弓手阵地 |
| 北侧溪沟 | x4-10, y2-5 | water_puddle | 雷/水元素与移动惩罚测试点 |

**敌方编队**

| 单位 ID | 名称 | 职业 | 武器/元素 | AI | 起始位置 | 备注 |
|---|---|---|---|---|---|---|
| E1 | Camp Captain | basic_knight | spear / earth | aggressive | (15,4) | Ch.3-1 队长，半血后守位 |
| E2 | Bow Sentry | basic_archer | bow / wind | support | (13,3) | 优先攻击接近平民的单位 |
| E3 | Torch Adept | basic_mage | magic / fire | control | (10,6) | 对围栏区域施压 |
| E4 | Axe Linebreaker | basic_warrior | axe / none | aggressive | (12,10) | 阻断救援路线 |
| E5 | Spear Guard | basic_knight | spear / none | balanced | (8,9) | 中央守卫 |

**NPC / 目标单位**

| 单位 ID | 名称 | 队伍 | 行为 |
|---|---|---|---|
| C1-C3 | Camp Civilian | neutral | 不攻击，受到威胁时向西南移动 |
| NPC1 | Local Guide | player_ally | 若 B2 倾向 `ren`，开局加入；否则第 3 回合出现 |

### 3.2 B3-N1 开章选择

开战前由情报室/战前简报提供 3 个立场选项：

| 选项 | 文案 | 信念变化 | Runtime 影响 |
|---|---|---|---|
| `protect_civilians` | 优先保护平民，宁可放慢追击 | ren +10, yi -2, zhi +2 | C1-C3 初始士气 +1，E4 提前 1 回合行动 |
| `strike_captain` | 斩首队长，快速破局 | yi +10, ren -3, zhi +1 | E1 初始暴露，平民 AI 更保守 |
| `cut_supply` | 先烧补给，诱敌离位 | zhi +10, ren +1, yi -2 | E2/E3 初始位置前移，物资箱可交互 |

### 3.3 Ch.3-2 `chapter_03_act_b`

第二战使用 Ch.3-1 的结果作为压力输入。若平民救出数低于 2，敌方士气 +1；若 E1 在 6 回合内被击败，我方开局获得一次先手提示。

**目标**：推进到关隘信标并守住 2 回合。
**B3-N2 行为计分**：

| 行为 | 信念变化 |
|---|---|
| 救出全部平民 | ren +6 |
| 8 回合内清场 | yi +6 |
| 通过补给/地形交互削弱敌方 | zhi +6 |
| 平民阵亡 | ren -5 / yi +2 |

### 3.4 B3-GATE

B3-GATE 在 `chapter_03_act_b` 结算后运行，只标记 soft-lock candidate，不阻止玩家继续。

```text
dominant_route = argmax(ren, yi, zhi)
margin = dominant_value - second_value
soft_lock_candidate = margin >= 20
fallback_route = "zhi" when all values are tied or missing
```

**存档字段**

```json
{
  "chapter": 3,
  "b3_gate": {
    "dominant_route": "ren|yi|zhi",
    "margin": 0,
    "soft_lock_candidate": false,
    "evaluated_after": "chapter_03_act_b"
  }
}
```

旧存档缺少 B2/B3 数据时，使用 `ren=0, yi=0, zhi=0`，`fallback_route="zhi"`，并在战役菜单显示“路线未定”。

### 3.5 Ch.3-3 `chapter_03_finale`

第三战围绕 B3-GATE 的 dominant_route 调整一条敌方增援线：

| dominant_route | 战场变化 |
|---|---|
| ren | 平民撤离点更多，但敌人追击平民更激进 |
| yi | 首领护卫减少，但正面敌人属性更高 |
| zhi | 可交互机关更多，但回合压力更严格 |

---

## 4. Formulas

### F1 - B3-GATE 路线判断

```text
dominant_route = argmax(ren, yi, zhi)
margin = dominant_value - second_value
soft_lock_candidate = margin >= 20
```

### F2 - Ch.3-1 平民救援评分

```text
civilian_score = rescued_civilians * 2 - civilian_deaths * 3
if civilian_score >= 6: ren += 4
if civilian_score <= 0: ren -= 4
```

### F3 - 基地整备提示

```text
readiness_score = min(5, highest_enhanced_item_level) + trained_action_count + bond_rank_count_C_or_above
if readiness_score < 2: show_intel_warning = true
```

该公式仅用于情报/提示，不直接改战斗数值。

---

## 5. Edge Cases

- If B2-GATE 数据缺失：Ch.3 以中立开局，B3-GATE fallback 到 `zhi`，但不写 hard lock。
- If Bond MVP 没有任何 C 级关系：Ch.3 特殊对话降级为普通战前提示，不阻塞战斗。
- If 玩家没有强化装备：敌人数值不降低，只在情报室提示“建议强化一件主武器至 +3 以上”。
- If 行动点为 0：训练和未来酒馆交互不可用，但市集、装备强化、情报室仍可使用。
- If 平民路径被单位堵住：平民 AI 选择最近可通行格等待，不判定失败。

---

## 6. UI / Audio / Visual Requirements

- 情报室显示 Ch.3-1 标题、目标、地图风险和建议准备项。
- 战前选择 UI 显示 3 个选项与路线倾向提示，但不显示精确数值。
- B3-GATE 结算只展示“路线倾向正在形成”，不使用“已锁定”措辞。
- Bond 特殊台词只在已有 C 级关系时出现，并标记角色 pair。
- 本章不要求新增美术或音频；可复用现有战斗 BGM、结算音效和文本面板。

---

## 7. Acceptance Criteria For Implementation

- [ ] `chapter_03_act_a.json` 包含 battle_id、objective、briefing、map_size、terrain、units、settlement、progress_on_start、progress_on_victory。
- [ ] Ch.3-1 至少包含 5 名敌人、3 名平民/目标单位和 1 个 Ch.2 状态影响点。
- [ ] B3-N1 选项写入 `story_progress.belief`，并可通过 save/load 保留。
- [ ] B3-N2 行为结果可从战斗结算或 battle_history 计算。
- [ ] B3-GATE 写入 `story_progress.b3_gate`，旧存档 fallback 可测试。
- [ ] 情报室能读取 Ch.3-1 briefing，不依赖战斗场景启动。
- [ ] 自动测试覆盖：B3-GATE margin、旧存档 fallback、Ch.3-1 JSON 加载、情报室 briefing。

---

## 8. Sprint-007 Handoff

Sprint-007 可直接开工的实现入口：

1. 新增 `src/ui/combat/battle_definitions/chapter_03_act_a.json`，使用本文件 3.1 的地图和敌方编队。
2. 在战斗载入流程加入可选 `narrative_choice` 解析，复用 Ch.2 的 belief 结构。
3. 在结算流程加入 B3-N2 行为评分与 B3-GATE evaluator。
4. 在 Base Intel Tab 中加入 Ch.3 readiness warning，读取装备强化等级、训练次数和 C 级 Bond 数。
5. 保持 Tavern、Base Upgrade UI、Fog-of-war、Ch.3-2/Finale runtime 为后续切片，除非 Sprint-007 明确扩大范围。
