# 更合理的 SRPG 开源参考组合

如果目标是：**做一款原创中文 SRPG / 战棋 RPG，支持 AI 辅助开发、剧情关卡编辑、角色养成、技能职业、可扩展内容库、长期二开**，我不建议再用一堆项目平铺参考。

更合理的是采用：

> **1 个主开发路线 + 3 个核心参考项目 + 3 个专项参考项目**

---

# 一、最终推荐组合

## 主路线

> **Godot 4 自研主工程**

原因很直接：

* SRPG 多数是 **2D / 等距 / 格子 / UI 密集 / 数据驱动**，Godot 4 比 Unity 更轻，AI 辅助改代码也更直接。
* 不容易被 Unity 的序列化、Prefab、Package、Editor 状态污染拖慢。
* 对你这种“AI Coding + 结构化内容生成 + 长期二开”的路线，Godot 更适合作为新项目主工程。

**不建议直接拿某个开源 SRPG 改成自己的主工程**。更合理做法是：自己搭主工程，然后从几个成熟项目拆模块设计。

---

# 二、核心三件套

## 1. Lex Talionis：学“火纹式 SRPG 制作器”

**定位：SRPG 编辑器与规则参考核心。**

Lex Talionis / LT-Maker 官方定位就是一个免费开源、受 GBA《Fire Emblem》启发的战术游戏引擎，并且带完整编辑器，支持物品、技能、能力、事件等系统，底层是 Python。([lex-talionis.net][1])

你应该重点研究它的：

* 章节 / 关卡编辑器
* 单位、职业、成长率
* 武器、技能、状态、特效
* 事件脚本
* 对话、登场、胜败条件
* 出击准备界面
* 火纹式战斗预测
* 敌方 AI 行为
* 项目级自定义组件机制

它最适合作为你的 **SRPG 规则系统蓝本**。

---

## 2. Sulis：学“数据驱动 RPG + 战术战斗”

**定位：RPG 深度系统参考核心。**

Sulis 是一个开源 2D 战术 RPG，引擎和战役都基本完整，使用 Rust，Lua 脚本，数据文件主要是 YAML；官方介绍强调它从一开始就为 Mod 和自定义内容设计，并支持回合制战术战斗、角色自定义、多战役、剧情与程序化内容。([sulisgame.com][2])

你应该重点研究它的：

* 技能系统
* 道具 / 装备 / 背包
* 职业与角色成长
* 战斗行动系统
* 对话与任务
* YAML 数据组织
* Lua 脚本扩展
* Mod 内容加载

它不适合作为你直接复制的技术栈，但非常适合作为 **RPG 数据 Schema 与战斗系统蓝本**。

---

## 3. Battle for Wesnoth：学“大型战棋内容工程”

**定位：大型战役、地图、Mod、内容组织参考核心。**

Wesnoth 是长期维护的开源回合制幻想战棋项目，支持单人战役、在线/热座多人、地图编辑器、多阵营、多单位技能与特质，并且内容脚本使用 Lua 和 WML。([GitHub][3])

你应该重点研究它的：

* 多战役组织方式
* 地图编辑器
* 关卡脚本
* 单位升级与召回
* 阵营设计
* 地形影响
* 战役难度曲线
* Mod / Add-on 生态
* 长期项目目录结构

它不是典型“角色养成 SRPG”，更偏策略战棋，但非常适合研究 **大型内容工程与 Mod 生态**。

---

# 三、专项三件套

## 4. GDQuest Tactical RPG Movement：学“格子移动最小闭环”

**定位：基础移动系统参考。**

GDQuest 的 Tactical RPG Movement 示例明确是做类似《Fire Emblem》和《Advance Wars》的格子移动系统，包括光标、单位选择、可移动范围、路径预览、确认/取消移动等。([GitHub][4])

你应该只借它的：

* Grid 坐标系统
* 光标选择
* 可移动范围计算
* AStar / Flood Fill
* 路径预览
* 单位移动状态机

它不是完整游戏，但适合作为你主工程的 **第一阶段原型参考**。

---

## 5. Tanks of Freedom II：学“Godot 4 战棋工程结构”

**定位：Godot 4 战棋项目参考。**

Tanks of Freedom II 是基于 Godot 4.2+ 的开源回合制策略游戏，有等距体素美术、内置地图编辑器、单人战役和热座多人。([allgodot.com][5])

你应该重点研究它的：

* Godot 4 项目结构
* 战棋地图编辑器
* 回合流程
* AI 基础
* 多方势力
* 战役组织
* 等距地图表达

它偏 Advance Wars，不是 RPG，但对 Godot SRPG 的工程落地很有参考价值。

---

## 6. Athena Crisis：学“现代战棋数据模型 + 编辑器 + AI”

**定位：现代 Web 战棋架构参考。**

Athena Crisis 是 open-core 项目，仓库开源了超过 10 万行非内容代码，包括核心数据结构、算法、游戏引擎、渲染、AI、地图编辑器；但单人战役、多人、艺术、音乐和内容不是开源。([GitHub][6])

你应该重点研究它的：

* 地图编辑器
* 战棋数据结构
* AI 行为
* 单元测试
* 回放 / 状态同步思路
* 前端 UI 与游戏状态分离

