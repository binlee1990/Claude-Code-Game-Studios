# Story 2-2 Visual Evidence

**Story**: Unit Scene — 场景结构 + 视觉
**Type**: Visual/Feel
**Status**: Pending Godot editor verification

## Verification Checklist

在 Godot 编辑器中打开项目后，逐项验证：

- [ ] **AC-C4 场景结构**: 打开 `src/unit/Unit.tscn`，场景树根节点为 Node2D，含两个子节点：ColorRect (48×48) 和 Label
- [ ] **AC-C2 阵营颜色**: PLAYER Unit ColorRect 为蓝色 (#3B82F6)，ENEMY Unit ColorRect 为红色 (#EF4444)
- [ ] **HP 标签**: Label 显示 "HP: 10/10"，位于单位中心上方
- [ ] **AC-C9 行动状态**: 未行动单位完整颜色+完整不透明度；已行动单位去饱和 (Color.GRAY, 50% 透明度)
- [ ] **AC-C5 实例隔离**: 两个 Unit 共享同一 soldier.tres，Unit A 受伤后 Unit B hp 不变

## 截图证据

> 在 Godot 编辑器中运行 `src/Game.tscn` 主场景后，截图粘贴于此。

D:\work\Games\SRPG_MINI\production\qa\evidence\story-2-2\image.png

## Sign-off

- [ ] Visual lead review
- [ ] Date:
