# Architecture Review Report

**Date**: 2026-04-30
**Engine**: Godot 4.6.2-stable
**Review Mode**: Full
**GDDs Reviewed**: 10（systems-index + game-concept + 8 system GDDs）
**ADRs Reviewed**: 4（ADR-0001 ~ ADR-0004）

---

## Verdict: CONCERNS

**PASS** — 不满足（需 ≥90% Foundation+Core 覆盖率，当前 Core 层 Turn 完全覆盖，Unit 80% 覆盖，但 Foundation 层 Map 仅 22% 直接覆盖）
**CONCERNS** — ✅ 当前状态：Foundation+Core 层 4 份 ADR 零冲突，依赖图为干净 DAG，引擎兼容性 PASS。但 Foundation 层 Map 系统仍有 6 项空白，Feature 层 4 个系统全部缺少 ADR。
**FAIL** — 不满足（无阻塞性跨 ADR 冲突）

### 阻塞问题（必须在 PASS 前解决）

1. Map CSV 加载格式 + 占用追踪 ADR（Foundation 层空白 —— 所有系统依赖 Map）
2. Movement System ADR（BFS + MovementResult —— Feature 层第一个系统）
3. Attack System ADR（伤害公式 + 射程检查）
4. AI Controller Interface ADR（@abstract 基类 + ActionPlan/ActionList/WorldState）

---

## Traceability Summary

| 层级 | 系统 | 需求数 | ✅ 覆盖 | ⚠️ 部分 | ❌ 空白 |
|------|------|--------|---------|---------|---------|
| Foundation | Map | 9 | 2 | 1 | 6 |
| Core | Unit | 10 | 8 | 1 | 1 |
| Core | Turn | 10 | 10 | 0 | 0 |
| Feature | Movement | 6 | 1 | 1 | 4 |
| Feature | Attack | 7 | 1 | 0 | 6 |
| Feature | Victory | 5 | 4 | 0 | 1 |
| Feature | AI | 7 | 1 | 1 | 5 |
| Presentation | UI | 8 | 2 | 0 | 6 |
| Cross-cutting | — | 3 | 3 | 0 | 0 |
| **合计** | | **65** | **32 (49%)** | **4 (6%)** | **29 (45%)** |

---

## Coverage Gaps (No ADR Exists)

### Foundation Layer

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-map-002 | map.md | TileMapLayer + CSV data-driven map loading | Map CSV Loading Format | Data |
| TR-map-003 | map.md | Atomic `move_unit()` for occupancy consistency | Map Occupancy & Move ADR | Data Integrity |
| TR-map-004 | map.md | Three tile states (walkable/blocked/obstacle) | Map CSV Loading Format | Grid Topology |
| TR-map-005 | map.md | 4-directional von Neumann neighbor query | Map Grid Topology (可合并) | Grid Topology |
| TR-map-006 | map.md | Occupancy tracking (Dictionary[Vector2i, Unit]) | Map Occupancy & Move ADR | Data Integrity |
| TR-map-008 | map.md | Map data validation on CSV load (dimensions, chars) | Map CSV Loading Format | Data Validation |

### Feature Layer — Movement

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-mov-001 | movement.md | BFS reachable tile computation over Map grid | Movement System (BFS + Result) | Algorithm |
| TR-mov-002 | movement.md | MovementResult immutable data object | Movement System (BFS + Result) | Data Structure |
| TR-mov-005 | movement.md | Manhattan distance formula ownership | Movement System (BFS + Result) | Formula |
| TR-mov-006 | movement.md | Path reconstruction from BFS parent map | Movement System (BFS + Result) | Algorithm |

### Feature Layer — Attack

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-atk-001 | attack.md | Deterministic damage formula `max(atk-def, 1)` | Attack System (Damage + Range) | Formula |
| TR-atk-002 | attack.md | Manhattan distance range check | Attack System (Damage + Range) | Formula |
| TR-atk-004 | attack.md | AttackRangeResolver target filtering/sorting | Attack System (Damage + Range) | Algorithm |
| TR-atk-005 | attack.md | AttackResult immutable data object | Attack System (Damage + Range) | Data Structure |
| TR-atk-006 | attack.md | No counter-attack in MVP (signal slot reserved) | Attack System (Damage + Range) | Interface |
| TR-atk-007 | attack.md | Damage preview (resolve_damage static method) | Attack System (Damage + Range) | API |

### Feature Layer — Victory

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-vic-004 | victory.md | Both factions eliminated → PLAYER wins (fallback) | Victory System | Edge Case |

