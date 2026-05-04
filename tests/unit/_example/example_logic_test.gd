# Example logic test — proves GdUnit4 framework is wired up correctly.
#
# 这是一个最小自洽测试，用来回答两个问题:
#   1. tests/ 框架是否能被 GdUnit4 发现并执行
#   2. CI 工作流是否能把测试结果回报到 PR
#
# 故意不依赖任何业务代码，所以即便 src/ 里一行 GDScript 都没有，本测试仍能跑。
# 真正的业务测试请按命名规范放到对应系统子目录，例如:
#   tests/unit/big_number/big_number_arithmetic_test.gd
#   tests/unit/resource_system/resource_immutable_test.gd
#
# 用法:
#   - 编辑器: GdUnit Runner 面板 → 选中本文件 → 运行
#   - CLI:   godot --headless --script tests/gdunit4_runner.gd (presence check)
#   - CI:    push 到 main 或开 PR 自动触发 .github/workflows/tests.yml
extends GdUnitTestSuite


func test_arithmetic_is_deterministic() -> void:
	assert_int(1 + 1).is_equal(2)


func test_string_compare_is_exact() -> void:
	assert_str("guaji_01").is_equal("guaji_01")


func test_array_membership() -> void:
	var ids := ["foundation", "core", "feature", "presentation"]
	assert_array(ids).contains(["core"])
	assert_array(ids).has_size(4)
