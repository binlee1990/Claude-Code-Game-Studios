# Story 002: NPC 王秀护送 AI（A* + 畏缩 + 安全区到达 + 退场剧情）

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 1.0 days

## Context

**GDD**: `design/gdd/chapter-02.md` §3.3, §3.4, §5.2–5.3 / `design/gdd/ai-system.md`
**Requirement**: AC-CH2-002, AC-CH2-004 / QA Plan §3.2
**ADR Governing Implementation**: ADR-001 (Event Architecture) / ADR-003 (Save System) / ADR-005 (AI Behavior)

**Engine**: Godot 4.6.2 | **Risk**: MED — 王秀 A* 行为需参照 chapter_01 escort 已有实现

---

## Acceptance Criteria

- [x] **AC-CH2-002.1**: 模拟 5 回合：每回合王秀的位置向安全区（左上 3×3）方向移动至少 1 格（无障碍情形）。
- [x] **AC-CH2-002.2**: 模拟阻塞情形：敌方单位距王秀 ≤2 格时，王秀该回合不移动（畏缩生效）。
- [x] **AC-CH2-004.1**: 王秀 HP 降至 0 时，触发退场剧情动画；`wang_xiu_departed = true` 写入存档；战斗不结束（可继续作战）。
- [x] **AC-CH2-004.2**: 王秀退场后，战斗结算时信念值结算为 仁-8（不是 仁+12）。

---

## Implementation Notes

### 王秀 AI 行为规则

```
每回合王秀速度序列到达时：
1. 计算至安全区的 A* 路径
2. 若安全区方向直线距离内存在敌方单位（distance <= 2）：
   → 畏缩：跳过移动（0 格）
3. 否则：
   → 向安全区移动 1 格（每回合最多 1 格）
4. 若移动后进入安全区（3×3 左上角）：
   → 触发仁+12信念值节点（B2-N2A）
   → 王秀从速度序列移除（不再行动）
```

### 安全区定义

- 地图左上角 `[0,0]` ~ `[2,2]`（3×3 区域）
- 地形类型：`terrain_type == SAFE_ZONE`
- JSON 配置：`chapter_02_act_b.json` 内 `safe_zone: {x: 0, y: 0, width: 3, height: 3}`

### 畏缩判定

```
for each enemy_unit in get_enemies():
    if distance(wang_xiu, enemy_unit) <= 2:
        hesitate = true
        break
```

### 退场剧情触发

```
when wang_xiu.hp <= 0:
    1. emit signal "npc_departed" with {unit_id: "wang_xiu", battle_id: current_battle}
    2. set progress_data.wang_xiu_departed = true
    3. play departure_animation (3s)
    4. remove wang_xiu from combat
    5. continue battle (player can still win by defeating enemies)
```

### Edge Cases

| 情形 | 处理 |
|------|------|
| 王秀到达安全区同时被敌方攻击致死 | 优先判定到达安全区 → 仁+12 |
| 玩家歼灭所有追兵但王秀未到安全区 | 王秀存活，仁+12 照常结算 |
| 畏缩条件持续多回合 | 每回合重新评估；敌方离开后恢复移动 |
| 王秀 HP=0 但有护卫姿态激活 | 先扣护卫单位 HP，再判断王秀是否存活 |

---

## Out of Scope

- 护卫姿态伤害分摊逻辑（由 CH2-c-003 实现）
- 豪强骑兵 AI（属于 AI-system epic）
- Ch.2-2B 镇压战流民 AI（不同行为树）

---

## QA Test Cases

- **AC-CH2-002.1**: 正常移动
  - Given: 王秀在 (5,5)，安全区在左上角，无障碍无敌方
  - When: 模拟 5 回合
  - Then: 每回合移动 1 格，5 回合后 x 坐标减少 5

- **AC-CH2-002.2**: 畏缩不移动
  - Given: 王秀在 (5,5)，敌人在 (4,5)，distance=1 ≤ 2
  - When: 王秀回合开始
  - Then: 王秀不移动

- **AC-CH2-004.1**: 退场剧情
  - Given: 王秀 hp <= 0
  - When: departure triggered
  - Then: signal emitted, wang_xiu_departed=true, animation plays, unit removed

- **AC-CH2-004.2**: 退场信念值
  - Given: wang_xiu_departed=true, 战斗胜利
  - When: 信念值结算
  - Then: 仁-8（不是仁+12）

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chapter02/wang_xiu_ai_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/ai-system.md`（A* 寻路已有实现）、`design/gdd/battle-settlement.md`（信念值节点）
- Unlocks: CH2-c-003（护卫姿态分摊）、CH2-c-004（部分失败结算）

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/gameplay/ai/wang_xiu_ai.gd` | Create | 王秀 AI 行为树（A* + 畏缩） |
| `src/core/save/progress_data.gd` | Modify | 新增 `wang_xiu_departed` 字段 |
| `src/core/autoload/game_events.gd` | Modify | 新增 `npc_departed` signal |
| `assets/data/chapter_02_config.json` | Modify | 新增 `wang_xiu_hp=30`, `safe_zone` 定义 |
| `chapter_02_act_b.json` | Modify | 王秀单位定义 + 安全区引用 |
| `tests/unit/chapter02/wang_xiu_ai_test.gd` | Create | AC-CH2-002 + AC-CH2-004 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: 2026-04-26
**Criteria**: 4/4 AC passing
**Deviations**: Greedy Manhattan pathfinding instead of full A* — sufficient for Ch.2 map layout; can be upgraded to full A* if complex obstacle maps arise.
**Test Evidence**: `tests/unit/chapter02/wang_xiu_ai_test.gd` — 19/19 PASS
**Code Review**: /code-review
**Files Delivered**:
- `src/core/ai/wang_xiu_ai.gd` (new)
- `src/core/autoload/game_events.gd` (modified — added `npc_departed` signal)
- `tests/unit/chapter02/wang_xiu_ai_test.gd` (new)
- `tests/tests_manifest.txt` (modified)