### Feature Layer — AI

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-ai-001 | ai.md | @abstract AIController base class | AI Controller Interface | Interface |
| TR-ai-003 | ai.md | ActionPlan/ActionList/WorldState data structures | AI Controller Interface | Data Structure |
| TR-ai-004 | ai.md | NullAI returns empty ActionList | AI Controller Interface | Implementation |
| TR-ai-006 | ai.md | Interface admits NullAI + BasicAI without Turn edits | AI Controller Interface | Interface Validation |
| TR-ai-007 | ai.md | WorldState.clone() deep copy for simulations | AI Controller Interface | Data Integrity |

### Presentation Layer — UI

| TR-ID | GDD | Requirement | Suggested ADR | Domain |
|-------|-----|-------------|---------------|--------|
| TR-ui-001 | ui.md | InputContext state machine (BOARD_IDLE/UNIT_SELECTED/ATTACK_TARGETING) | UI/Input Architecture | State Machine |
| TR-ui-002 | ui.md | 3×HighlightLayer with _draw() (move/path/attack) | UI/Input Architecture | Rendering |
| TR-ui-003 | ui.md | HUD elements (turn indicator, faction indicator, End Turn) | UI/Input Architecture | UI Layout |
| TR-ui-004 | ui.md | Result overlay (WIN/LOSE/DRAW screens) | UI/Input Architecture | UI Layout |
| TR-ui-007 | ui.md | Debug coordinate overlay default ON | UI/Input Architecture | Debug |
| TR-ui-008 | ui.md | Color tokens (move cyan, path bright cyan, attack orange, etc.) | Color Token Specification | Visual |

---

## Full Traceability Matrix

### Map / Coordinates (Foundation)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-map-001 | GridSpace as sole coordinate transform authority (world_to_grid, grid_to_world, tile_center) | ADR-0001 | ✅ |
| TR-map-002 | TileMapLayer + CSV data-driven map loading | — | ❌ |
| TR-map-003 | Atomic move_unit() for occupancy consistency | ADR-0001 (partial) | ⚠️ |
| TR-map-004 | Three tile states (walkable/blocked/obstacle) from CSV | — | ❌ |
| TR-map-005 | 4-directional von Neumann neighbor query (get_neighbors) | — | ❌ |
| TR-map-006 | Occupancy tracking (Dictionary[Vector2i, Unit]) | — | ❌ |
| TR-map-007 | TILE_SIZE=64 constant encapsulation in GridSpace | ADR-0001 | ✅ |
| TR-map-008 | Map data validation on CSV load (dimensions, characters) | — | ❌ |
| TR-map-009 | place_unit/remove_unit with validation + error return | — | ❌ |

### Unit (Core)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-unit-001 | UnitStats as .tres Resource (data-driven, 5 attributes) | ADR-0003 | ✅ |
| TR-unit-002 | Faction enum in standalone file (src/core/faction.gd) | ADR-0003 (partial) | ⚠️ |
| TR-unit-003 | Stable public interface for 5 downstream consumers | ADR-0003 | ✅ |
| TR-unit-004 | Mutation authorization (take_damage, heal, reset_action_state) | ADR-0003 | ✅ |
| TR-unit-005 | unit_died signal contract (exactly once, before queue_free) | ADR-0003 | ✅ |
| TR-unit-006 | Unit scene structure (Node2D + ColorRect + Label) | ADR-0003 | ✅ |
| TR-unit-007 | action_state machine (IDLE/SELECTED/MOVED/ACTED/DEAD) | ADR-0003 | ✅ |
| TR-unit-008 | .tres validation fail-fast on bad data (validate()) | ADR-0003 | ✅ |
| TR-unit-009 | Monotonically increasing unit_id generation | — | ❌ |
| TR-unit-010 | Visual state mapping (acted = gray + 50% alpha) | — | （Visual/Feel — ADR 可推迟） |

### Turn System (Core)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-turn-001 | TurnManager as RefCounted, DI, no Autoload | ADR-0004 | ✅ |
| TR-turn-002 | 4-state machine with 5 transitions | ADR-0004 | ✅ |
| TR-turn-003 | Auto-advance condition (all alive units of active faction acted) | ADR-0004 | ✅ |
| TR-turn-004 | VictoryChecker injection + determine_winner() contract | ADR-0004 | ✅ |
| TR-turn-005 | AIController injection + take_turn() contract | ADR-0004 | ✅ |
| TR-turn-006 | TurnConfig.tres data-driven (turn_cap [1,99]) | ADR-0004 | ✅ |
| TR-turn-007 | End Turn reentrancy guard | ADR-0004 | ✅ |
| TR-turn-008 | Signal contract (5 signals, consumer obligations) | ADR-0004 | ✅ |
| TR-turn-009 | Faction elimination → immediate MATCH_ENDED | ADR-0004 | ✅ |
| TR-turn-010 | end_reason single source of truth (VictoryChecker) | ADR-0004 | ✅ |

