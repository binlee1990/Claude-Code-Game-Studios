# Epic: Chapter 04

> **Status**: Planning
> **Created**: 2026-05-02
> **GDD**: Not yet created (needs `/design-system chapter-04`)
> **System**: chapter-04
> **Layer**: Content
> **Priority**: Alpha

## Scope

Ch.4 内容 — GDD + epic stories + battle definitions (JSON)。延续 Ch.3 信念值分叉结果，难度进入挑战期(1.2×)。

## Prerequisites

- [ ] Create `design/gdd/chapter-04.md` via `/design-system`
- [ ] Create battle definition JSONs (3 battles typical)
- [ ] Create story files under `production/epics/chapter-04/`

## Stories (TBD — after GDD)

Typical chapter structure:
| # | Story | Type | Est. |
|---|-------|------|------|
| 001 | Ch.4 GDD | Design | 0.5d |
| 002 | Battle definitions (act_a / act_b / finale) | Config | 0.5d |
| 003 | Battle 1 implementation | Content | 1d |
| 004 | B4-GATE (信念值分叉) | Logic | 0.5d |
| 005 | Battle 2 implementation | Content | 1d |
| 006 | Finale implementation | Content | 1d |

## Difficulty Context

Ch.4 falls into Phase 3 (Challenge, enemy_stat_mult=1.2×). DifficultyManager already provides correct scaling for chapter 4-5.
