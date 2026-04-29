# Story 002: Unit Scene — 场景结构 + 视觉表现

> **Epic**: Unit
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/unit.md`
**Requirement**: `TR-unit-006`, `TR-unit-010`

**ADR Governing Implementation**: ADR-0003: Unit Public Interface Contract
**ADR Decision Summary**: Unit 场景根节点为 Node2D，子节点为 ColorRect（48×48，瓦片 64×64 内居中）+ Label（偏移 Vector2(0,-40) 位于正上方）。颜色由 Faction 驱动：Player=#3B82F6（蓝），Enemy=#EF4444（红）。已行动单位去饱和度（Color.GRAY、50% modulate）。死亡时无动画——直接 queue_free()。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: Node2D、ColorRect、Label、CanvasItem.modulate 自 4.0 起稳定。

---

## Acceptance Criteria

- [ ] **AC-C2 — 阵营颜色**: PLAYER Unit → ColorRect 为蓝 `#3B82F6`。ENEMY Unit → 红 `#EF4444`。
- [ ] **AC-C4 — 场景结构**: Unit.tscn 根节点 Node2D，子节点: ColorRect（48×48，居中于 64×64 瓦片）+ Label（offset (0,-40) 在中心上方）。
- [ ] **AC-C9 — 视觉去饱和**: 未行动 Unit → 完整阵营颜色 + 100% 不透明度。has_acted_this_turn==true → modulate=Color.GRAY + 50% alpha。

---

## Implementation Notes

```
Unit (Node2D)
├── Body (ColorRect)
│   - size: (48, 48)
│   - position: (-24, -24)  # 在 64×64 瓦片内居中
│   - color: faction == PLAYER ? #3B82F6 : #EF4444
└── HPLabel (Label)
    - position: (0, -40)  # 单位中心正上方
    - text: "HP: 8/10"
    - horizontal_alignment: CENTER
```

- `_update_visual()` 在以下时机调用: _ready()、take_damage() 后、reset_action_state() 后
- 去饱和: `modulate = Color.GRAY; modulate.a = 0.5`（非 has_acted 时重置为 `Color.WHITE`）
- 阵营颜色在 _ready() 中根据 faction 一次性设置，运行时不可变（faction 无 setter）

---

## Out of Scope

- Story 001: UnitStats .tres 加载与校验
- Story 003: 公共接口、状态机、Faction enum 定义
- Story 004: HP 更新逻辑、unit_died 信号
- 选中高亮: 属于 UI/Input Epic（HighlightLayer 叠加层）

---

## QA Test Cases（Manual Verification）

- **AC-C2**: 阵营颜色目视检查
  - Setup: 场景中放置 1 个 PLAYER Unit + 1 个 ENEMY Unit
  - Verify: Player 为蓝色矩形，Enemy 为红色矩形
  - Pass condition: 两个单位颜色明显可区分，符合 #3B82F6 和 #EF4444

- **AC-C4**: 场景树结构
  - Setup: 在 Godot 编辑器中打开 Unit.tscn
  - Verify: 根节点为 Node2D，含 Body (ColorRect, 48×48) 和 HPLabel (Label, offset -40 Y)
  - Pass condition: 两个子节点均存在，无多余/缺失节点

- **AC-C9**: 去饱和度状态切换
  - Setup: 一个未行动 Unit 和一个 has_acted_this_turn=true 的 Unit
  - Verify: 已行动 Unit 变灰且半透明，未行动 Unit 保持完整颜色
  - Pass condition: 两个单位视觉状态明显不同

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/unit-visual-evidence.md` — must exist + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（UnitStats 加载——_ready() 中需要 faction 和 hp 来设置颜色和标签文字）
- Unlocks: Story 003（状态机驱动视觉更新）、Story 004（HP 变化触发标签更新）
