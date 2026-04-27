# Architecture Review — 2026-04-27 (增量)

| 字段 | 值 |
|---|---|
| Date | 2026-04-27 |
| Engine | Godot 4.6.2 |
| Mode | 增量审查（针对 ADR-008 / ADR-009 接受后的覆盖与一致性） |
| ADRs Reviewed | ADR-008, ADR-009（依赖项 ADR-001 / ADR-003 / ADR-004 同时核对） |
| GDDs Reviewed | resource-economy.md, equipment-system.md |
| Engine Reference Cross-checked | docs/engine-reference/godot/ (VERSION, breaking-changes, deprecated-apis, current-best-practices, modules/physics, modules/rendering, modules/ui) |
| Scope NOT covered | 其余 28 GDD / 7 ADR — 维持上一次 baseline 结论 |

---

## Verdict

🟡 **CONCERNS（已修复）**

接受 ADR-008 / ADR-009 后发现 3 个非阻塞修复项与 8 条 TR registry 同步缺失，本次会话已就地修复。无 blocking issue，无依赖循环，无引擎冲突，无 GDD revision flag。Sprint-006 base economy 与 equipment upgrade MVP 的实现门禁正式解除。

---

## Traceability Summary（增量）

| TR-ID | Registry `adr:`（修订前）| Registry `adr:`（修订后）| 状态 |
|---|---|---|---|
| TR-resource-001 | ADR-001, ADR-003 | ADR-001, ADR-003, **ADR-008** | ✅ |
| TR-resource-002 | ADR-001 | ADR-001, **ADR-008** | ✅ |
| TR-resource-003 | ADR-001 | ADR-001, **ADR-008** | ✅ |
| TR-resource-004 | ADR-001 | ADR-001, **ADR-008** | ✅ |
| TR-resource-005 | ADR-001 | ADR-001, **ADR-008**, **ADR-009** | ✅ |
| TR-resource-006 | ADR-001, ADR-003 | ADR-001, ADR-003, **ADR-008** | ✅ |
| TR-equip-001 | ADR-001 | 无变化 | ✅ |
| TR-equip-002 | ADR-001 | 无变化 | ✅ |
| TR-equip-003 | ADR-001 | ADR-001, **ADR-009** | ✅ |
| TR-equip-004 | ADR-001 | 无变化（ADR-009 显式排除 set crafting） | ✅ |
| TR-equip-005 | ADR-001 | 无变化（ADR-009 显式排除 decomposition） | ✅ |
| TR-equip-006 | ADR-001, ADR-006 | ADR-001, ADR-006, **ADR-009** | ✅ |
| TR-equip-007 | ADR-001, ADR-003 | ADR-001, ADR-003, **ADR-009** | ✅ |

8 行 registry 已同步，全部满足完整覆盖。无硬 gap。

---

## Cross-ADR Conflicts（已修复）

| # | 类型 | 描述 | 处置 |
|---|---|---|---|
| C-1 | Pattern conflict | ADR-008 草稿引入 `inventory_changed(item_id, delta)`，与 ADR-001 既有 `resource_changed` / `item_acquired` 信号语义重叠 | 已修：ADR-008 §Engine Compatibility 改为 "复用 ADR-001 既有 `resource_changed` / `item_acquired` 信号" |
| C-2 | Dependency 节歧义 | ADR-008 §ADR Dependencies 把 ADR-009 列在依赖项中，但语义实为 enables 方向 | 已修：拆出 **Depends On** 与 **Enables** 子节，ADR-009 移至 Enables |
| C-3 | TR ID 命名错误 | ADR-008 引用 `TR-econ-001..006`，registry 实际 ID 为 `TR-resource-001..006` | 已修：ADR-008 §GDD Requirements Addressed 改为 `TR-resource-001..006` |

---

## ADR Dependency Order（无 cycle）

