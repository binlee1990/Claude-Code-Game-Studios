# Story BOND-001: Bond Data Model + Save Payload

> **Epic**: Bond System MVP
> **Status**: Ready
> **Type**: Logic

## Acceptance Criteria

- [ ] Bond pair key is stable across save/load.
- [ ] Affinity value, support rank, and bond type serialize into SaveData.
- [ ] Missing bond data in old saves defaults to an empty bond registry.
- [ ] Unit tests cover creation, update, rank threshold, and deserialize.

## Notes

Use `design/gdd/bond-system.md` thresholds as initial constants. Do not implement combo skills in this story.