### Movement (Feature)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-mov-001 | BFS reachable tile computation over Map grid | — | ❌ |
| TR-mov-002 | MovementResult immutable data object | — | ❌ |
| TR-mov-003 | MovementResolver as RefCounted pure function | ADR-0002 (DI pattern) | ⚠️ |
| TR-mov-004 | Map.move_unit() atomic requirement | ADR-0001 (partial) | ⚠️ |
| TR-mov-005 | Manhattan distance formula ownership | — | ❌ |
| TR-mov-006 | Path reconstruction from BFS parent map | — | ❌ |

### Attack (Feature)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-atk-001 | Deterministic damage formula max(atk-def, 1) | — | ❌ |
| TR-atk-002 | Manhattan distance range check | — | ❌ |
| TR-atk-003 | AttackResolver as RefCounted pure function | ADR-0002 (DI pattern) | ⚠️ |
| TR-atk-004 | AttackRangeResolver target filtering/sorting | — | ❌ |
| TR-atk-005 | AttackResult immutable data object | — | ❌ |
| TR-atk-006 | No counter-attack in MVP (signal slot reserved) | — | ❌ |
| TR-atk-007 | Damage preview (resolve_damage static method) | — | ❌ |

### Victory (Feature)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-vic-001 | VictoryChecker as RefCounted pure function | ADR-0002 (DI pattern) | ✅ |
| TR-vic-002 | determine_winner() 3-param interface | ADR-0004 | ✅ |
| TR-vic-003 | Elimination > Turn Cap priority | ADR-0004 | ✅ |
| TR-vic-004 | Both factions eliminated → PLAYER wins (fallback rule) | — | ❌ |
| TR-vic-005 | end_reason single source of truth (VictoryChecker) | ADR-0004 | ✅ |

### AI / AIController (Feature)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-ai-001 | @abstract AIController base class (RefCounted) | — | ❌ |
| TR-ai-002 | take_turn(units, world_state) → ActionList contract | ADR-0004 (partial) | ⚠️ |
| TR-ai-003 | ActionPlan/ActionList/WorldState data structures | — | ❌ |
| TR-ai-004 | NullAI returns empty ActionList | — | ❌ |
| TR-ai-005 | Turn System execution model (AI plans, Turn executes) | ADR-0004 | ✅ |
| TR-ai-006 | Interface admits NullAI + BasicAI without Turn edits | — | ❌ |
| TR-ai-007 | WorldState.clone() deep copy for simulations | — | ❌ |

### UI / Input (Presentation)

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-ui-001 | InputContext state machine (BOARD_IDLE/UNIT_SELECTED/ATTACK_TARGETING) | — | ❌ |
| TR-ui-002 | 3×HighlightLayer with _draw() (move/path/attack) | — | ❌ |
| TR-ui-003 | HUD elements (turn indicator, faction indicator, End Turn button) | — | ❌ |
| TR-ui-004 | Result overlay (WIN/LOSE/DRAW screens) | — | ❌ |
| TR-ui-005 | Click→grid resolution via GridSpace.world_to_grid() | ADR-0001 | ✅ |
| TR-ui-006 | InputHandler as RefCounted, DI | ADR-0002 | ✅ |
| TR-ui-007 | Debug coordinate overlay default ON | — | ❌ |
| TR-ui-008 | Color tokens (move cyan, path bright cyan, attack orange, etc.) | — | ❌ |

### Cross-Cutting

| TR-ID | Requirement | ADR | Status |
|-------|-------------|-----|--------|
| TR-cc-001 | Dependency Injection over Autoloads (all systems) | ADR-0002 | ✅ |
| TR-cc-002 | Forbidden: inline position * 64 / / 64 outside GridSpace | ADR-0001 | ✅ |
| TR-cc-003 | RefCounted for logic objects, Node2D only for scene entities | ADR-0002 | ✅ |

---

## Cross-ADR Conflicts

**零冲突。** 4 份 ADR 之间无数据所有权冲突、接口契约冲突、性能预算冲突、依赖循环或架构模式矛盾。

### ADR Dependency Ordering

```
Foundation Layer (无依赖):
  1. ADR-0001: GridSpace — Coordinate Transform Boundary
  2. ADR-0002: Dependency Injection Architecture

Core Layer (依赖 Foundation):
  3. ADR-0003: Unit Public Interface Contract (requires ADR-0001, ADR-0002)
  4. ADR-0004: Turn System Architecture (requires ADR-0002, ADR-0003)

Feature Layer (依赖 Core — 层内可并行):
  5. ADR-0005: Movement System (requires ADR-0001, ADR-0003)
  6. ADR-0006: Attack System (requires ADR-0001, ADR-0003)
  7. ADR-0007: Victory System (requires ADR-0003, ADR-0004)
  8. ADR-0008: AI Controller Interface (requires ADR-0004, ADR-0005, ADR-0006)

Presentation Layer (依赖所有上游):
  9. ADR-0009: UI / Input Architecture (requires all above)
```