```
Foundation (no external deps)
  ADR-001  Event Architecture
  ADR-008  Resource Economy Upgrade Scope     ← 新增（仅 enables，无外部依赖）

Depends on Foundation
  ADR-002  Scene Management            (depends ADR-001)
  ADR-003  Save System                 (depends ADR-001, ADR-002)

Core
  ADR-004  Combat System               (depends ADR-001, ADR-002)
  ADR-005  AI Behavior                 (depends ADR-001, ADR-004)
  ADR-006  Attribute Data Model        (depends ADR-001, ADR-003)

Feature
  ADR-007  Belief Branch System        (depends ADR-001, ADR-003, ADR-004)
  ADR-009  Equipment Upgrade Scope     (depends ADR-001, ADR-003, ADR-008)  ← 新增
```

✅ 无 cycle。✅ ADR-008 / ADR-009 均为 Accepted，下游 stories 可直接引用。

---

## Engine Compatibility（增量审计）

| 检查项 | 结果 |
|---|---|
| Godot 4.6.2 版本一致性 | ✅ 两份 ADR 均显式声明 4.6.2 |
| Post-cutoff API 使用 | ✅ 无 — 两份 ADR 仅依赖 Core API（Autoload / Resource / Signal / Control） |
| Deprecated API 引用 | ✅ 无（已 grep `playback_active`、`GodotPhysics3D for new projects` 等模式） |
| Jolt 物理切换影响 | ✅ 无 — ADR-008/009 不涉及物理 |
| D3D12 默认渲染影响 | ✅ 无 — ADR-008/009 不涉及渲染 backend |
| AccessKit / 屏幕阅读 | ⚠️ ADR-009 §Engine Compatibility 提到 `Control + GridContainer`；未来强化 UI 实现需符合 ADR-001 + AccessKit pipeline，建议在 Sprint-006 story acceptance 中显式列入 |

---

## GDD Revision Flags

无。ADR-008 / ADR-009 与 resource-economy.md / equipment-system.md 的引擎假设无冲突。

---

## Architecture Document Coverage

`docs/architecture/architecture.md` 在本次增量审查范围之外，未做 systems-index 与顶层架构文档对齐。建议在下一次 full mode `/architecture-review` 中处理。

---

## Required Follow-ups（next sprint）

| # | 项 | 时机 |
|---|---|---|
| F-1 | 实现 Sprint-006 base full economy story 时，登记新增 `equipment_enhanced(item_id, level, success)` 信号到 ADR-001 GameEvents 列表 | Sprint-006 实现期，story-by-story 同步 |
| F-2 | 在 Sprint-006 强化 UI story 验收中加入"Control 节点符合 AccessKit / 键盘导航"检查项 | Sprint-006 QA plan 阶段 |
| F-3 | 下次完整 `/architecture-review full` 时把 architecture.md 顶层文档纳入对齐 | 任意 Pre-Production 检查点 |

---

## Files Modified This Review

| 文件 | 变更 |
|---|---|
| `docs/architecture/ADR-008-resource-economy-upgrade.md` | §ADR Dependencies 拆 Depends On / Enables；§Engine Compatibility 移除 inventory_changed；§GDD Requirements Addressed TR-econ → TR-resource |
| `production/registries/tr-registry.yaml` | 8 行 `adr:` 字段补登 ADR-008/009；version 2→3；last_updated→2026-04-27 |
| `docs/architecture/architecture-review-2026-04-27.md` | 新建（本报告） |
| `production/session-state/active.md` | 追加本次审查的 Session Extract |

---

## Next Steps

1. 在新会话中运行 `/sprint-plan`，把 bond-system / fog-of-war / base full economy / equipment enhancement MVP 转为 Sprint-006 stories
2. 或在 release 视野下推进人工 QA 队列（`production/sprints/sprint-人工.md`）
3. 任意时刻可以再跑 `/architecture-review full` 完整核对全部 30 GDD / 9 ADR
