# Epic: Boss System

> **Status**: Sprint-009 Planning
> **Created**: 2026-05-01
> **GDD**: `design/gdd/boss-system.md`
> **ADR**: `docs/architecture/ADR-013-boss-system.md`
> **System**: boss
> **Layer**: Feature
> **Priority**: Vertical Slice

## Scope

实现 Boss 系统数据模型（5 类型分类 + 检查点规范 + 失败恢复策略）+ Boss action pattern 数据模型（telegraph 前兆 + range indicator + cooldown）。阶段切换逻辑和检查点系统推至后续实现 story。

## Stories

| # | Story | Type | Est. | Status |
|---|-------|------|------|--------|
| 001 | Boss 系统 Epic 创建 + 数据模型 | Design/Logic | 0.5d | pending |
| 002 | Boss action pattern 数据模型 | Logic | 0.5d | pending |

## Out of Scope

- Boss 阶段切换 runtime 实现
- Boss 检查点持久化
- Boss telegraph 正式视觉资产（MVP 用几何占位）
- Boss 专属 AI 策略 runtime

## GDD Requirements

- TR-boss-001: Boss type classification (5 types) + checkpoint spec
- TR-boss-002: Boss action pattern: telegraph + range indicator + cooldown
