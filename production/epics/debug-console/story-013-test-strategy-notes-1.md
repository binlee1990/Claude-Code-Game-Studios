# Story 013: Test Strategy Notes 1

> **Epic**: 调试控制台
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/debug-console.md`
**Requirement**: `TR-debug-console-001` — DebugConsole provides debug-only runtime commands, event watching, pause-safe overlay behavior, and release-build self-removal.

**ADR Governing Implementation**: ADR-0011: UI 屏幕管理架构
**ADR Decision Summary**: Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0011 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use JSON files under `res://assets/data/` as the MVP configuration source** — source: ADR-0005
- Required: **Keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves** — source: ADR-0005
- Required: **Keep all MVP config tables resident in DataConfig memory after startup load** — source: ADR-0005
- Required: **Use SaveManager provider callbacks by namespace for persistence** — source: ADR-0006
- Forbidden: **Never use Godot Resource files as the MVP content format** — source: ADR-0005
- Forbidden: **Never write runtime player state through DataConfig** — source: ADR-0005
- Forbidden: **Never make SaveManager import or understand concrete system state types** — source: ADR-0006
- Guardrail: **DataConfig**: MVP load target <= 100 ms and cache <= 5 MB — source: ADR-0005
- Guardrail: **SaveManager**: MVP save/load target <= 20 ms and save object <= 50 KB — source: ADR-0006
- Guardrail: **ModifierEngine**: cached 1000 `get_multiplier()` calls target <= 1 ms — source: ADR-0007

---

## Acceptance Criteria

*From GDD `design/gdd/debug-console.md`, scoped to this story:*

- [ ] Automated unit tests (GDUnit4): → `tests/unit/debug_console/`：Release `queue_free` 行为、命令解析、错误分支（unknown / invalid handler / missing Autoload）、命令历史导航、输出缓冲溢出（行数断言）、`time speed` 范围拒绝、`event watch` 守卫（empty prefix / duplicate）。纯逻辑分支无需场景渲染，headless 跑：`godot --headless --script tests/gdunit4_runner.gd`。
- [ ] Integration tests: → `tests/integration/debug_console/`：`event watch` 订阅/回调/注销生命周期需 FakeEventBus stub 记录调用次数并按需触发合成事件；"close 自动注销所有 watch" 与 "已暂停的 tree 不被解暂停" 需场景树集成（`add_child_autofree` + 最小场景）。
- [ ] Manual QA（不易自动化）: BBCode 颜色渲染（gray/white/yellow/red/cyan）、`CanvasLayer` Z 序高于游戏 HUD、对真实 UI 控件（非 mock）的焦点恢复。归档至 `production/qa/evidence/debug-console-visual-[date].md` 含截图。

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

- Must build screens as Godot `Control` scenes managed by UIManager.
- Must test both mouse and keyboard/gamepad focus paths in Godot 4.6.
- Must use EventBus subscriptions and read-only queries for display state.
- Must route player actions through explicit command methods on owning systems.
- Must format every BigNumber through NumberFormatter.
- Must coalesce or throttle high-frequency resource/HUD refreshes.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 014 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: Automated unit tests (GDUnit4): → `tests/unit/debug_console/`：Release `queue_free` 行为、命令解析、错误分支（unknown / invalid handler / missing Autoload）、命令历史导航、输出缓冲溢出（行数断言）、`time speed` 范围拒绝、`event watch` 守卫（empty prefix / duplicate）。纯逻辑分支无需场景渲染，headless 跑：`godot --headless --script tests/gdunit4_runner.gd`。
  - Setup: the story preconditions from the linked GDD are set up
  - Verify: the behavior under this acceptance criterion is exercised
  - Pass condition: Automated unit tests (GDUnit4): → `tests/unit/debug_console/`：Release `queue_free` 行为、命令解析、错误分支（unknown / invalid handler / missing Autoload）、命令历史导航、输出缓冲溢出（行数断言）、`time speed` 范围拒绝、`event watch` 守卫（empty prefix / duplicate）。纯逻辑分支无需场景渲染，headless 跑：`godot --headless --script tests/gdunit4_runner.gd`。

- **Manual check**: Integration tests: → `tests/integration/debug_console/`：`event watch` 订阅/回调/注销生命周期需 FakeEventBus stub 记录调用次数并按需触发合成事件；"close 自动注销所有 watch" 与 "已暂停的 tree 不被解暂停" 需场景树集成（`add_child_autofree` + 最小场景）。
  - Setup: the story preconditions from the linked GDD are set up
  - Verify: the behavior under this acceptance criterion is exercised
  - Pass condition: Integration tests: → `tests/integration/debug_console/`：`event watch` 订阅/回调/注销生命周期需 FakeEventBus stub 记录调用次数并按需触发合成事件；"close 自动注销所有 watch" 与 "已暂停的 tree 不被解暂停" 需场景树集成（`add_child_autofree` + 最小场景）。

- **Manual check**: Manual QA（不易自动化）: BBCode 颜色渲染（gray/white/yellow/red/cyan）、`CanvasLayer` Z 序高于游戏 HUD、对真实 UI 控件（非 mock）的焦点恢复。归档至 `production/qa/evidence/debug-console-visual-[date].md` 含截图。
  - Setup: the story preconditions from the linked GDD are set up
  - Verify: the behavior under this acceptance criterion is exercised
  - Pass condition: Manual QA（不易自动化）: BBCode 颜色渲染（gray/white/yellow/red/cyan）、`CanvasLayer` Z 序高于游戏 HUD、对真实 UI 控件（非 mock）的焦点恢复。归档至 `production/qa/evidence/debug-console-visual-[date].md` 含截图。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/test-strategy-notes-1-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 014
