# Epic: 多语言管理系统

> **Layer**: Foundation
> **GDD**: `design/gdd/localization-system.md`
> **Status**: Planning
> **Created**: 2026-04-26

## 目标

将所有硬编码 UI 字符串迁移至 `SRPGLocalization` 集中管理，添加语言切换 UI，持久化语言偏好。
解决玩家反馈"所有字段全部默认显示中文，增加多语言管理系统"。

## 前置条件

| 条件 | 状态 |
|------|------|
| SRPGLocalization 类已存在 | ✅ |
| zh_CN + en_US 双语目录骨架 | ✅ |
| SaveManager 持久化能力 | ✅ |
| Sprint-004 管理/基地 UI 已完成 | ✅ |

## Stories

| ID | 标题 | 类型 | Est. | Dependencies |
|----|------|------|------|-------------|
| LOC-001 | 全量 UI 字符串迁移至 SRPGLocalization | Integration | 1d | SRPGLocalization 存在 |
| LOC-002 | 语言切换 UI（主菜单） | UI | 0.25d | LOC-001 |
| LOC-003 | 语言偏好持久化 + 运行时切换 | Integration | 0.25d | LOC-001 + SaveManager |

## 范围外

- 外部翻译文件（CSV/JSON）导入导出
- 自动翻译 API 集成
- 第三方语言包支持
- 字体/排版 RTL 支持
