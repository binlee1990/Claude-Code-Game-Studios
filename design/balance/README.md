# Balance Data Index

> **Created**: 2026-05-02
> **Scope**: AI-verifiable balance artifacts and tuning ownership.

## Current Balance Sources

| Domain | Source | Status |
|---|---|---|
| Difficulty curve | `assets/data/difficulty/phase_curve.json` | Active |
| Base upgrade costs | `assets/data/economy/base-upgrade-costs.json` | Active |
| Equipment enhancement costs | `src/core/resource/resource_formulas.gd` | Active |
| Equipment success rates | `src/core/equipment/equipment_definitions.gd` | Active |
| Battle definitions | `src/ui/combat/battle_definitions/*.json` | Active |

## Open Balance Work

| Area | Owner | Notes |
|---|---|---|
| Performance-scale fog tuning | Sprint-011 | Needs larger-grid perf runs |
| Ch.2 cultivation relief | Human playtest + agent analysis | Depends on MAN-004/MAN-005 |
| +11+ enhancement feel | Human playtest + automated logs | Automated rules complete; subjective fairness pending |

## Rule

Concrete numeric tables should move to `assets/data/` when they become content-authored data. Code constants remain acceptable for small closed formulas covered by tests.
