Role: Godot 4.6.2/GDScript QA 修复负责人，兼顾 qa-lead 测试计划、gameplay 代码实现和回归验证。
Context: 用户要求对 production/sprints 下所有 sprint 按 sprint-1 到 sprint-10 顺序串行执行本地 .claude/skills/qa-plan，并在每个 sprint 修复完成后才进入下一个。项目当前是 Godot 4.6.2 + GDScript，测试框架为 GdUnit4，生产文档要求中文输出。根目录 git 状态在任务开始时干净。qa-plan 的交互写入确认在本任务中由用户的显式批量执行请求和 AGENTS.md 自主执行指令替代，但每个 sprint 仍保留验证证据。
Objective: 依次为 sprint-1 到 sprint-10 生成或更新 QA 计划，按计划补齐必须的自动化测试/手测证据/实现修复，并用可运行验证证明当前 sprint 达标后再进入下一 sprint。
Success criteria: 每个 sprint 都有对应 production/qa/qa-plan-sprint-N-2026-05-04.md；该 sprint 的 Logic/Integration 故事有测试文件或明确证据；相关实现缺口被补齐；可用的测试命令通过或不可运行原因被记录；处理顺序未跳过任何未完成 sprint。
Decomposition: 1. 盘点 sprint 文件和项目测试入口。2. 对当前 sprint 解析故事、GDD/ADR、实现文件和验收标准。3. 按 qa-plan 结构生成 sprint QA 计划。4. 补齐或修复当前 sprint 的代码、测试和证据。5. 运行当前 sprint 相关测试及全局可用验证。6. 记录结果，通过后进入下一个 sprint。7. 全部完成后归档此任务文件。
Methodology: 使用 reframe-and-execute 的 Diagnose -> Reframe -> Challenge -> Execute -> Evaluate -> Deliver gate；使用 MECE 将工作按 sprint 串行分块，避免跨 sprint 混改导致验证边界不清。
Output: 代码/测试/文档变更、每个 sprint 的 QA 计划、执行记录和最终中文汇报，包含变更文件、验证证据、剩余风险。
Constraints: 不新增依赖；不提交 git commit；不跳过失败 sprint；不使用破坏性 git 操作；遵守 src 与 tests 下 CLAUDE.md；优先复用已有设计/GDD/ADR；Game code 公共 API 需要文档注释；测试需确定性。
Non-assumptions: 不假设 Godot/GdUnit4 已安装或可执行；不假设 sprint-status.yaml 代表所有 sprint，只将其作为 sprint 1 的状态上下文；不假设故事全部已实现；不把视觉/手感验收伪装成自动化通过。
Verification: 对每个 sprint 运行相关 GDScript/GdUnit 可用检查；若 Godot CLI 不可用，则至少进行静态文件/故事覆盖/测试路径校验并记录环境缺口；最终运行 git diff/status、QA 计划覆盖检查和可用测试命令。
Confidence: medium - 范围和顺序明确，但当前仓库可能缺少完整 Godot 项目文件或 GdUnit4 插件，自动化运行能力需现场确认。
Reproducibility: 工作目录 D:\work\Games\GUAJI_01；当前日期 2026-05-04；目标 sprint 文件 production/sprints/sprint-1.md 到 sprint-10.md；QA 技能 D:\work\Games\GUAJI_01\.claude\skills\qa-plan\SKILL.md。
Baseline: 任务开始时 git status --short 无输出；production/sprints/index.md 列出 10 个 sprint，共 187 个故事；已有 tests/README.md 与 tests/gdunit4_runner.gd。
Execution: 状态 complete；sprint-1 到 sprint-10 已按顺序完成 QA 计划、实现/测试补齐和可用验证。
Verification: Godot CLI `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe` 为 4.6.2.stable；`--headless --path . --quit --editor` 通过；`--headless --path . --quit` 通过；`tests/gdunit4_runner.gd` 仅因本机未安装 `res://addons/gdUnit4/plugin.cfg` 被阻断。
