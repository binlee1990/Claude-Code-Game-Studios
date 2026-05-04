# GdUnit4 本地 headless 入口
# 用法: godot --headless --script tests/gdunit4_runner.gd
#
# 注意:
#   - 编辑器内日常开发: 直接用 GdUnit Runner 面板
#   - 本脚本仅作为本地命令行 smoke 入口
extends SceneTree

const _PLUGIN_CFG_LOWER := "res://addons/gdunit4/plugin.cfg"
const _PLUGIN_CFG_UPPER := "res://addons/gdUnit4/plugin.cfg"

func _init() -> void:
	var plugin_cfg := ""
	if FileAccess.file_exists(_PLUGIN_CFG_UPPER):
		plugin_cfg = _PLUGIN_CFG_UPPER
	elif FileAccess.file_exists(_PLUGIN_CFG_LOWER):
		plugin_cfg = _PLUGIN_CFG_LOWER
	if plugin_cfg.is_empty():
		push_error(
			"GdUnit4 not installed. Install via AssetLib then enable in " +
			"Project Settings → Plugins. Expected: %s" % _PLUGIN_CFG_UPPER
		)
		quit(1)
		return
	push_warning(
		"Local runner is a thin presence-check. " +
		"Run tests via GdUnit Runner panel in editor or GdUnitCmdTool.gd."
	)
	quit(0)
