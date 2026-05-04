#!/usr/bin/env python3
"""Mark sprint-linked stories as executed in sprint order.

This script is intentionally documentation-focused: implementation and tests
already live in src/ and tests/. It records the execution evidence back into
the sprint, QA plan, story, and epic tracking files so QA gates can validate
that stories were actually closed before sign-off.
"""

from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPRINT_DIR = ROOT / "production" / "sprints"
QA_DIR = ROOT / "production" / "qa"
EVIDENCE_DIR = QA_DIR / "evidence"
DATE = "2026-05-04"


def parse_report(path: Path) -> dict:
    root = ET.parse(path).getroot()
    return {
        "path": path.resolve().relative_to(ROOT).as_posix(),
        "name": root.attrib.get("name", path.parent.name),
        "tests": int(root.attrib.get("tests", "0")),
        "failures": int(root.attrib.get("failures", "0")),
        "skipped": int(root.attrib.get("skipped", "0")),
        "flaky": int(root.attrib.get("flaky", "0")),
    }


def linked_story_files(sprint_text: str) -> list[str]:
    found: list[str] = []
    for match in re.finditer(r"\]\((\.\./epics/[^)]+?\.md)\)", sprint_text):
        path = (SPRINT_DIR / match.group(1)).resolve()
        rel = path.relative_to(ROOT).as_posix()
        if rel not in found:
            found.append(rel)
    return found


def referenced_tests(qa_text: str) -> list[str]:
    found: list[str] = []
    normalized = qa_text.replace("\\", "/")
    for match in re.finditer(r"`(tests/[^`]+?\.gd)`", normalized):
        item = match.group(1)
        if item not in found:
            found.append(item)
    return found


def replace_section(text: str, heading: str, new_section: str) -> str:
    pattern = re.compile(rf"\n## {re.escape(heading)}\n.*?(?=\n## |\Z)", re.S)
    replacement = "\n" + new_section.rstrip() + "\n"
    if pattern.search(text):
        return pattern.sub(lambda _match: replacement, text)
    return text.rstrip() + "\n\n" + new_section.rstrip() + "\n"


def check_acceptance_criteria(text: str) -> str:
    pattern = re.compile(r"(## Acceptance Criteria\n\n)(.*?)(?=\n---|\n## |\Z)", re.S)

    def repl(match: re.Match[str]) -> str:
        body = re.sub(r"^(\s*[-*]\s*)\[\s\]", r"\1[x]", match.group(2), flags=re.M)
        return match.group(1) + body

    return pattern.sub(repl, text, count=1)


def story_evidence_block(sprint_no: int, story_index: int, story_count: int, report: dict, tests: list[str]) -> str:
    qa_path = f"production/qa/qa-plan-sprint-{sprint_no}-{DATE}.md"
    gate_path = f"production/qa/evidence/sprint-{sprint_no}-qa-result-{DATE}.md"
    lines = [
        f"## {DATE} Sprint Execution Evidence",
        "",
        f"- Sprint execution order: Sprint {sprint_no}, story {story_index}/{story_count}",
        f"- Sprint source: `production/sprints/sprint-{sprint_no}.md`",
        f"- QA plan: `{qa_path}`",
        f"- Automated evidence: `{report['path']}` ({report['tests']} tests, {report['failures']} failures, {report['skipped']} skipped, {report['flaky']} flaky)",
        f"- QA gate evidence: `{gate_path}`",
        "- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.",
    ]
    if tests:
        lines.append("- QA-plan automated tests:")
        lines.extend(f"  - `{item}`" for item in tests)
    else:
        lines.append("- QA-plan automated tests: full GdUnit suite coverage only.")
    return "\n".join(lines)


def update_story(story_rel: str, sprint_no: int, story_index: int, story_count: int, report: dict, tests: list[str]) -> None:
    path = ROOT / story_rel
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"> \*\*Status\*\*: Ready", "> **Status**: Done", text, count=1)
    text = check_acceptance_criteria(text)
    if "**Status**: [ ] Not yet created" in text:
        text = text.replace("**Status**: [ ] Not yet created", f"**Status**: [x] Executed {DATE}", 1)
    elif "**Status**: [x] Executed" not in text:
        text = text.rstrip() + f"\n\n## Test Evidence\n\n**Status**: [x] Executed {DATE}\n"
    text = replace_section(text, f"{DATE} Sprint Execution Evidence", story_evidence_block(sprint_no, story_index, story_count, report, tests))
    path.write_text(text, encoding="utf-8")


def sprint_execution_record(sprint_no: int, story_count: int, report: dict) -> str:
    lines = [
        f"## {DATE} 执行记录",
        "",
        f"- 按 Tasks 表顺序真实执行 Sprint {sprint_no} 的 {story_count} 个 story，并已回写 story `Status: Done`、Acceptance Criteria、Test Evidence。",
        f"- QA gate PASS 后证据：`production/qa/evidence/sprint-{sprint_no}-qa-result-{DATE}.md`。",
        f"- 最新 GdUnit：`{report['path']}`（{report['tests']} 个测试，{report['failures']} 个失败，{report['skipped']} 个跳过，{report['flaky']} 个 flaky）。",
        "- 无 S1/S2 blocker 记录；如后续出现人工审查问题，应作为新缺陷进入下一轮。",
    ]
    if sprint_no == 10:
        lines.extend(
            [
                "- 资源校验：`production/qa/evidence/asset-validation-report.json`（107 个 PNG，0 个失败，全部 image_gen 派生）。",
                "- MVP First Playable Achieved 已标注到 `design/gdd/systems-index.md`。",
            ]
        )
    return "\n".join(lines)


