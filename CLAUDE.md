# Claude Code Game Studios -- Game Studio Agent Architecture

## core rules（沟通与决策）

1. **Think in English, respond in Chinese** — 思考过程用英语保证逻辑严谨；回复用户统一用中文。Quality over speed — iterate until requirements are truly clear.
2. **AskUserQuestion 决策模式** — 需用户确认时，通过 AskUserQuestion Tool 给至少 4 个选项，标记推荐项（✅）并说明理由。
3. **文档输出语言** — 所有文档统一中文。代码、文件名、路径、reason codes 等必要字段使用英文。
4. godot执行文件地址: G:\SteamLibrary\steamapps\common\Godot Engine
5. **工具调用卫生** — 严禁用 shell/PowerShell 输出进度标记、占位文本、自言自语、工具切换说明或内部犹豫；例如 `Write-Output "now call image_gen"`、`echo "marker"`、`echo "noop"`。Shell 只能用于读取状态、修改文件、运行构建/测试/校验等真实任务。进度说明必须走对话消息，不得伪装成命令执行。

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