无未解决依赖。无循环依赖。

---

## Engine Compatibility Issues

### Engine Audit Results

| ADR | Verdict | Key Findings |
|-----|---------|-------------|
| ADR-0001 | ✅ PASS | floori/clampi/TileMapLayer 全部稳定（Godot 4.0+） |
| ADR-0002 | ✅ PASS（1 CONCERN） | RefCounted 循环引用风险未记录为 Forbidden Pattern |
| ADR-0003 | ✅ PASS（1 CONCERN） | @abstract 运行时保护链正确；需交叉引用验证 |
| ADR-0004 | ✅ PASS | 信号同步发射顺序正确；AIController null-safety 需与 AI GDD 对齐 |

### Engine Specialist Findings (Godot Specialist)

1. **`@abstract` 机制澄清**: 架构文档中"@abstract 仅编辑器级别"的说法部分不准确——类级别的 `@abstract` 在 Godot 4.5+ 运行时也会阻止实例化。当前双重守卫（class @abstract + method assert + release fallback）是正确的。

2. **RefCounted 循环引用**: 当前设计正确（Game scene 是唯一持有者），但建议记录为 Forbidden Pattern："RefCounted 对象不得持有其他 RefCounted 对象的永久引用——仅 Game 场景（Node）可持有。"

3. **ADR-0004 AIController 集成块**: 建议在 TurnManager 执行循环中添加 `if action_list == null or action_list.is_empty(): return` 守卫，与 AI GDD 的 release fallback 对齐。

4. **InputHandler 事件转发**: InputHandler 是 RefCounted，但需要接收 InputEvent。Game 的 `_unhandled_input()` → `InputHandler.handle_event()` 的转发机制应在实现前明确。

### Deprecated API References

**无。** 4 份 ADR 均使用现代 Godot 4 API：
- `instantiate()` 而非 `instance()` ✅
- `signal.connect(Callable)` 而非 string-based `connect()` ✅
- `TileMapLayer` 而非 `TileMap` ✅
- Typed arrays (`Array[Unit]`, `Array[Vector2i]`) ✅

### Missing Engine Compatibility Sections

无。全部 4 份 ADR 均包含 Engine Compatibility 章节。

### Stale Version References

无。全部 4 份 ADR 均引用 Godot 4.6.2-stable。

---

## GDD Revision Flags

**无 GDD 修订标志。** 所有 GDD 假设与经验证的引擎行为一致。

---

## Architecture Document Coverage

`docs/architecture/architecture.md` 审查结果：

- ✅ 全部 8 个系统出现在层次映射中
- ✅ 数据流章节覆盖所有跨系统通信
- ✅ API 边界支持所有 GDD 集成需求
- ⚠️ ADR Audit 表格过时——显示 "0/19 requirements covered"，但 4 份 ADR 已创建并覆盖了 32 项需求
- ⚠️ Required ADRs 列表包含已完成的条目（ADR-0001 ~ 0004）

**建议**: 更新 ADR Audit 表格以反映当前状态。

---

## Required ADRs (Prioritized)

| Priority | # | ADR Title | Covers | Layer |
|----------|---|-----------|--------|-------|
| 🔴 P0 | 5 | Map CSV Loading Format & Occupancy | TR-map-002~006, 008, 009 | Foundation |
| 🔴 P0 | 6 | Movement System (BFS + MovementResult) | TR-mov-001~006 | Feature |
| 🔴 P0 | 7 | Attack System (Damage Formula + Range) | TR-atk-001~007 | Feature |
| 🔴 P0 | 8 | AI Controller Interface | TR-ai-001~007 | Feature |
| 🟡 P1 | 9 | Victory System | TR-vic-004 | Feature |
| 🟡 P1 | 10 | UI / Input Architecture | TR-ui-001~008 | Presentation |
| 🟢 P2 | — | Faction Enum Location | TR-unit-002 | Core (minor) |
| 🟢 P2 | — | Color Token Specification | TR-ui-008 | Presentation (minor) |

---

## Next Steps

1. **立即行动**: 编写 ADR-0005（Map CSV Loading）和 ADR-0006（Movement System）
2. **后续行动**: 编写 ADR-0007（Attack System）和 ADR-0008（AI Controller）
3. **门禁指导**: 当 Foundation + Core + Feature ADR 覆盖率达到 >80% 时，运行 `/gate-check pre-production`
4. **重新审查**: 每编写一份新 ADR 后运行 `/architecture-review` 验证覆盖率改善
