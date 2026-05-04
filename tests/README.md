# 测试基础设施

| 字段 | 值 |
|------|-----|
| **Engine** | Godot 4.6.2 |
| **Test Framework** | GdUnit4 |
| **CI** | `.github/workflows/tests.yml` |
| **Setup date** | 2026-05-04 |

## 目录结构

```
tests/
  unit/             # 隔离单元测试（公式、状态机、纯逻辑）
  integration/      # 跨系统、存档往返、Autoload 协作测试
  smoke/            # /smoke-check 关键路径列表（≤15 分钟人工验证）
  evidence/         # 截图证据 / 手测签字记录（Visual/UI/Feel 故事用）
  gdunit4_runner.gd # 本地 headless 入口（手动跑用）
  README.md         # 本文档
```

## 运行测试

### 编辑器内（推荐日常开发）

1. Godot Editor 打开项目
2. 顶部菜单 → GdUnit → 显示 Runner 面板
3. 选中 `tests/unit/` 或单个 `*_test.gd`，点击播放按钮

### Headless 本地

```powershell
# Windows PowerShell
godot --headless --script tests/gdunit4_runner.gd

# 或者使用 GdUnit4 自带 runtest 脚本（取决于已安装版本）
.\addons\gdUnit4\runtest.cmd -a tests/unit -a tests/integration
```

### CI

`main` 分支与所有 PR 上自动跑。失败会阻塞合并。

## 安装 GdUnit4 插件

scaffold 不含插件本体。首次运行前需要：

1. Godot Editor → AssetLib → 搜索 `gdUnit4` → Download & Install
2. 启用插件: Project → Project Settings → Plugins → gdUnit4 ✓
3. 重启编辑器
4. 校验: `addons/gdUnit4/plugin.cfg` 存在

> **路径备注**：当前 GdUnit4 主线插件目录通常为 `addons/gdUnit4/`（大小写按 plugin.cfg 实际为准）。如安装后路径不同，请同步修改 `tests/gdunit4_runner.gd` 与 CI 工作流。

## CI Godot 版本

`.github/workflows/tests.yml` 中固定为 **`4.6.2`**（与 `docs/engine-reference/godot/VERSION.md` 一致）。如 `MikeSchulze/gdUnit4-action@v1` 暂不支持该版本，可临时降级为最近一个被支持的稳定版（如 `4.5.x`），并在本 README 顶部记录降级原因与计划升回时间。

## 测试命名规范

- **文件**: `[system]_[feature]_test.gd`
- **函数**: `test_[scenario]_[expected]`
- **示例**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## 故事类型 → 测试证据要求

| Story Type | 必备证据 | 位置 | Gate Level |
|---|---|---|---|
| Logic | 自动化单元测试 — 必须通过 | `tests/unit/[system]/` | BLOCKING |
| Integration | 集成测试 或 文档化 playtest | `tests/integration/[system]/` | BLOCKING |
| Visual/Feel | 截图 + lead 签字 | `tests/evidence/` | ADVISORY |
| UI | 手测走查文档 或 交互测试 | `tests/evidence/` | ADVISORY |
| Config/Data | smoke check 通过 | `production/qa/smoke-*.md` | ADVISORY |

## 自动化测试硬规则

- **确定性**：禁止 `randf()` 无种子调用、禁止依赖系统时间。统一走 `RNGManager`（ADR-0004）与 `TimeManager`（ADR-0003）注入的可控源。
- **隔离**：每个 test 自己 setup / teardown 状态，不依赖执行顺序。
- **无外部 IO**：单元测试不读真实文件、不发网络、不开真实存档。集成测试可以，但要清理。
- **无内联魔法数**：用 const / fixture 工厂，边界值测试除外（数值就是测试本身）。

## 不要试图自动化的内容

- 视觉保真度（shader 输出、VFX、动画曲线）
- 手感（输入响应、节奏、重量）
- 平台特定渲染（去目标硬件跑）
- 完整玩法 session（交给 playtest，不是自动化）

## 与 Gate 的关系

`/gate-check Technical Setup → Pre-Production` 要求：

- `tests/unit/` 与 `tests/integration/` 目录存在 ✓
- `.github/workflows/tests.yml` 存在 ✓
- 至少一个示例测试文件存在 ✓ (`tests/unit/_example/example_logic_test.gd`)

`/gate-check Pre-Production → Production` 要求所有 Logic 故事都有对应 unit test，且 `/smoke-check` 通过。
