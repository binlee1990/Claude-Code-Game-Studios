# Smoke Test: Critical Paths

**用途**：在任何 QA 交接前 ≤15 分钟人工跑完。
**调用方**：`/smoke-check` 读取本文件。
**维护**：每个 sprint 实现新核心系统时往下加条目，删过期条目。

## Core Stability（始终运行）

1. 游戏从启动到主菜单无崩溃、无 stderr error / push_error
2. 主菜单可启动新存档 / 进入既有存档
3. 主菜单对所有输入响应正常，无僵死

## Core Mechanic（按 sprint 更新）

<!-- 每个 sprint 实现新核心系统时往这里加条目 -->
<!-- 示例: "ResourceSystem 累加 BigNumber 资源后 HUD 即时刷新" -->
4. [Primary mechanic — 第一个 Foundation/Core sprint 实现后填入]

## 存档完整性（SaveSystem 实现后启用）

5. 存档保存完成、无 push_error、文件落盘
6. 重新启动后读档恢复正确状态（resource、cultivation、time、rng seed）
7. 存档版本号正确递增；旧版本存档触发 migration 路径

## 离线 / 时间体系（TimeManager / OfflineSimulationCore 实现后启用）

8. 离线 30 秒后回到游戏，离线收益结算 = 公式预期值（容差 ε）
9. 关闭/恢复 PC 后时间戳差值正确，不依赖 _process 累计（ADR-0003）
10. 离线 simulation tick 粒度符合 ADR-0015

## 性能（核心循环跑通后启用）

11. 60 fps 目标硬件无明显掉帧（≥3 分钟 idle 观测）
12. 5 分钟 idle 内存无明显增长（堆稳定，无泄漏）
13. 自动战斗 30 秒内 draw call ≤ 100（technical-preferences.md 预算）

## 可访问性（Pre-Production 后启用）

14. 主要交互可用键鼠完成（gamepad partial 范围内）
15. UI 可缩放或文字字号符合 design/accessibility-requirements.md tier