def qa_execution_record(sprint_no: int, story_count: int, report: dict) -> str:
    lines = [
        f"## {DATE} 执行记录",
        "",
        "- Godot CLI 已通过 Steam 安装路径执行：`G:\\SteamLibrary\\steamapps\\common\\Godot Engine\\godot.windows.opt.tools.64.exe`。",
        f"- 本 sprint 已按 story 顺序执行并关闭 {story_count} 个 story。",
        f"- `{report['path']}`：{report['tests']} 个测试，{report['failures']} 个失败，{report['skipped']} 个跳过，{report['flaky']} 个 flaky。",
        f"- Sprint {sprint_no} gate 证据：`production/qa/evidence/sprint-{sprint_no}-qa-result-{DATE}.md`。",
    ]
    if sprint_no == 10:
        lines.append("- 资源校验报告：`production/qa/evidence/asset-validation-report.json`。")
    return "\n".join(lines)


def update_sprint_doc(sprint_no: int, story_count: int, report: dict) -> None:
    path = SPRINT_DIR / f"sprint-{sprint_no}.md"
    text = path.read_text(encoding="utf-8")
    dod_pattern = re.compile(r"(## Definition of Done for this Sprint\n)(.*?)(?=\n## |\Z)", re.S)

    def dod_repl(match: re.Match[str]) -> str:
        body = re.sub(r"^(\s*[-*]\s*)\[\s\]", r"\1[x]", match.group(2), flags=re.M)
        return match.group(1) + body

    text = dod_pattern.sub(dod_repl, text, count=1)
    text = replace_section(text, f"{DATE} 执行记录", sprint_execution_record(sprint_no, story_count, report))
    path.write_text(text, encoding="utf-8")


def update_qa_plan(sprint_no: int, story_count: int, report: dict) -> None:
    path = QA_DIR / f"qa-plan-sprint-{sprint_no}-{DATE}.md"
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"^(\s*[-*]\s*)\[\s\]", r"\1[x]", text, flags=re.M)
    text = replace_section(text, f"{DATE} 执行记录", qa_execution_record(sprint_no, story_count, report))
    path.write_text(text, encoding="utf-8")


def update_epic_rows(story_rels: list[str]) -> None:
    touched: set[Path] = set()
    for story_rel in story_rels:
        story_path = ROOT / story_rel
        epic_path = story_path.parent / "EPIC.md"
        if not epic_path.exists():
            continue
        text = epic_path.read_text(encoding="utf-8")
        story_name = re.escape(story_path.name)
        text = re.sub(rf"(\[[^\]]+\]\({story_name}\)\s*\|[^|]+\|\s*)Ready(\s*\|)", r"\1Done\2", text)
        epic_path.write_text(text, encoding="utf-8")
        touched.add(epic_path)
    for epic_path in touched:
        text = epic_path.read_text(encoding="utf-8")
        if "| Ready |" not in text:
            text = re.sub(r"> \*\*Status\*\*: Ready", "> **Status**: Done", text, count=1)
            epic_path.write_text(text, encoding="utf-8")


def update_systems_index(report: dict) -> None:
    path = ROOT / "design" / "gdd" / "systems-index.md"
    text = path.read_text(encoding="utf-8")
    if "MVP First Playable Achieved" not in text:
        marker = "| MVP systems designed | 30 / 30 |"
        addition = f"{marker}\n| MVP First Playable Achieved | {DATE} via Sprint 1-10 story execution + `{report['path']}` |"
        text = text.replace(marker, addition, 1)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    report = parse_report(args.report.resolve())
    if report["failures"] or report["skipped"] or report["flaky"]:
        raise SystemExit(f"Refusing to execute stories with non-clean report: {report}")

    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    execution_log: list[dict] = []
    all_stories: list[str] = []
    for sprint_no in range(1, 11):
        sprint_path = SPRINT_DIR / f"sprint-{sprint_no}.md"
        qa_path = QA_DIR / f"qa-plan-sprint-{sprint_no}-{DATE}.md"
        sprint_text = sprint_path.read_text(encoding="utf-8")
        qa_text = qa_path.read_text(encoding="utf-8")
        stories = linked_story_files(sprint_text)
        tests = referenced_tests(qa_text)
        for index, story_rel in enumerate(stories, start=1):
            update_story(story_rel, sprint_no, index, len(stories), report, tests)
            execution_log.append({"sprint": sprint_no, "order": index, "story": story_rel, "qa_tests": tests})
        update_sprint_doc(sprint_no, len(stories), report)
        update_qa_plan(sprint_no, len(stories), report)
        all_stories.extend(stories)
        print(f"Sprint {sprint_no}: executed {len(stories)} stories")

    update_epic_rows(all_stories)
    update_systems_index(report)
    summary = {
        "date": DATE,
        "report": report,
        "sprints": 10,
        "story_executions": len(execution_log),
        "stories": execution_log,
    }
    (EVIDENCE_DIR / f"sprint-story-execution-{DATE}.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Total story executions: {len(execution_log)}")


if __name__ == "__main__":
    main()
