# Claude Code Game Studios -- Game Studio Agent Architecture

## 核心规则

1. **语言**: 用英文思考，用中文回复。质量优先于速度——需求未明确前不急于动手。
2. **决策**: 需要用户做决定时，用 `AskUserQuestion` 工具交互，至少提供4个选项，必须含一个推荐项并附理由。
3. **风格**: 极简输出——直接给结果，不重复、不总结、不废话。
4. **文档输出/生成**: 统一使用中文生成，必要时再转换为英文。
5. **必问协议**: 决策节点（Schema 字段取舍、实体建模边界、Cypher 建模方式、Phase 范围变更）一律调用 `AskUserQuestion`，至少 4 个选项，其中 1 个 "(Recommended)" 并附理由。不猜测、不默认。

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
