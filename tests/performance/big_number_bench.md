# BigNumber 性能验证记录

**日期**: 2026-05-04
**范围**: Sprint 1 / 大数值系统 Story 008
**测试文件**: `tests/performance/big_number_performance_test.gd`

## 验证目标

1000 个 BigNumber 实例各执行 5 次核心运算，在单帧预算 16.6ms 内完成。

## 本地执行状态

当前机器未发现 `godot` 可执行文件，无法执行 `godot --headless --script tests/gdunit4_runner.gd` 或 GdUnit4 性能测试。

## 已落地证据

- 性能测试文件已创建，使用 `Time.get_ticks_usec()` 记录运行时间。
- 测试断言 `elapsed_ms < 16.6`，可在安装 Godot 4.6.2 与 GdUnit4 后运行。
- 在未安装运行环境前，本条证据状态为 `PENDING_RUNTIME_EXECUTION`，不伪造通过结果。

