# 多语言管理系统

## 概述

基于现有 `SRPGLocalization` 类构建完整的多语言管理流程：将所有硬编码 UI 字符串迁移至集中式翻译目录，添加语言切换 UI，并持久化语言偏好。

## 设计原则

1. **零硬编码**：所有玩家可见字符串必须通过 `SRPGLocalization.translate(key)` 获取
2. **默认中文**：`DEFAULT_LOCALE = "zh_CN"`，中文为首要语言
3. **key 命名**：`{domain}.{element}` 格式，如 `base.training_title`、`market.confirm`
4. **编译期安全**：key 作为字符串常量集中管理，减少拼写错误
5. **扩展友好**：目录结构支持未来迁移到外部 CSV/JSON 文件

## 影响范围

### 需要迁移的 UI 文件

| 文件 | 硬编码字符串数（估） |
|------|---------------------|
| `base_hub.gd` | ~25 |
| `training_ground.gd` | ~10 |
| `character_management.gd` | ~20 |
| `equipment_management.gd` | ~15 |
| `main_menu.gd` | ~5 |
| `battle_arena.gd` (settlement/management) | ~30 |
| **合计** | **~105** |

### 新增 key 域

| 域 | 说明 |
|----|------|
| `base.*` | 基地界面（训练场/市集） |
| `management.*` | 管理界面（角色/装备） |
| `market.*` | 市集交易 |
| `training.*` | 训练场 |
| `menu.*` | 主菜单 |
| `settlement.*` | 战斗结算 |
| `common.*` | 通用（确认/取消/关闭等） |

## 语言切换 UI

- 位置：主菜单 Settings 按钮 或 独立语言切换按钮
- 选项：中文 / English（未来可扩展）
- 切换后即时生效（无需重启）
- 语言偏好通过 SaveManager 持久化

## 公式

无数学公式。key 映射关系：`translate(key) → _CATALOG[locale][key] ?? _CATALOG[DEFAULT_LOCALE][key] ?? key`

## 边界情况

| 情况 | 处理 |
|------|------|
| key 不存在 | 回退到 DEFAULT_LOCALE，再回退到 key 本身 |
| 新 locale 缺少 key | 用 DEFAULT_LOCALE 的值填充 |
| 运行时切换语言 | 所有可见 UI 刷新 translate 调用 |
| 存档无语言设置 | 使用 DEFAULT_LOCALE |

## 依赖

| 系统 | 说明 |
|------|------|
| SRPGLocalization | 已存在，需扩展目录 |
| SaveManager | 持久化语言偏好 |
| SRPGTheme | UI 组件需要支持动态文本刷新 |

## 可调参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| DEFAULT_LOCALE | "zh_CN" | 首要语言 |
| SUPPORTED_LOCALES | ["zh_CN", "en_US"] | 支持的语言列表 |
| FALLBACK_BEHAVIOR | key → zh_CN → key | 三级回退 |

## 验收标准

1. 所有 UI 文件中无硬编码中文/英文字符串（除 debug 日志）
2. 语言切换即时生效
3. 语言偏好存档后重进保持
4. 新增 key 覆盖率 100%（zh_CN 和 en_US 都有对应翻译）
