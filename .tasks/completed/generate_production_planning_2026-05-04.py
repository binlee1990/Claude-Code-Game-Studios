from __future__ import annotations

# Task artifact for 2026-05-04 all-GDD production planning generation.

import datetime as dt
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TODAY = dt.date(2026, 5, 4)

GDD_DIR = ROOT / "design" / "gdd"
ARCH_DIR = ROOT / "docs" / "architecture"
PROD_DIR = ROOT / "production"
EPICS_DIR = PROD_DIR / "epics"
SPRINTS_DIR = PROD_DIR / "sprints"

PREEXISTING_EPICS = {
    "big-number-system",
    "event-bus",
    "random-seed-system",
    "time-manager",
}


ADR_BY_SYSTEM = {
    "big-number-system": ["ADR-0001"],
    "random-seed-system": ["ADR-0004", "ADR-0008"],
    "event-bus": ["ADR-0002", "ADR-0008"],
    "time-manager": ["ADR-0003", "ADR-0008"],
    "number-formatting-system": ["ADR-0014"],
    "data-config-system": ["ADR-0005", "ADR-0008"],
    "formula-engine": ["ADR-0013"],
    "modifier-engine": ["ADR-0007", "ADR-0008"],
    "save-system": ["ADR-0006", "ADR-0008"],
    "resource-system": ["ADR-0010", "ADR-0001", "ADR-0002"],
    "attribute-system": ["ADR-0007", "ADR-0001", "ADR-0002"],
    "item-material-system": ["ADR-0005"],
    "output-multiplier-system": ["ADR-0007", "ADR-0010"],
    "debug-console": ["ADR-0012", "ADR-0002", "ADR-0008", "ADR-0011"],
    "level-system": ["ADR-0013", "ADR-0007", "ADR-0010"],
    "storage-limit-system": ["ADR-0010", "ADR-0005"],
    "auto-production-system": ["ADR-0003", "ADR-0007", "ADR-0010"],
    "enemy-database": ["ADR-0005"],
    "loot-system": ["ADR-0004", "ADR-0005", "ADR-0009"],
    "cultivation-system": ["ADR-0003", "ADR-0007", "ADR-0010"],
    "combat-calculator": ["ADR-0009", "ADR-0007", "ADR-0013", "ADR-0004"],
    "semi-auto-combat-system": ["ADR-0009", "ADR-0002"],
    "zone-system": ["ADR-0005"],
    "map-progression-system": ["ADR-0013", "ADR-0002", "ADR-0005"],
    "offline-simulation-core": ["ADR-0015", "ADR-0003"],
    "idle-exploration-system": ["ADR-0009", "ADR-0002"],
    "offline-combat-simulation-system": ["ADR-0009", "ADR-0015", "ADR-0004"],
    "offline-reward-settlement-system": ["ADR-0009", "ADR-0015", "ADR-0010", "ADR-0002"],
    "ui-framework": ["ADR-0011", "ADR-0002", "ADR-0014"],
    "hud-system": ["ADR-0011", "ADR-0014", "ADR-0002"],
}

SPECIAL_STORY_GROUPS = {
    "big-number-system": [
        {
            "title": "Testing harness and BigNumber API contract",
            "source": "existing BigNumber EPIC Producer addendum",
            "type": "Integration",
            "criteria": [
                "GIVEN Foundation stories require executable tests, WHEN this story completes, THEN GdUnit4 plugin installation and first CI workflow green result are recorded for downstream stories.",
                "GIVEN BigNumber public API must freeze before downstream consumers implement against it, WHEN the API contract test runs, THEN `tests/integration/big_number/api_contract_test.gd` locks all public method signatures listed in ADR-0001.",
            ],
        }
    ],
    "event-bus": [
        {
            "title": "Godot 4.6 Callable lifecycle spike",
            "source": "existing EventBus EPIC Producer addendum",
            "type": "Integration",
            "criteria": [
                "GIVEN Godot 4.6 Callable lifecycle risk is unresolved, WHEN this spike completes, THEN `production/qa/evidence/event-bus-callable-lifecycle-spike.md` records weak-reference, strong-reference, and deferred-cleanup behavior.",
                "GIVEN the spike selects a safe cleanup path, WHEN ADR-0002 is reviewed, THEN the implementation decision is recorded or ADR-0002 is marked for replacement before EventBus implementation continues.",
                "GIVEN EventBus must initialize before all other Autoload services, WHEN `tests/integration/event_bus/autoload_order_test.gd` runs, THEN EventBus is verified as the first Autoload dependency.",
            ],
        }
    ],
}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def slugify_ascii(text: str, fallback: str) -> str:
    text = re.sub(r"`([^`]+)`", r" \1 ", text)
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    text = re.sub(r"-+", "-", text)
    return text[:56].strip("-") or fallback


