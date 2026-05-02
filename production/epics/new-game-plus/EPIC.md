# Epic: New Game Plus

> **Status**: Planning
> **Created**: 2026-05-02
> **GDD**: `design/gdd/new-game-plus-system.md`
> **System**: new-game-plus
> **Layer**: Meta
> **Priority**: Alpha

## Scope

多周目系统 — 一周目完成后获得成就点数 → 兑换 NG+ 开关（难度倍率/继承内容）。DifficultyManager 已预留 `_ng_multiplier` 扩展点。

## Stories (TBD)

| # | Story | Type | Est. | Status |
|---|-------|------|------|--------|
| 001 | Achievement points data model + award | Logic | 0.5d | pending |
| 002 | NG+ difficulty selection UI (1×/2×/4×/8×/16×) | UI | 0.5d | pending |
| 003 | NG+ carry-over logic (继承内容选择) | Logic | 0.5d | pending |
| 004 | NG+ save/load (周目计数持久化) | Integration | 0.25d | pending |

## GDD Requirements

- Achievement points awarded based on Ch.1-10 completion
- NG+ difficulty multipliers: 2× (100pts), 4× (300pts), 8× (600pts), 16× (1000pts)
- Difficulty multiplier feeds into DifficultyManager._ng_multiplier
- Carry-over options: retain equipment / retain bond levels / retain class exp

## Integration Points

- DifficultyManager: `_ng_multiplier` field (already reserved)
- SaveData: `achievement_points` field (already exists)
- Main menu: NG+ start flow (after MainMenu "New Game+")