它不适合作为主工程，因为它是 open-core，内容不完整；但非常适合研究 **现代战棋工程抽象**。

---

# 四、最终组合结构

## 推荐组合

| 层级       | 项目                                | 作用                            |
| -------- | --------------------------------- | ----------------------------- |
| 主工程      | **Godot 4 自研项目**                  | 真正落地自己的中文 SRPG                |
| 规则蓝本     | **Lex Talionis**                  | 火纹式关卡、单位、职业、技能、事件、编辑器         |
| RPG 深度   | **Sulis**                         | 数据驱动 RPG、技能、装备、剧情、Lua/YAML 扩展 |
| 内容工程     | **Battle for Wesnoth**            | 大型战役、地图编辑器、Mod、阵营、单位升级        |
| 基础原型     | **GDQuest Tactical RPG Movement** | 格子移动、路径、光标、行动范围               |
| Godot 参考 | **Tanks of Freedom II**           | Godot 4 战棋工程、地图编辑器、战役         |
| 现代架构     | **Athena Crisis**                 | 数据模型、AI、编辑器、状态管理、测试           |

---

# 五、不建议放进核心组合的项目

## OpenXcom

OpenXcom 很强，但它是 X-COM 重实现，需要原版资源，方向是“基地经营 + 小队战术 + 外星人入侵”，不是传统 SRPG。适合后期研究命中率、装备、掩体、士兵成长，但不适合作为第一阶段核心。([GitHub][7])

## VCMI / fheroes2

这类更偏《英雄无敌》：大地图探索、城镇、资源、英雄、兵种堆叠、战场回合制。它们很有价值，但会把你的设计拉向 4X / SLG，不适合作为火纹/FFT 类 SRPG 的核心。

## Silent Storm

适合研究 3D 战术、掩体、破坏、射线、命中率，但过重。除非你明确要做 XCOM 式 3D 小队战术，否则不放核心组合。

## Emblem Forge

Unity 框架有参考价值，但如果你主路线选 Godot，就只作为概念参考，不应该进入主组合。否则会造成 Unity/Godot 双栈分裂。

---

# 六、最合理的学习顺序

## 阶段 1：先做最小 SRPG 原型

参考：

> **GDQuest Tactical RPG Movement + Tanks of Freedom II**

目标只做：

* 地图
* 光标
* 选中单位
* 移动范围
* 路径预览
* 移动
* 回合切换
* 简单攻击
* 简单敌方 AI

不要一开始做职业、剧情、装备、技能树。

---

## 阶段 2：补火纹式 SRPG 规则

参考：

> **Lex Talionis**

加入：

* 职业
* 等级
* 成长率
* 武器类型
* 命中 / 闪避 / 暴击
* 伤害预测
* 技能
* 状态
* 关卡事件
* 胜败条件
* 出击准备

---

## 阶段 3：补 RPG 深度

参考：

> **Sulis**

加入：

* 装备词条
* 主动技能
* 被动技能
* Buff / Debuff
* 道具系统
* 对话系统
* 任务系统
* 角色 Build
* 数据驱动配置

---

## 阶段 4：补大型内容与 Mod

参考：

> **Battle for Wesnoth + Athena Crisis**

加入：

* 地图编辑器
* 章节编辑器
* 战役编辑器
* 剧情节点
* 多阵营
* AI 策略
* 内容包加载
* Mod 规范
* 回放 / 测试 / 战斗日志

---

# 七、最终建议

最合理的一套组合不是：

> jynew + 一堆 SRPG 项目

而是：

> **Godot 4 自研主工程 + Lex Talionis 规则体系 + Sulis 数据驱动 RPG + Wesnoth 内容工程 + Tanks of Freedom II / GDQuest 的 Godot 战棋基础 + Athena Crisis 的现代数据架构**

一句话概括：

> **用 Godot 4 做自己的主工程；用 Lex Talionis 定义 SRPG 玩法；用 Sulis 定义 RPG 数据层；用 Wesnoth 定义战役和 Mod 体系；用 Tanks/GDQuest 落地 Godot 战棋基础；用 Athena Crisis 学现代状态管理和编辑器架构。**

[1]: https://lex-talionis.net/?utm_source=chatgpt.com "Lex Talionis"
[2]: https://www.sulisgame.com/?utm_source=chatgpt.com "Home - Sulis"
[3]: https://github.com/wesnoth/wesnoth?utm_source=chatgpt.com "GitHub - wesnoth/wesnoth: An open source, turn-based strategy game with a high fantasy theme."
[4]: https://github.com/gdquest-demos/godot-2d-tactical-rpg-movement?utm_source=chatgpt.com "GitHub - gdquest-demos/godot-2d-tactical-rpg-movement: Grid-based movement for a Tactical RPG"
[5]: https://allgodot.com/godot/tanks-of-freedom-ii?utm_source=chatgpt.com "Tanks of Freedom II | All Godot"
[6]: https://github.com/nkzw-tech/athena-crisis?utm_source=chatgpt.com "GitHub - nkzw-tech/athena-crisis: Athena Crisis is a modern-retro turn-based tactical strategy game. Athena Crisis is open core technology."
[7]: https://github.com/OpenXcom/OpenXcom?utm_source=chatgpt.com "GitHub - OpenXcom/OpenXcom: Open-source clone of the original X-Com 👽"
