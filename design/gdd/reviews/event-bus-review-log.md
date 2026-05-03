# Review Log: 事件总线 (Event Bus)

## Review — 2026-05-03 — Verdict: NEEDS REVISION

Scope signal: S
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-gdscript-specialist
Blocking items: 3 | Recommended: 8 | Nice-to-have: 3

### Summary

EventBus GDD 结构完整（8/8），设计理念优秀，Player Fantasy 与修仙世界观精准连接。但存在 3 个阻塞性问题：(1) GDScript 无 try/catch，Core Rule 8 错误隔离机制不可实现；(2) Dependencies 表与 Interactions 表不一致，遗漏时间管理器、等级系统、掉落系统；(3) 高频事件无节流/合并机制，与 Player Fantasy "因果有序呈现"承诺矛盾。

### Blocking Items

1. **[godot-gdscript-specialist] GDScript 无 try/catch — 错误隔离不可实现**  
   Core Rule 8 声明捕获异常继续投递，GDScript 无此能力。需替代方案。

2. **[systems-designer] Dependencies 表不完整**  
   Interactions 表列出 time-manager/level/loot 系统，Dependencies 表遗漏。

3. **[performance-analyst] [game-designer] 高频事件无节流机制**  
   resource.lingqi.changed 每秒 60 次，无合并策略。与 Player Fantasy 因果序承诺矛盾。

### Key Recommended Items

4. Dictionary payload 引用传递风险 — 需明确禁止修改或声明深拷贝
5. Non-Node 订阅者生命周期未定义
6. Callable.bind() 相等性边界情况需文档化
7. Autoload 初始化顺序约束需明确
8. Player Fantasy "因果顺序"措辞需弱化或声明无序保证
9. 性能 AC 非确定性 — 需改为可复现断言
10. 缺失 3 个 AC（事件名拼写错误、debug off 零开销、错误注入方式）
11. Formula 3 极端值退化为 3 个订阅者 — 需说明

Prior verdict resolved: First review