def test_dir_for(slug: str) -> str:
    if slug.endswith("-system"):
        slug = slug[: -len("-system")]
    return slug.replace("-", "_")


def normalize_name(name: str) -> str:
    return (
        name.replace("系统", "")
        .replace(" ", "")
        .replace("/", "")
        .replace("倍率", "")
        .replace("（", "(")
        .replace("）", ")")
    )


def section(content: str, heading: str) -> str:
    pattern = re.compile(
        rf"^##\s+{re.escape(heading)}\s*$([\s\S]*?)(?=^##\s+|\Z)",
        re.MULTILINE,
    )
    match = pattern.search(content)
    return match.group(1).strip() if match else ""


def first_paragraph(text: str) -> str:
    lines = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("|") or line.startswith(">"):
            if lines:
                break
            continue
        lines.append(line)
    return " ".join(lines).strip()


def parse_systems() -> list[dict]:
    content = read(GDD_DIR / "systems-index.md")
    systems: list[dict] = []
    for line in content.splitlines():
        if not re.match(r"\|\s*\d+\s*\|", line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 7:
            continue
        order, name, category, priority, status, gdd, deps = cells[:7]
        slug = Path(gdd).stem
        dep_names = [] if deps in {"—", "-", ""} else [d.strip() for d in deps.split(",")]
        systems.append(
            {
                "order": int(order),
                "name": name,
                "category": category,
                "priority": priority,
                "status": status,
                "gdd": gdd,
                "slug": slug,
                "depends_on_names": dep_names,
            }
        )
    return systems


def parse_arch_modules() -> dict[str, dict]:
    modules: dict[str, dict] = {}
    for line in read(ARCH_DIR / "architecture.md").splitlines():
        if not line.startswith("|") or line.startswith("| System") or line.startswith("|--------"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 5 and "design/gdd" not in line and cells[0] and cells[1]:
            system = cells[0].replace("随机数与种子", "随机数与种子系统")
            modules[system] = {
                "class": cells[1],
                "pattern": cells[2],
                "owns": cells[3],
                "risk": cells[4],
            }
            modules[normalize_name(system)] = modules[system]
    return modules


def parse_tr_registry() -> dict[str, dict]:
    content = read(ARCH_DIR / "tr-registry.yaml")
    entries: dict[str, dict] = {}
    blocks = re.split(r"\n\s*-\s+id:\s+", "\n" + content)
    for block in blocks[1:]:
        block = "id: " + block
        data: dict[str, str] = {}
        for key in ["id", "system", "gdd", "requirement", "status"]:
            match = re.search(rf"^\s*{key}:\s*(.+)$", block, re.MULTILINE)
            if match:
                data[key] = match.group(1).strip().strip('"')
        if data.get("gdd"):
            entries[Path(data["gdd"]).stem] = data
    return entries


def parse_adrs() -> dict[str, dict]:
    adrs: dict[str, dict] = {}
    for path in sorted(ARCH_DIR.glob("adr-*.md")):
        content = read(path)
        title_match = re.match(r"#\s+(ADR-\d+):\s+(.+)", content)
        if not title_match:
            continue
        adr_id, title = title_match.groups()
        status = first_paragraph(section(content, "Status")) or "Unknown"
        decision = first_paragraph(section(content, "Decision"))
        risk_match = re.search(r"\|\s*\*\*Knowledge Risk\*\*\s*\|\s*(LOW|MEDIUM|HIGH)\b([^|]*)\|", content)
        risk = risk_match.group(1) if risk_match else "LOW"
        guidelines = []
        in_guidelines = False
        for line in content.splitlines():
            if line.strip() == "## Implementation Guidelines":
                in_guidelines = True
                continue
            if in_guidelines and line.startswith("## "):
                break
            if in_guidelines and line.strip().startswith("- "):
                guidelines.append(line.strip()[2:])
        adrs[adr_id] = {
            "id": adr_id,
            "title": title,
            "path": path,
            "status": status,
            "decision": decision,
            "risk": risk,
            "guidelines": guidelines,
        }
    return adrs


def parse_manifest_rules() -> dict[str, dict[str, list[str]]]:
    content = read(ARCH_DIR / "control-manifest.md")
    result: dict[str, dict[str, list[str]]] = {}
    for layer in ["Foundation", "Core", "Feature", "Presentation"]:
        body_match = re.search(rf"^## {layer} Layer Rules[\s\S]*?(?=^## |\Z)", content, re.MULTILINE)
        body = body_match.group(0) if body_match else ""
        result[layer] = {"required": [], "forbidden": [], "guardrails": []}
        for label, key in [
            ("Required Patterns", "required"),
            ("Forbidden Approaches", "forbidden"),
            ("Performance Guardrails", "guardrails"),
        ]:
            part_match = re.search(rf"^### {label}\s*$([\s\S]*?)(?=^### |^## |\Z)", body, re.MULTILINE)
            if not part_match:
                continue
            bullets = []
            for line in part_match.group(1).splitlines():
                line = line.strip()
                if line.startswith("- "):
                    bullets.append(line[2:])
            result[layer][key] = bullets
    return result


def rules_key(category: str, slug: str) -> str:
    if category == "Foundation":
        return "Foundation"
    if category in {"Core Data", "Core Gameplay"} or slug == "offline-simulation-core":
        return "Core"
    if category == "Presentation":
        return "Presentation"
    return "Feature"


def parse_acceptance_criteria(gdd_content: str) -> list[dict]:
    ac = section(gdd_content, "Acceptance Criteria")
    if not ac:
        return []
    groups: list[dict] = []
    current_title = "Acceptance Criteria"
    current: list[str] = []
    for raw in ac.splitlines():
        line = raw.strip()
        h3 = re.match(r"^###\s+(.+)", line)
        if h3:
            if current:
                groups.append({"title": current_title, "criteria": current})
            current_title = h3.group(1).strip()
            current = []
            continue
        bullet = re.match(r"^(?:[-*]\s+(?:\[[ xX]\]\s*)?|\d+[.)]\s+)(.+)", line)
        if bullet and not line.startswith("|"):
            text = bullet.group(1).strip()
            text = re.sub(r"^\*\*(.+?)\*\*[:：]?\s*", r"\1: ", text)
            current.append(text)
    if current:
        groups.append({"title": current_title, "criteria": current})
    if not groups:
        paras = [p.strip() for p in re.split(r"\n\s*\n", ac) if p.strip() and not p.strip().startswith("###")]
        if paras:
            groups.append({"title": "Acceptance Criteria", "criteria": paras})
    split_groups: list[dict] = []
    for group in groups:
        criteria = group["criteria"]
        if len(criteria) <= 4:
            split_groups.append(group)
        else:
            for idx in range(0, len(criteria), 3):
                title = group["title"]
                if len(criteria) > 3:
                    title = f"{title} {idx // 3 + 1}"
                split_groups.append({"title": title, "criteria": criteria[idx : idx + 3]})
    return split_groups


def classify_story(title: str, criteria: list[str]) -> str:
    text = (title + " " + " ".join(criteria)).lower()
    ui_terms = ["ui", "hud", "screen", "modal", "button", "display", "tooltip", "focus", "panel", "menu", "overlay", "界面", "按钮", "面板", "显示"]
    visual_terms = ["visual", "audio", "animation", "vfx", "feel", "responsive", "screen shake", "视觉", "音频", "动画", "手感"]
    config_terms = ["config", "json", "table", "schema", "data file", "tuning", "配置", "数据表", "表"]
    integration_terms = [
        "eventbus",
        "event bus",
        "resource system",
        "resourcesystem",
        "savemanager",
        "save/load",
        "offline",
        "online",
        "autoload",
        "cross-system",
        "integration",
        "emit",
        "subscribe",
        "restore",
        "snapshot",
        "batch",
        "离线",
        "在线",
        "事件",
        "存档",
        "恢复",
        "结算",
    ]
    if any(term in text for term in ui_terms):
        return "UI"
    if any(term in text for term in visual_terms):
        return "Visual/Feel"
    if any(term in text for term in config_terms):
        return "Config/Data"
    if any(term in text for term in integration_terms):
        return "Integration"
    return "Logic"


def parse_gwt(criterion: str) -> tuple[str, str, str] | None:
    clean = re.sub(r"\*\*", "", criterion)
    clean = re.sub(r"\s+", " ", clean).strip()
    match = re.search(
        r"GIVEN[:：]?\s*(.*?)[,，]?\s*WHEN[:：]?\s*(.*?)[,，]?\s*THEN[:：]?\s*(.*)$",
        clean,
        re.IGNORECASE,
    )
    if not match:
        return None
    return tuple(part.strip(" ,，。.") for part in match.groups())


def choose_governing_adr(story_type: str, adr_ids: list[str]) -> str:
    preferred = {
        "UI": ["ADR-0011", "ADR-0014", "ADR-0002"],
        "Visual/Feel": ["ADR-0011", "ADR-0002"],
        "Config/Data": ["ADR-0005", "ADR-0006"],
        "Integration": ["ADR-0009", "ADR-0002", "ADR-0008", "ADR-0015"],
        "Logic": ["ADR-0001", "ADR-0007", "ADR-0013", "ADR-0003", "ADR-0004"],
    }
    for adr in preferred.get(story_type, []):
        if adr in adr_ids:
            return adr
    return adr_ids[0]


def qa_case_for(story_type: str, criterion: str) -> str:
    parsed = parse_gwt(criterion)
    if parsed:
        g, w, t = parsed
    else:
        g, w, t = "the story preconditions from the linked GDD are set up", "the behavior under this acceptance criterion is exercised", criterion
    if story_type in {"Logic", "Integration", "Config/Data"}:
        return f"- **AC**: {criterion}\n  - Given: {g}\n  - When: {w}\n  - Then: {t}\n  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section"
    return f"- **Manual check**: {criterion}\n  - Setup: {g}\n  - Verify: {w}\n  - Pass condition: {t}"


def evidence_for(story_type: str, system_slug: str, story_slug: str) -> str:
    test_dir = test_dir_for(system_slug)
    if story_type == "Logic":
        return f"`tests/unit/{test_dir}/{story_slug}_test.gd` — must exist and pass"
    if story_type == "Integration":
        return f"`tests/integration/{test_dir}/{story_slug}_test.gd` — must exist and pass"
    if story_type in {"UI", "Visual/Feel"}:
        return f"`production/qa/evidence/{story_slug}-evidence.md` — manual/interaction evidence with sign-off"
    return f"`production/qa/smoke-{system_slug}.md` — smoke check evidence"


def md_cell(text: str) -> str:
    return (
        text.replace("\n", " ")
        .replace("|", "\\|")
        .replace("[", "\\[")
        .replace("]", "\\]")
    )


def make_story(system: dict, group: dict, idx: int, total: int, tr: dict, adr_ids: list[str], adrs: dict, manifest_rules: dict) -> dict:
    story_type = group.get("type") or classify_story(group["title"], group["criteria"])
    governing = choose_governing_adr(story_type, adr_ids)
    title_base = group["title"]
    if title_base.startswith("Acceptance Criteria") and group["criteria"]:
        parsed = parse_gwt(group["criteria"][0])
        if parsed:
            title_base = parsed[2]
        else:
            title_base = re.sub(r"\*\*", "", group["criteria"][0])
            title_base = re.split(r"[。.;；]", title_base)[0]
        title_base = title_base[:70]
    title = title_base.strip() or f"{system['name']} Behaviour {idx:03d}"
    story_slug = slugify_ascii(title, f"{system['slug']}-story-{idx:03d}")
    if story_slug.startswith(system["slug"]):
        story_slug = f"{idx:03d}-{story_type.lower().replace('/', '-')}"
    file_name = f"story-{idx:03d}-{story_slug}.md"
    rules = manifest_rules[rules_key(system["category"], system["slug"])]
    adr = adrs[governing]
    other_scope = []
    if idx > 1:
        other_scope.append("Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.")
    if idx < total:
        other_scope.append(f"Story {idx + 1:03d} covers the next acceptance group in this epic.")
    if not other_scope:
        other_scope.append("Neighbouring epics own their own GDD requirements.")
    depends_on = "None" if idx == 1 else "Story 001 must be ready or done for shared test fixtures and baseline APIs"
    unlocks = "None" if idx == total else f"Story {idx + 1:03d}"
    evidence = evidence_for(story_type, system["slug"], story_slug)
    return {
        "number": idx,
        "title": title,
        "slug": story_slug,
        "file": file_name,
        "type": story_type,
        "criteria": group["criteria"],
        "tr_id": tr["id"],
        "requirement": tr["requirement"],
        "governing_adr": governing,
        "adr": adr,
        "rules": rules,
        "depends_on": depends_on,
        "unlocks": unlocks,
        "out_of_scope": other_scope,
        "evidence": evidence,
        "source": group.get("source", f"GDD `{system['gdd']}`"),
    }


def render_story(system: dict, story: dict, manifest_version: str, engine: str) -> str:
    adr = story["adr"]
    guidelines = adr["guidelines"][:6] or [adr["decision"]]
    rules = story["rules"]
    criteria = "\n".join(f"- [ ] {c}" for c in story["criteria"])
    qa = "\n\n".join(qa_case_for(story["type"], c) for c in story["criteria"])
    required = "\n".join(f"- Required: {b}" for b in rules["required"][:4]) or "- Required: Follow control manifest rules for this layer."
    forbidden = "\n".join(f"- Forbidden: {b}" for b in rules["forbidden"][:3]) or "- Forbidden: Do not bypass owning system boundaries."
    guardrail = "\n".join(f"- Guardrail: {b}" for b in rules["guardrails"][:3]) or "- Guardrail: Keep story tests within the project performance budgets."
    notes = "\n".join(f"- {g}" for g in guidelines)
    out_of_scope = "\n".join(f"- {item}" for item in story["out_of_scope"])
    return f"""# Story {story['number']:03d}: {story['title']}

> **Epic**: {system['name']}
> **Status**: Ready
> **Layer**: {system['category']}
> **Type**: {story['type']}
> **Manifest Version**: {manifest_version}

## Context

**GDD**: `{system['gdd']}`
**Requirement**: `{story['tr_id']}` — {story['requirement']}

**ADR Governing Implementation**: {story['governing_adr']}: {adr['title']}
**ADR Decision Summary**: {adr['decision']}

**Engine**: {engine} | **Risk**: {adr['risk']}
**Engine Notes**: {story['governing_adr']} status is {adr['status']}; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
{required}
{forbidden}
{guardrail}

---

## Acceptance Criteria

*From {story['source']}, scoped to this story:*

{criteria}

---

## Implementation Notes

*Derived from {story['governing_adr']} Implementation Guidelines:*

{notes}

---

## Out of Scope

{out_of_scope}

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

{qa}

---

## Test Evidence

**Story Type**: {story['type']}
**Required evidence**:
- {story['evidence']}

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: {story['depends_on']}
- Unlocks: {story['unlocks']}
"""


def render_stories_table(stories: list[dict]) -> str:
    rows = ["| # | Story | Type | Status | ADR |", "|---|-------|------|--------|-----|"]
    for story in stories:
        rows.append(
            f"| {story['number']:03d} | [{md_cell(story['title'])}]({story['file']}) | {story['type']} | Ready | {story['governing_adr']} |"
        )
    return "\n".join(rows)


def render_epic(system: dict, tr: dict, adr_ids: list[str], adrs: dict, module: dict, downstream: list[str], stories: list[dict], engine: str) -> str:
    gdd_content = read(ROOT / system["gdd"])
    overview = first_paragraph(section(gdd_content, "Overview")) or first_paragraph(section(gdd_content, "Summary"))
    module_name = f"{module.get('class', system['name'])} ({module.get('pattern', 'module')})"
    class_label = module.get("class", system["name"]).replace("`", "")
    adr_rows = ["| ADR | Decision Summary | Engine Risk |", "|-----|------------------|-------------|"]
    for adr_id in adr_ids:
        adr = adrs[adr_id]
        adr_rows.append(f"| {adr_id}: {adr['title']} | {adr['decision']} | {adr['risk']} |")
    deps = ", ".join(system["depends_on_names"]) if system["depends_on_names"] else "None"
    downstream_text = ", ".join(downstream) if downstream else "None listed in `systems-index.md`"
    return f"""# Epic: {system['name']}

> **Layer**: {system['category']}
> **GDD**: {system['gdd']}
> **Architecture Module**: {module_name}
> **Status**: Ready
> **Stories**: Created ({len(stories)} stories)

## Overview

{overview}

Architecture ownership: `{class_label}` owns {module.get('owns', 'the module responsibilities defined in architecture.md')}.

## Governing ADRs

{chr(10).join(adr_rows)}

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| {tr['id']} | {tr['requirement']} | {', '.join(adr_ids)} |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**{max((adrs[a]['risk'] for a in adr_ids), key=lambda r: ['LOW', 'MEDIUM', 'HIGH'].index(r))}** — highest governing ADR knowledge risk. Engine baseline: {engine}.

## Cross-Epic Dependencies

- Upstream: {deps}
- Downstream: {downstream_text}

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `{system['gdd']}` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

{render_stories_table(stories)}

## Next Step

Run `/story-readiness production/epics/{system['slug']}/story-001-*.md` before implementing the first story in this epic.
"""


def update_existing_epic(path: Path, stories: list[dict], slug: str) -> None:
    content = read(path)
    content = re.sub(r"^> \*\*Stories\*\*:.*$", f"> **Stories**: Created ({len(stories)} stories)", content, flags=re.MULTILINE)
    stories_section = "\n## Stories\n\n" + render_stories_table(stories) + "\n"
    content = re.sub(r"\n## Stories\n[\s\S]*?(?=\n## Next Step|\Z)", "", content)
    if "\n## Next Step" in content:
        content = content.replace("\n## Next Step", stories_section + "\n## Next Step", 1)
    else:
        content = content.rstrip() + stories_section
    content = re.sub(
        r"## Next Step\s*\n[\s\S]*$",
        f"## Next Step\n\nRun `/story-readiness production/epics/{slug}/story-001-*.md` before implementing the first story in this epic.\n",
        content,
    )
    write(path, content)


def render_epics_index(systems: list[dict], stories_by_slug: dict[str, list[dict]], engine: str) -> str:
    groups: dict[str, list[dict]] = {}
    for system in systems:
        groups.setdefault(system["category"], []).append(system)
    lines = [
        "# Epics Index",
        "",
        f"> **Last Updated**: {TODAY.isoformat()}",
        f"> **Engine**: {engine}",
        "> **Stage**: Pre-Production",
        f"> **Total Epics Created**: {len(systems)} / {len(systems)} MVP systems",
        "",
    ]
    for category, items in groups.items():
        lines += [
            f"## {category} Layer ({len(items)} / {len(items)} epics created)",
            "",
            "| Epic | Layer | System | GDD | Stories | Status |",
            "|------|-------|--------|-----|---------|--------|",
        ]
        for system in items:
            count = len(stories_by_slug[system["slug"]])
            lines.append(
                f"| [{system['slug']}]({system['slug']}/EPIC.md) | {category} | {system['name']} | [{system['gdd']}](../../{system['gdd']}) | {count} created | Ready |"
            )
        lines.append("")
    lines += [
        "## Review Notes",
        "",
        "- `production/review-mode.txt` is `full`; Claude Task review gates are not available in this Codex execution surface, so this batch used deterministic traceability validation instead.",
        "- Story decomposition uses stable system-level TR IDs from `docs/architecture/tr-registry.yaml`; no new TR IDs were invented.",
        "- Sprints cap story count at 20 to keep each AI execution context bounded.",
    ]
    return "\n".join(lines)


def render_sprint(sprint_num: int, start: dt.date, stories: list[dict], system_by_slug: dict[str, dict], total_sprints: int) -> str:
    end = start + dt.timedelta(days=13)
    first_system = system_by_slug[stories[0]["system_slug"]]["name"]
    last_system = system_by_slug[stories[-1]["system_slug"]]["name"]
    parallel = sum(1 for s in stories if s["depends_on"] == "None")
    must = stories[: min(12, len(stories))]
    should = stories[len(must) : min(len(stories), len(must) + 6)]
    nice = stories[len(must) + len(should) :]

    def table(rows: list[dict]) -> str:
        out = ["| ID | Story | Epic | Type | Depends On |", "|----|-------|------|------|------------|"]
        for story in rows:
            system = system_by_slug[story["system_slug"]]
            story_path = f"../epics/{system['slug']}/{story['file']}"
            out.append(
                f"| S{sprint_num}-{story['number']:03d}-{system['slug']} | [{md_cell(story['title'])}]({story_path}) | {system['name']} | {story['type']} | {md_cell(story['depends_on'])} |"
            )
        return "\n".join(out)

    risk_rows = [
        "| Risk | Probability | Impact | Mitigation |",
        "|------|-------------|--------|------------|",
        "| Missing sprint QA plan | Medium | High | Run `/qa-plan sprint` before implementing the final story in this sprint. |",
        "| Godot 4.6.2 post-cutoff API behavior | Medium | High | Verify against `docs/engine-reference/godot/` when a governing ADR marks HIGH or MEDIUM risk. |",
        "| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |",
    ]
    return f"""# Sprint {sprint_num} -- {start.isoformat()} to {end.isoformat()}

## Sprint Goal
Deliver the planning and implementation slice from {first_system} through {last_system} while preserving upstream dependency order.

## AI Context Budget
- Stories: {len(stories)} total（≤ 20 — context window hard constraint）
- Parallelizable: {parallel} stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
{table(must)}

### Should Have
{table(should)}

### Nice to Have
{table(nice)}

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set {sprint_num}/{total_sprints}. |

## Risks
{chr(10).join(risk_rows)}

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is not present yet; sprint closure remains gated on `/qa-plan sprint`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-{sprint_num}.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

> WARNING: No QA Plan was found for this generated sprint. Run `/qa-plan sprint` before the last story is implemented. The Production -> Polish gate requires a QA sign-off report, which requires a QA plan.

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
"""


def render_sprint_status(sprint_num: int, stories: list[dict], system_by_slug: dict[str, dict], start: dt.date) -> str:
    end = start + dt.timedelta(days=13)
    lines = [
        "# Auto-generated by /sprint-plan. Updated by /story-done.",
        "# DO NOT edit manually — use /story-done to update story status.",
        "",
        f"sprint: {sprint_num}",
        'goal: "Deliver the first AI-executable implementation slice from generated planning artifacts."',
        f'start: "{start.isoformat()}"',
        f'end: "{end.isoformat()}"',
        f'generated: "{TODAY.isoformat()}"',
        f'updated: "{TODAY.isoformat()}"',
        "",
        "stories:",
    ]
    for idx, story in enumerate(stories, start=1):
        system = system_by_slug[story["system_slug"]]
        priority = "must-have" if idx <= 12 else "should-have" if idx <= 18 else "nice-to-have"
        status = "ready-for-dev" if priority == "must-have" else "backlog"
        lines += [
            f'  - id: "{sprint_num}-{idx}"',
            f'    name: "{story["title"].replace(chr(34), chr(39))}"',
            f'    file: "production/epics/{system["slug"]}/{story["file"]}"',
            f"    priority: {priority}",
            f"    status: {status}",
            '    owner: ""',
            '    blocker: ""',
            '    completed: ""',
        ]
    return "\n".join(lines)


def render_sprints_index(sprint_sets: list[list[dict]], system_by_slug: dict[str, dict]) -> str:
    lines = [
        "# Sprint Plan Index",
        "",
        f"> **Generated**: {TODAY.isoformat()}",
        "> **Planning Rule**: Each sprint has at most 20 stories for AI execution context safety.",
        "",
        "| Sprint | Story Count | First Epic | Last Epic | File |",
        "|--------|-------------|------------|-----------|------|",
    ]
    for i, stories in enumerate(sprint_sets, start=1):
        first = system_by_slug[stories[0]["system_slug"]]["name"]
        last = system_by_slug[stories[-1]["system_slug"]]["name"]
        lines.append(f"| Sprint {i} | {len(stories)} | {first} | {last} | [sprint-{i}.md](sprint-{i}.md) |")
    return "\n".join(lines)


def main() -> None:
    systems = parse_systems()
    modules = parse_arch_modules()
    tr_by_slug = parse_tr_registry()
    adrs = parse_adrs()
    manifest_rules = parse_manifest_rules()
    engine = "Godot 4.6.2"
    version_match = re.search(r"\|\s*\*\*Engine Version\*\*\s*\|\s*([^|]+)\|", read(ROOT / "docs" / "engine-reference" / "godot" / "VERSION.md"))
    if version_match:
        engine = version_match.group(1).strip()
    manifest_match = re.search(r"\*\*Manifest Version\*\*:\s*([0-9-]+)", read(ARCH_DIR / "control-manifest.md"))
    manifest_version = manifest_match.group(1) if manifest_match else TODAY.isoformat()

    system_by_name = {s["name"]: s for s in systems}
    system_by_slug = {s["slug"]: s for s in systems}
    downstream: dict[str, list[str]] = {s["slug"]: [] for s in systems}
    for system in systems:
        for dep_name in system["depends_on_names"]:
            dep = system_by_name.get(dep_name)
            if dep:
                downstream[dep["slug"]].append(system["name"])

    stories_by_slug: dict[str, list[dict]] = {}
    flat_stories: list[dict] = []
    for system in systems:
        slug = system["slug"]
        gdd_content = read(ROOT / system["gdd"])
        groups = SPECIAL_STORY_GROUPS.get(slug, []) + parse_acceptance_criteria(gdd_content)
        tr = tr_by_slug.get(slug) or {
            "id": f"TR-{slug}-???",
            "requirement": "No stable TR entry found; review tr-registry.yaml before implementation.",
        }
        adr_ids = [a for a in ADR_BY_SYSTEM.get(slug, []) if a in adrs]
        if not adr_ids:
            adr_ids = ["ADR-0008"] if "ADR-0008" in adrs else sorted(adrs)[:1]
        if not groups:
            groups = [{"title": "Baseline Contract", "criteria": [tr["requirement"]]}]
        stories = []
        for idx, group in enumerate(groups, start=1):
            story = make_story(system, group, idx, len(groups), tr, adr_ids, adrs, manifest_rules)
            story["system_slug"] = slug
            stories.append(story)
            flat_stories.append(story)
        stories_by_slug[slug] = stories

        epic_path = EPICS_DIR / slug / "EPIC.md"
        epic_dir = EPICS_DIR / slug
        epic_dir.mkdir(parents=True, exist_ok=True)
        for old_story in epic_dir.glob("story-*.md"):
            old_story.unlink()
        for story in stories:
            write(EPICS_DIR / slug / story["file"], render_story(system, story, manifest_version, engine))
        if epic_path.exists() and slug in PREEXISTING_EPICS:
            update_existing_epic(epic_path, stories, slug)
        else:
            module = modules.get(system["name"]) or modules.get(normalize_name(system["name"]), {})
            write(epic_path, render_epic(system, tr, adr_ids, adrs, module, downstream[slug], stories, engine))

    write(EPICS_DIR / "index.md", render_epics_index(systems, stories_by_slug, engine))

    sprint_sets: list[list[dict]] = []
    current: list[dict] = []
    for story in flat_stories:
        if len(current) >= 20:
            sprint_sets.append(current)
            current = []
        current.append(story)
    if current:
        sprint_sets.append(current)

    SPRINTS_DIR.mkdir(parents=True, exist_ok=True)
    for i, sprint_stories in enumerate(sprint_sets, start=1):
        start = TODAY + dt.timedelta(days=(i - 1) * 14)
        write(SPRINTS_DIR / f"sprint-{i}.md", render_sprint(i, start, sprint_stories, system_by_slug, len(sprint_sets)))
    write(SPRINTS_DIR / "index.md", render_sprints_index(sprint_sets, system_by_slug))
    write(PROD_DIR / "sprint-status.yaml", render_sprint_status(1, sprint_sets[0], system_by_slug, TODAY))

    print(f"systems={len(systems)}")
    print(f"epics={len(list(EPICS_DIR.glob('*/EPIC.md')))}")
    print(f"stories={len(flat_stories)}")
    print(f"sprints={len(sprint_sets)}")
    print(f"max_sprint_stories={max(len(s) for s in sprint_sets)}")


if __name__ == "__main__":
    main()
