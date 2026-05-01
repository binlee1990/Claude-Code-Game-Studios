# Changelog — SRPG 开发变更日志

> **版本**: v0.0.1-alpha
> **生成日期**: 2026-05-01
> **覆盖**: 2026-04-21 → 2026-05-01 (Sprint-001~008)
> **生成方式**: git log + sprint plans 汇总

---

## Sprint-008 (2026-04-27) — Ch.3 内容完成

### 新增
- Ch.3 战斗 2（压力量表系统）
- B3-GATE 信念分叉激活（3 路线判定 + 软锁检测）
- Ch.3 Finale Boss 战（路线变量 + 多阶段）
- 装备分解 UI + 词缀 reroll UI
- 羁绊组合技 GDD（4 类型 × 效果规格）
- 战争迷雾 GDD（三态模型 + 视野公式）

### 改进
- `architecture.md` §8 补全 + ADR 001~009 Dependencies/Engine/GDD 修复
- 测试: 879/879 PASS

---

## Sprint-007 (2026-04-27) — Ch.3 启动 + 养成深化

### 新增
- Ch.3 战斗 1（可玩路径 + 胜利通路）
- 基地酒馆 Tab（支援对话状态 + 羁绊 affinity）
- 基地升级 Tab（消耗预览 + 等级持久化）
- 装备 +6~+10 风险区（失败降级 + 保护符号）
- 架构全面审查（ADR-001~009 一致性）

### 改进
- 测试: 855/855 PASS
- Windows export + packaged smoke PASS

---

## Sprint-006 (2026-04-27) — 羁绊 + 强化 + 基地

### 新增
- 羁绊系统 MVP（BondRegistry + affinity 事件钩子）
- 装备强化 UI（已装备物品 +1~+5 安全区）
- 基地行动点系统（AP per chapter + save/load）
- 情报室（只读章节简报 + 下战预览）
- Ch.3 GDD skeleton

### 改进
- 基地升级消耗配置表（Lv1~Lv5）
- 强化成本来源统一到资源经济常量

---

## Sprint-005 (2026-04-27) — 本地化 + 收尾

### 新增
- 多语言管理（中/英运行时切换 + locale 持久化）
- Credits overlay
- ADR-008（资源经济升级范围）
- ADR-009（装备升级范围）
- Ch.3 GDD skeleton
- Fog-of-War readiness epic
- Bond readiness epic

### 修复
- Packaged smoke BGM resource leak

---

## Sprint-004 (2026-04-26) — 管理界面 + 基地 MVP

### 新增
- 角色管理面板（Tab 切换 + 属性/职业/技能显示）
- 装备管理面板（装备/卸下/详情）
- 基地 Hub（训练场 + 市集入口）
- Inventory 提升为 Autoload

---

## Sprint-003 (2026-04-26) — Ch.2 完整可玩

### 新增
- Ch.2 三战完整路径（act_a → B2-GATE → act_b/suppression → finale）
- B2-GATE 信念值分叉（义≥5→suppression，否则→mercy）
- 王秀 AI（A* 寻路 + 畏缩行为）
- 护卫姿态（伤害分摊 30%）
- 镇压战结算（双路线 variant）
- Boss 三阶段 + 检查点 + 援军刷新
- 果子二选三系统

### 改进
- 测试: 686→776 PASS (+90)

---

## Sprint-002 (2026-04-26) — 治理 + 观感 + Ch.2 基线

### 新增
- ADR-004 (Combat System) / ADR-005 (AI Behavior) / ADR-006 (Attribute Data Model) → Accepted
- Control Manifest v2（覆盖 ADR-001~006）
- Ch.2 GDD 全量展开（8 节）
- 信念值分支叙事设计
- 标题字体 ZCOOL XiaoWei + 正文字体 Noto Serif SC
- 主菜单 BGM + 战斗 BGM（CC-BY 3.0）
- 主菜单焦点系统（GOLD 视觉统一）
- 战斗 Auto/手动徽章 + Speed badge
- 回合立牌迷你 HP 条
- 全局按键提示行（HintBar）

### 修复
- TR registry 路径规范化

---

## Sprint-001 (2026-04-21 → 2026-04-25) — Vertical Slice

### 新增
- 回合制战斗模式（速度序列 + 行动系统 + 移动系统 + 战斗流程状态机）
- 自动战斗 + 加速模式（1×/2×/3×）
- 战斗结算系统（经验/评价/掉落/战斗历史）
- 视角与地图（2D top-down 网格）
- 战斗 HUD + 资源菜单
- Windows 打包构建
- 5 个核心 epic 完成: attribute (7 stories), class (6), resource (6), tactical (5), AI (6)
- 3 个 P3 epic 完成: skill (7), equipment (7), character (3)
- 447 test functions 全部 PASS

---

## Foundation (2026-04-21 之前)

### 新增
- 24 系统 GDD 完整设计
- ADR-001 (Event Architecture) / ADR-002 (Scene Management) / ADR-003 (Save System)
- Architecture Review + Control Manifest v1
- TR Registry + Entity Registry
- Cross-GDD consistency check + fix
- 项目 scaffold: Godot 4.6.2 + GDScript + GUT

---

## 当前里程碑统计

| Metric | Value |
|--------|-------|
| GDD 系统 | 24/24 Designed |
| ADR | 13 Accepted |
| Epic | 20 (18 Complete + 2 Sprint-009) |
| 故事 | ~130 total |
| 测试 | 879 PASS / 0 FAIL |
| 可玩章节 | Ch.1 ~ Ch.3 (9+ 战) |
| 构建 | Windows .exe (124MB) |
| 本地化 | 中/英（字符串仍在源码中 hardcode） |
