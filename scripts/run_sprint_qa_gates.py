#!/usr/bin/env python3
"""Serially validate sprint QA gates from the latest GdUnit report."""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QA_DIR = ROOT / "production" / "qa"
SPRINT_DIR = ROOT / "production" / "sprints"
EVIDENCE_DIR = QA_DIR / "evidence"
DEPRECATED_TOKENS = ["yield(", "OS.get_ticks_msec(", 'connect("']


def latest_report() -> Path:
    reports = sorted((ROOT / "reports").glob("report_*/results.xml"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not reports:
        raise FileNotFoundError("No GdUnit results.xml found under reports/report_*")
    return reports[0]


def parse_report(report: Path) -> dict:
    root = ET.parse(report).getroot()
    return {
        "path": report.relative_to(ROOT).as_posix(),
        "tests": int(root.attrib.get("tests", "0")),
        "failures": int(root.attrib.get("failures", "0")),
        "skipped": int(root.attrib.get("skipped", "0")),
        "flaky": int(root.attrib.get("flaky", "0")),
    }


def referenced_tests(plan_text: str) -> list[str]:
    found = []
    for match in re.finditer(r"`(tests/[^`]+?\.gd)`", plan_text.replace("\\", "/")):
        path = match.group(1)
        if path not in found:
            found.append(path)
    return found


def linked_story_files(sprint_text: str) -> list[str]:
    found = []
    for match in re.finditer(r"\]\((\.\./epics/[^)]+?\.md)\)", sprint_text):
        path = (SPRINT_DIR / match.group(1)).resolve()
        rel = path.relative_to(ROOT).as_posix()
        if rel not in found:
            found.append(rel)
    return found


def acceptance_section(text: str) -> str:
    match = re.search(r"## Acceptance Criteria\n\n(.*?)(?=\n---|\n## |\Z)", text, re.S)
    return match.group(1) if match else ""


def story_execution_issues(story_rel: str) -> list[str]:
    path = ROOT / story_rel
    text = path.read_text(encoding="utf-8")
    issues = []
    if "> **Status**: Done" not in text:
        issues.append(f"{story_rel} 未标记 Status: Done")
    if re.search(r"^\s*[-*]\s*\[\s\]", acceptance_section(text), re.M):
        issues.append(f"{story_rel} 仍有未勾选 Acceptance Criteria")
    if f"**Status**: [x] Executed 2026-05-04" not in text:
        issues.append(f"{story_rel} 未创建 2026-05-04 Test Evidence")
    if "## 2026-05-04 Sprint Execution Evidence" not in text:
        issues.append(f"{story_rel} 缺少 sprint execution evidence block")
    return issues


def check_autoload_order() -> tuple[bool, str]:
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    order = [
        "EventBusAutoload",
        "RNGManagerAutoload",
        "TimeManagerAutoload",
        "DataConfigHostAutoload",
        "SaveManagerAutoload",
        "ResourceSystemHostAutoload",
        "AttributeSystemHostAutoload",
        "ItemRegistryHostAutoload",
        "OutputMultiplierSystemHostAutoload",
        "LevelSystemHostAutoload",
        "StorageLimitSystemHostAutoload",
        "AutoProductionSystemHostAutoload",
        "EnemyDatabaseHostAutoload",
        "LootSystemHostAutoload",
        "CultivationSystemHostAutoload",
        "CombatCalculatorHostAutoload",
        "ZoneSystemHostAutoload",
        "MapProgressionSystemHostAutoload",
        "SemiAutoCombatSystemHostAutoload",
        "OfflineSimulationCoreHostAutoload",
        "IdleExplorationSystemHostAutoload",
        "OfflineCombatSimulationSystemHostAutoload",
        "OfflineRewardSettlementSystemHostAutoload",
        "UIManagerHostAutoload",
        "HUDSystemHostAutoload",
        "DebugConsoleAutoload",
    ]
    positions = []
    for name in order:
        pos = text.find(name)
        if pos < 0:
            return False, f"缺少 autoload: {name}"
        positions.append(pos)
    if positions != sorted(positions):
        return False, "autoload 顺序不符合标准依赖顺序"
    return True, "autoload 顺序符合 sprint 依赖序列"


def check_deprecated_tokens() -> tuple[bool, str]:
    scanned = []
    for base in [ROOT / "src", ROOT / "tests"]:
        for path in base.rglob("*.gd"):
            text = path.read_text(encoding="utf-8")
            for token in DEPRECATED_TOKENS:
                if token in text:
                    scanned.append(f"{path.relative_to(ROOT).as_posix()} 包含 {token}")
    if scanned:
        return False, "; ".join(scanned)
    return True, "src/tests 未发现废弃 Godot 3 写法"


def gate_sprint(number: int, report: dict) -> dict:
    sprint_path = SPRINT_DIR / f"sprint-{number}.md"
    qa_path = QA_DIR / f"qa-plan-sprint-{number}-2026-05-04.md"
    issues = []
    checks = []

    if not sprint_path.exists():
        issues.append(f"缺少 {sprint_path.relative_to(ROOT).as_posix()}")
        sprint_text = ""
    else:
        sprint_text = sprint_path.read_text(encoding="utf-8")
        story_files = linked_story_files(sprint_text)
        missing_stories = [p for p in story_files if not (ROOT / p).exists()]
        if missing_stories:
            issues.append("缺少 sprint 关联 story 文件: " + ", ".join(missing_stories))
        for story_file in story_files:
            if (ROOT / story_file).exists():
                issues.extend(story_execution_issues(story_file))
        checks.append(f"{len(story_files)} 个 sprint 关联 story 文件存在且已校验执行状态")

    if not qa_path.exists():
        issues.append(f"缺少 {qa_path.relative_to(ROOT).as_posix()}")
        qa_text = ""
    else:
        qa_text = qa_path.read_text(encoding="utf-8")
        required_tests = referenced_tests(qa_text)
        missing_tests = [p for p in required_tests if not (ROOT / p).exists()]
        if missing_tests:
            issues.append("缺少 QA 引用测试文件: " + ", ".join(missing_tests))
        checks.append(f"{len(required_tests)} 个 QA 引用测试文件存在")

    if report["failures"] != 0 or report["skipped"] != 0 or report["flaky"] != 0:
        issues.append(f"GdUnit 报告未清零: failures={report['failures']} skipped={report['skipped']} flaky={report['flaky']}")
    checks.append(f"GdUnit 报告 {report['path']} 通过: {report['tests']} 个测试")

    ok, message = check_autoload_order()
    checks.append(message)
    if not ok:
        issues.append(message)

    ok, message = check_deprecated_tokens()
    checks.append(message)
    if not ok:
        issues.append(message)

    if number == 10:
        asset_report = ROOT / "production" / "qa" / "evidence" / "asset-validation-report.json"
        if not asset_report.exists():
            issues.append("缺少资源校验报告")
        else:
            checks.append("资源校验报告存在")

    verdict = "PASS" if not issues else "FAIL"
    write_evidence(number, verdict, checks, issues, report)
    return {"sprint": number, "verdict": verdict, "issues": issues}


def write_evidence(number: int, verdict: str, checks: list[str], issues: list[str], report: dict) -> None:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# Sprint {number} QA Gate - 2026-05-04",
        "",
        f"验收结论: {verdict}",
        f"GdUnit 报告: `{report['path']}`",
        f"GdUnit 摘要: {report['tests']} 个测试，{report['failures']} 个失败，{report['skipped']} 个跳过，{report['flaky']} 个 flaky",
        "",
        "## 校验项",
        "",
    ]
    lines.extend(f"- {item}" for item in checks)
    lines.extend(["", "## 问题", ""])
    if issues:
        lines.extend(f"- {item}" for item in issues)
    else:
        lines.append("- 无")
    lines.append("")
    (EVIDENCE_DIR / f"sprint-{number}-qa-result-2026-05-04.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, default=None)
    args = parser.parse_args()
    report_path = (args.report if args.report else latest_report()).resolve()
    report = parse_report(report_path)
    failed = []
    for number in range(1, 11):
        result = gate_sprint(number, report)
        print(f"Sprint {number}: {result['verdict']}")
        if result["verdict"] != "PASS":
            failed.append(result)
            break
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
