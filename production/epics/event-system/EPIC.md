# Epic: Event System

> **Status**: Planning
> **Created**: 2026-05-02
> **GDD**: `design/gdd/event-system.md`
> **System**: event
> **Layer**: Narrative
> **Priority**: Alpha

## Scope

叙事事件触发框架 — 条件检测 → 事件触发 → 对话/选择 → 奖励/后果。与信念值系统、羁绊系统、章节推进互锁。

## Stories (TBD)

| # | Story | Type | Est. | Status |
|---|-------|------|------|--------|
| 001 | Event data model (条件+触发+后果) | Logic | 0.5d | pending |
| 002 | Event trigger engine (故事进度监听) | Logic | 0.5d | pending |
| 003 | Dialogue UI (对话+选项) | UI | 0.5d | pending |
| 004 | Event persistence (已完成事件记录) | Integration | 0.25d | pending |

## GDD Requirements

- Event trigger conditions (story flag / bond level / belief value / chapter)
- Event consequences (gain item / change belief / unlock bond dialogue / progress story)
- Event persistence through save/load

## Out of Scope (MVP)

- Complex branching dialogue trees
- Animated event cutscenes
- Voice-over integration
