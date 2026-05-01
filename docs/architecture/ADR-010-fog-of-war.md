# ADR-010: Fog-of-War Architecture

> **Status**: Accepted
> **Date**: 2026-05-01
> **Author**: technical-director
> **Systems Affected**: Fog-of-War, Tactical Mechanism, AI System, Save System, Combat Targeting, UI/Battle HUD

---

## Context

Sprint-009 将实现战争迷雾系统 MVP。GDD `fog-of-war-system.md` 已定义三态模型（unknown/explored/visible）、视野计算公式、盲射惩罚等核心规则。系统需要在 Godot 4.6.2 中以最小性能开销实现 15×15~25×25 网格的迷雾渲染，同时保持与非迷雾关卡的零开销兼容。

---

## Decision

### 1. 数据模型独立于战斗网格

Fog 状态存储为独立的 `Dictionary[Vector2i, int]`（key=cell coordinate, value=state enum），挂载在 battle_state 上。不修改 TacticalGrid 的数据结构。

**理由**: 迷雾是可选关卡机制，不应侵入核心战斗网格。关闭迷雾的关卡不分配 fog 数据。

### 2. 三态枚举 + explored_cells 持久化

```gdscript
enum FogCellState { UNKNOWN = 0, EXPLORED = 1, VISIBLE = 2 }
```

- `VISIBLE` 每回合/移动后重算（瞬态）
- `EXPLORED` 持久到本场战斗结束
- `UNKNOWN` 是默认值（不存储，查找时 fallback）

SaveData 路径: `battle_state.explored_cells: Array[Vector2i]`（仅存储 explored 格坐标，不存储 visible/unknown 以减少存档体积）。

### 3. 渲染层使用 TileMapLayer + modulate 而非自定义 drawing

使用 Godot 4.6 的 `TileMapLayer` 在战斗网格上方渲染半透明覆盖层：
- UNKNOWN: 不渲染（默认黑色背景透过）
- EXPLORED: dark modulate（Color(0, 0, 0, 0.5)）
- VISIBLE: 不渲染（透明）

**理由**: TileMapLayer 的批量渲染比逐个 `draw_rect` 调用更适合网格规模。Jolt 物理引擎（4.6 默认）不影响此渲染路径。

### 4. 敌人可见性通过 targeting 过滤器实现

不在 AI 层添加视野检查。战斗 targeting 系统在获取可选目标列表时过滤 `explored`/`unknown` 格上的敌人。AI 全知地图布局（与 GDD 一致），但通过 targeting 过滤器限制攻击目标。

### 5. 关卡 opt-in 模型

`battle_definition.fog: Dictionary` 控制迷雾启用：
```gdscript
{
  "enabled": true,
  "density": "night",     # night/ambush/recon
  "base_vision": 3,
  "scout_bonus": 3
}
```

`fog.enabled == false` 或 `fog` 字段缺失时，完全跳过所有迷雾逻辑。零开销兼容旧关卡。

---

## Consequences

### Positive

- 非迷雾关卡零性能开销（opt-in 检查在入口处短路）
- 存档体积可控（仅 explored 坐标数组，25×25 全图最坏情况 ~2.5KB）
- 不侵入 TacticalGrid / AI 核心逻辑
- TileMapLayer 渲染路径在 Godot 4.6 中成熟稳定

### Negative

- MVP 不做 line-of-sight 裁剪（墙体/遮挡物），高密度障碍物地图体验会受影响
- TileMapLayer 的 per-cell 更新在大网格（25×25）下全量刷新可能触发 >1000 次 cell 设置，需在实现时确认批处理策略

---

## Rejected Alternatives

- **将 fog state 嵌入 TacticalGrid 数据结构**: 拒绝——TacticalGrid 是非迷雾关卡的核心依赖，侵入式改动会导致大量回归风险。
- **使用自定义 `draw_rect`/`draw_circle` 渲染覆盖层**: 拒绝——无法利用批量渲染，在大网格下可能有性能问题。
- **MVP 阶段实现 line-of-sight 裁剪**: 推迟——Ballmann 或 Bresenham LOS 增加约 1-1.5 天实现和调参工作，不阻塞 MVP 交付。

---

## Verification Required

- 迷雾关卡的 unit test: 视野半径计算、侦察兵加成、三态状态转换
- 迷雾关闭的 integration test: 验证旧战斗定义加载不触发任何 fog 逻辑
- Fog state round-trip: save/load 还原 explored_cells
- Performance smoke: 25×25 全图迷雾 + 16 单位的帧率不低于 55 FPS

---

## ADR Dependencies

- **ADR-004** (Combat System): targeting 过滤器依赖 combat targeting 接口
- **ADR-003** (Save System): explored_cells 通过 SaveData battle_state 持久化
- **ADR-005** (AI Behavior): AI 全知地图设计已在 GDD 确认

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| `TileMapLayer` cell-based rendering | ✓ (4.3+) |
| `Dictionary[Vector2i, int]` 序列化 | ✓ |
| Jolt physics (default 4.6) | ✓ 不影响 2D 渲染 |
| D3D12 default (Windows) | ✓ 无影响 |

---

## GDD Requirements Addressed

- `design/gdd/fog-of-war-system.md` — TR-fog-001（三态可见性模型 + 视野公式）
- `design/gdd/fog-of-war-system.md` — TR-fog-002（迷雾渲染覆盖层 + map-opt-in 切换）
- `design/gdd/fog-of-war-system.md` — TR-fog-003（隐藏敌人渲染 + targeting 过滤）
- `design/gdd/fog-of-war-system.md` — TR-fog-004（battle_state explored_cells 持久化）
