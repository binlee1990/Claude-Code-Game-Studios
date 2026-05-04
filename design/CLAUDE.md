# Design Directory

When authoring or editing files in this directory, follow these standards.

## GDD Files (`design/gdd/`)

Every GDD must include all **8 required sections** in this order:
1. Overview — one-paragraph summary
2. Player Fantasy — intended feeling and experience
3. Detailed Rules — unambiguous mechanics
4. Formulas — all math defined with variables
5. Edge Cases — unusual situations handled
6. Dependencies — other systems listed
7. Tuning Knobs — configurable values identified
8. Acceptance Criteria — testable success conditions

**File naming:** `[system-slug].md` (e.g. `movement-system.md`, `combat-system.md`)

**Systems index:** `design/gdd/systems-index.md` — update when adding a new GDD.

**Design order:** Foundation → Core → Feature → Presentation → Polish

**Validation:** Run `/design-review [path]` after authoring any GDD.
Run `/review-all-gdds` after completing a set of related GDDs.

## Quick Specs (`design/quick-specs/`)

Lightweight specs for tuning changes, minor mechanics, or balance adjustments.
Use `/quick-design` to author.

## UX Specs (`design/ux/`)

- Per-screen specs: `design/ux/[screen-name].md`
- HUD design: `design/ux/hud.md`
- Interaction pattern library: `design/ux/interaction-patterns.md`

Use `/ux-design` to author. Validate with `/ux-review` before passing to `/team-ui`.

## Accessibility Requirements (`design/`)

- **Path**: `design/accessibility-requirements.md`（项目根 `design/` 下，**不在** `design/ux/` 子目录）
- 与 `gate-check` skill 的 Required Artifact 路径保持一致
- 包含 tier 承诺、特性表、已知限制、跨节引用 art-bible Sec 4.6 的色弱矩阵
- 单屏的 accessibility 注释仍写在各 `design/ux/[screen].md` 内，但项目级承诺写本文件
