# UI / Input

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 1 — Data-Driven (UI reads state, doesn't embed values); Pillar 2 — System Orthogonality (Presentation layer aggregates upstream data without owning game logic)

## Overview

UI / Input 是 SRPG 骨架的**表现层**——玩家与游戏之间唯一的界面。它接收所有鼠标输入（点击单位、点击目标瓦片、悬停预览、Escape 取消、End Turn 按钮），并将 7 个底层系统的状态渲染为可见的视觉元素：蓝/红色的单位几何图形（方=玩家，圆=敌方）带 HP 标签、蓝色移动范围高亮、青色路径预览、红色攻击目标高亮、琥珀色伤害预览数字、回合指示器和 End Turn 按钮、以及绿/红/灰的胜/负/平局画面。UI 系统**不拥有任何游戏逻辑**——它读取上游系统的数据（Map 的瓦片状态、Unit 的属性、Turn 的回合数、Movement 的可达瓦片、Attack 的目标列表和伤害值、Victory 的胜负判定、AI 的 ActionList），并将其转换为 Control 节点树。所有视觉元素均为 code-drawn（Godot 内置 ColorRect / Polygon2D / Label / StyleBoxFlat），与 Programmer Art Functional 的零纹理、零图标、零动画立场一致。没有 UI 系统，游戏仍然在运行——单位仍然有 HP、BFS 仍然在计算、Turn 仍然在轮转——但玩家什么都看不见，什么都点不了。UI 让棋盘**可见**，让决策**可操作**。

## Player Fantasy

[To be designed]

## Detailed Design

### Core Rules

[To be designed]

### Input Handling

[To be designed]

### Screen Flow

[To be designed]

### Visual Elements

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
