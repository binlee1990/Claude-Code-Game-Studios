# Sprint-004 Management Interface Beta + Base System MVP Evidence

**Story ID**: MGMT-006
**Sprint**: Sprint-004
**Date**: 2026-04-26
**Gate Level**: ADVISORY (UI/Visual evidence)
**Status**: PENDING — sprint implementation not yet complete

---

## Scope

This document catalogs all UI/screens that require manual visual verification for Sprint-004's two deliverables:

1. **Management Interface Beta** — character management + equipment management with Tab switching
2. **Base System MVP** — training ground + market accessible from base hub

---

## Feature Screenshots Checklist

| # | Feature | Screen / Element | Verification Method | Priority |
|---|---------|------------------|---------------------|----------|
| 1 | Base entry from main menu | Main menu scene — base button visible and clickable | Screenshot + interaction test | Must Have |
| 2 | Base entry from settlement | Post-battle settlement screen — base button visible and clickable | Screenshot + interaction test | Must Have |
| 3 | Base hub main interface | Base scene with Tab navigation (training ground / market) | Screenshot of each Tab | Must Have |
| 4 | Management interface — Tab switching | Character tab and Equipment tab switch without data loss | Screenshot each Tab | Must Have |
| 5 | Character management — roster list | List of characters with formation order | Screenshot | Must Have |
| 6 | Character management — formation adjustment | Drag or button to reorder formation | Screenshot before/after | Must Have |
| 7 | Character management — character detail | Individual character stats view | Screenshot | Must Have |
| 8 | Equipment management — equipment list | All equipment items visible with equipped state | Screenshot | Must Have |
| 9 | Equipment management — equip/unequip | Swap equipment on a character | Screenshot before/after | Must Have |
| 10 | Training ground — skill proficiency view | Character skill proficiency displayed correctly | Screenshot | Should Have |
| 11 | Market — buy interface | Items listed with prices, purchase flow | Screenshot | Should Have |
| 12 | Market — sell interface | Items listed with sell prices, sell flow | Screenshot | Should Have |

---

## Manual Screenshot Verification Instructions

For each Must Have item, capture a screenshot after performing the described interaction.

**Environment**: Windows 11, Godot 4.6.2, exported build or editor play

**Session flow to verify end-to-end**:

```
Main Menu
  └─> [Base Button] --> Base Hub (Training Ground Tab default)
                        └─> [Equipment Tab] --> Management Interface
                                                ├─> [Character Tab]
                                                │    └─> Select character --> Character Detail
                                                └─> [Equipment Tab]
                                                     └─> Select loadout --> Equip/Unequip
                        └─> [Training Ground Tab]
                        └─> [Market Tab]
                             ├─> Buy item
                             └─> Sell item
  └─> [Continue] --> Chapter --> Battle --> Victory
                                         └─> [Base Button on Settlement]
```

---

## Smoke Test Criteria (ADVISORY)

These are the 10-15 critical path scenarios. A full smoke pass is required before marking Sprint-004 complete.

### Entry Points
- [ ] Main menu shows base entry button
- [ ] Post-battle settlement shows base entry button

### Management Interface
- [ ] Tab switching between Character and Equipment preserves state
- [ ] Character roster renders with correct formation order
- [ ] Character detail shows correct stats
- [ ] Equipment list shows all items with equipped/unequipped state
- [ ] Equip action updates character stats and persists after tab switch
- [ ] Unequip action returns item to inventory

### Base System MVP
- [ ] Training ground Tab displays character skill proficiencies
- [ ] Market Tab displays buyable items with prices
- [ ] Market buy flow deducts gold and adds item to inventory
- [ ] Market sell flow adds gold and removes item from inventory

### Persistence
- [ ] Formation changes persist after exiting management interface
- [ ] Equipment changes persist after exiting management interface
- [ ] Gold changes persist after market transactions
- [ ] Save/load cycle preserves all above state

---

## Evidence Collection

Screenshots should be saved to: `production/qa/evidence/screenshots/sprint-004/`

Naming convention: `{date}_{feature}_{action}.png`

Example: `2026-05-01_base_hub_training_ground.png`

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | | | |
| UI Programmer | | | |
| Gameplay Programmer | | | |

---

## Notes

- MGMT-006 is a blocking gate only for the Nice-to-Have column of Sprint-004
- This evidence file must exist before the sprint can be marked Done
- Screenshots are ADVISORY only — functional behavior is verified via smoke test checklist above
