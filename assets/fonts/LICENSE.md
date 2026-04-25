# Fonts License

> 版本: v0.1 | 日期: 2026-04-26 | 负责: art-director / asset-engineer
> Sprint: sprint-002 Lane B (ART-P0-05 / ART-P0-06)

本目录下所有字体文件均为开源字体，遵循 SIL Open Font License 1.1 (OFL-1.1)。
OFL 1.1 全文: https://openfontlicense.org/open-font-license-official-text/

---

## 1. zcool_xiaowei.ttf — ZCOOL XiaoWei (站酷小薇 LOGO 体)

| 字段 | 内容 |
|------|------|
| 文件名 | `zcool_xiaowei.ttf` |
| 字体名 | ZCOOL XiaoWei |
| 文件大小 | 6,313,808 字节 (~6.02 MB) |
| 字重/样式 | Regular |
| License | SIL Open Font License 1.1 (OFL-1.1) |
| License 全文链接 | https://github.com/google/fonts/blob/main/ofl/zcoolxiaowei/OFL.txt |
| 来源平台 | Google Fonts (镜像于 google/fonts GitHub 仓库) |
| 来源 URL (规范页面) | https://fonts.google.com/specimen/ZCOOL+XiaoWei |
| 实际下载 URL | https://github.com/google/fonts/raw/main/ofl/zcoolxiaowei/ZCOOLXiaoWei-Regular.ttf |
| 下载日期 | 2026-04-26 |
| 用途 | 主菜单游戏标题、章节名称、Boss 名称、重大选择提示文本 |
| 来源依据 | `production/assets/free-asset-shopping-list.md` 1-D 条目；`design/art/redesign-direction-2026-04-26.md` §3.1 |

## 2. noto_serif_sc.otf — Noto Serif SC (思源宋体简体子集)

| 字段 | 内容 |
|------|------|
| 文件名 | `noto_serif_sc.otf` |
| 字体名 | Noto Serif SC (Subset OTF, Regular) |
| 文件大小 | 11,625,800 字节 (~11.09 MB) |
| 字重/样式 | Regular |
| License | SIL Open Font License 1.1 (OFL-1.1) |
| License 全文链接 | https://github.com/notofonts/noto-cjk/blob/main/Serif/LICENSE |
| 来源平台 | notofonts/noto-cjk (Google Noto 官方 GitHub 仓库) |
| 来源 URL (规范页面) | https://github.com/notofonts/noto-cjk |
| 实际下载 URL | https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/SubsetOTF/SC/NotoSerifSC-Regular.otf |
| 下载日期 | 2026-04-26 |
| 用途 | 中文正文：对话气泡、技能描述、物品说明、战斗 Log、菜单列表文字 |
| 选用说明 | 清单 1-C 朱雀仿宋 (TrionesType/zhuque-fangsong) 为首选；本 Sprint 改用 Noto Serif SC 作为正文字体 (sprint plan 风险栏明确允许 fallback 到思源宋体)。Noto Serif SC SubsetOTF 单文件 ~11 MB，相较 Source Han Serif SC 全字符集 ~30-100 MB 更适合直接入库；OFL 1.1 与朱雀仿宋同 License，合规性等价。 |
| 来源依据 | `production/assets/free-asset-shopping-list.md` (1-C 备用方向) ；`production/sprints/sprint-002.md` 风险与缓解栏 ART-P0-06 fallback 条款 |

---

## OFL 1.1 合规要点（项目级 reminder）

| 要点 | 说明 |
|------|------|
| 嵌入游戏 | 允许（OFL 明确允许字体嵌入软件分发） |
| 商用 | 允许，无需付费 |
| 修改/重命名 | 修改后**不得使用原 Reserved Font Name**；本项目仅嵌入未修改的原字体文件，无重命名需求 |
| 单独销售字体本身 | **禁止** —— 本项目仅作为游戏内资源使用，不会单独分发字体文件 |
| Credits 要求 | OFL 不强制要求游戏内 Credits 注明，但建议在 Credits 屏幕列出字体名以示尊重 |

## 字体在游戏内的 Credits 文案建议

```
Fonts
  ZCOOL XiaoWei  — Open Font License, ZCOOL Studio
  Noto Serif SC  — Open Font License, Google / Adobe
```
