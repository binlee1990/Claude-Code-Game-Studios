# Story 004: Position Scoring

> **Epic**: AI System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: C.6 (position selection algorithm), D.3 (position score formula)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-P1: AI evaluates all reachable cells and selects highest-scoring position
- [ ] AC-P2: Height advantage scoring: high=1.2, plain=1.0, low=0.8
- [ ] AC-P3: Element terrain scoring: dangerous element=0.5, normal=1.0
- [ ] AC-P4: Support range scoring: in ally heal range=1.2, otherwise=1.0
- [ ] AC-P5: When no reachable position is better than current, AI stays

---

## Implementation Notes

From GDD C.6: Position selection: (1) get all reachable cells, (2) evaluate each by distance/height/element/support, (3) weight by AI type, (4) pick highest score. From D.3: `position_score = distance_score × height_score × element_score × support_score`. distance_score ∈ [0.0, 1.0] (closer = higher). height_score ∈ {0.8, 1.0, 1.2}. element_score ∈ {0.5, 1.0}. support_score ∈ {0.8, 1.2}. From E.4: No reachable safe position → stay or move to nearest useful position. From E.7: AI avoids standing on hazardous element terrain when possible.

---

## Out of Scope

- Target selection (Story 003)
- Boss AI (Story 005)
- Movement animation/visual feedback

---

## QA Test Cases

- **AC-P1**: Best position selection
  - Given: 5 reachable cells with scores {0.5, 0.8, 1.2, 0.3, 0.9}
  - When: AI selects position
  - Then: Selects cell with score 1.2

- **AC-P2**: Height scoring
  - Given: High position (height=2) vs low position (height=0), equal other factors
  - When: Position scores calculated
  - Then: High = 1.2 multiplier, Low = 0.8 multiplier

- **AC-P3**: Element terrain avoidance
  - Given: Cell on oil stain (dangerous) vs normal cell, equal other factors
  - When: Position scores calculated
  - Then: Oil stain = 0.5 multiplier, Normal = 1.0 multiplier

- **AC-P4**: Support range bonus
  - Given: Cell in ally healer range vs cell outside, equal other factors
  - When: Position scores calculated
  - Then: In range = 1.2 multiplier, Outside = 1.0 multiplier

- **AC-P5**: Stay in place
  - Given: All reachable cells score lower than current position
  - When: AI evaluates movement
  - Then: AI stays at current position
  - Edge cases: Only current cell reachable → stay

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/position_scoring_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (target needed for distance calculation)
- Unlocks: Story 005 (Boss AI uses position scoring)
- Cross-epic: Tactical Mechanism Stories 001, 003 (terrain data, height values)
