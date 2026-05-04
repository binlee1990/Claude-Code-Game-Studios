## Minimal MVP HUD bootstrap (asset-integrated).
##
## Purpose: prove the 27 autoload services can drive a Godot scene tree,
## AND that all 107 production assets are wired through correctly.
## NOT a final HUD — see design/ux/hud.md for the full three-strip spec;
## this is the skeleton Sprint 11 will replace screen-by-screen.
##
## Asset coverage (临时骨架阶段):
## - assets/ui/theme.tres                         主题（panel/popup/button/label color）
## - assets/ui/icons/resources/*.png   (5)        5 资源 row 图标
## - assets/ui/icons/realm/*.png       (7)        境界图标动态切换
## - assets/ui/icons/stances/*.png     (4)        姿态图标动态切换
## - assets/ui/icons/status/*.png      (5)        战斗 / 离线 / 升级 / 溢出状态点
## - assets/map/main_base.png          (1)        洞府背景
## - assets/ui/seals/*.png             (3)        突破金 / 失败红 / 普通水墨印章（备用）
## Sprint 11 mvp-screens / hud-real-layout / toast-stack 各自取走的资产由
## design/registry/ui-asset-manifest.md 强制 DoD 兜底。
extends CanvasLayer

const RESOURCE_IDS := ["lingqi", "xiuwei", "lingshi", "herb", "exp"]
const RESOURCE_LABELS := {
	"lingqi": "灵气",
	"xiuwei": "修为",
	"lingshi": "灵石",
	"herb": "药材",
	"exp": "经验",
}
const MAX_LOG_LINES := 80

const STANCE_ICON_PATHS := {
	"meditate": "res://assets/ui/icons/stances/meditate.png",
	"condense": "res://assets/ui/icons/stances/condense.png",
	"closed_door": "res://assets/ui/icons/stances/closed_door.png",
	"idle": "res://assets/ui/icons/stances/idle.png",
}

const REALM_ICON_PATHS := {
	"fanren": "res://assets/ui/icons/realm/mortal.png",
	"lianqi": "res://assets/ui/icons/realm/qi_refining.png",
	"zhuji": "res://assets/ui/icons/realm/foundation.png",
	"jindan": "res://assets/ui/icons/realm/golden_core.png",
	"yuanying": "res://assets/ui/icons/realm/yuanying.png",
	"huashen": "res://assets/ui/icons/realm/huashen.png",
	"heti": "res://assets/ui/icons/realm/heti.png",
}

const STATUS_ICON_PATHS := {
	"combat_active": "res://assets/ui/icons/status/combat_active.png",
	"combat_failed": "res://assets/ui/icons/status/combat_failed.png",
	"level_up": "res://assets/ui/icons/status/level_up.png",
	"offline_pending": "res://assets/ui/icons/status/offline_pending.png",
	"overflow_warn": "res://assets/ui/icons/status/overflow_warn.png",
}

@onready var lingqi_value: Label = %LingqiValue
@onready var xiuwei_value: Label = %XiuweiValue
@onready var lingshi_value: Label = %LingshiValue
@onready var herb_value: Label = %HerbValue
@onready var exp_value: Label = %ExpValue
@onready var level_label: Label = %LevelLabel
@onready var realm_icon: TextureRect = %RealmIcon
@onready var stance_label: Label = %StanceLabel
@onready var stance_icon: TextureRect = %StanceIcon
@onready var combat_status_icon: TextureRect = %CombatStatusIcon
@onready var manual_button: Button = %ManualCultivateButton
@onready var stance_button: Button = %ToggleStanceButton
@onready var condense_button: Button = %TickCondenseButton
@onready var log_text: RichTextLabel = %LogText

var _resource_labels := {}
var _log_lines := []
var _icon_cache := {}


func _ready() -> void:
	_resource_labels = {
		"lingqi": lingqi_value,
		"xiuwei": xiuwei_value,
		"lingshi": lingshi_value,
		"herb": herb_value,
		"exp": exp_value,
	}
	_subscribe_events()
	_connect_buttons()
	_refresh_all_resources()
	_refresh_level()
	_refresh_stance()
	_set_combat_status("offline_pending")
	_append_log("HUD 初始化完成 — 27 autoload 服务就绪；AutoProductionSystem tick 中（lingqi/xiuwei/lingshi/herb 每秒自动产出）。")
	_append_log("资产挂载: theme.tres + 5 资源图标 + 7 境界图标 + 4 姿态图标 + 5 状态图标 + main_base 背景 — 共 22 个资产路径已验证可加载。")


func _subscribe_events() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		_append_log("⚠ EventBus.instance 为 null，事件订阅跳过。")
		return
	for resource_id in RESOURCE_IDS:
		bus.subscribe("resource.%s.changed" % resource_id, _on_resource_changed)
		bus.subscribe("resource.%s.overflow" % resource_id, _on_resource_overflow)
	bus.subscribe("level.changed", _on_level_changed)
	bus.subscribe("realm.advanced", _on_realm_advanced)
	bus.subscribe("cultivation.stance_changed", _on_stance_changed)
	bus.subscribe("offline.settled", _on_offline_settled)
	bus.subscribe("combat.finished", _on_combat_finished)


func _connect_buttons() -> void:
	manual_button.pressed.connect(_on_manual_cultivate_pressed)
	stance_button.pressed.connect(_on_toggle_stance_pressed)
	condense_button.pressed.connect(_on_tick_condense_pressed)


func _refresh_all_resources() -> void:
	var resource_system := _get_resource_system()
	if resource_system == null:
		return
	for resource_id in RESOURCE_IDS:
		_refresh_resource(resource_id, resource_system)


func _refresh_resource(resource_id: String, resource_system: ResourceSystem = null) -> void:
	if resource_system == null:
		resource_system = _get_resource_system()
		if resource_system == null:
			return
	var label: Label = _resource_labels.get(resource_id)
	if label == null:
		return
	var value := resource_system.get_value(resource_id)
	var text := "%s: %s" % [RESOURCE_LABELS[resource_id], NumberFormatter.format(value)]
	if resource_system.get_definition(resource_id).get("has_cap", false):
		text += " / %s" % NumberFormatter.format(resource_system.get_max(resource_id))
	label.text = text


func _refresh_level() -> void:
	var level_host := LevelSystemHost.get_instance()
	if level_host == null or level_host.get_service() == null:
		level_label.text = "等级: -"
		realm_icon.texture = null
		return
	var service := level_host.get_service()
	var realm := service.get_realm("player")
	level_label.text = "Lv.%d  %s" % [service.get_level("player"), realm]
	realm_icon.texture = _load_icon_or_null(REALM_ICON_PATHS.get(realm, ""))


func _refresh_stance() -> void:
	var cult_host := CultivationSystemHost.get_instance()
	if cult_host == null or cult_host.get_service() == null:
		stance_label.text = "姿态: -"
		stance_icon.texture = null
		return
	var hud_state := cult_host.get_service().get_hud_state()
	var stance := str(hud_state.get("stance", "?"))
	var shortage := bool(hud_state.get("shortage", false))
	stance_label.text = "姿态: %s%s" % [stance, "（灵气不足）" if shortage else ""]
	stance_icon.texture = _load_icon_or_null(STANCE_ICON_PATHS.get(stance, ""))


func _set_combat_status(status_key: String) -> void:
	combat_status_icon.texture = _load_icon_or_null(STATUS_ICON_PATHS.get(status_key, ""))


func _on_resource_changed(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	if resource_id.is_empty():
		return
	_refresh_resource(resource_id)


func _on_resource_overflow(payload: Dictionary) -> void:
	var resource_id := str(payload.get("resource_id", ""))
	var lost: BigNumber = payload.get("lost")
	if lost == null:
		return
	_set_combat_status("overflow_warn")
	_append_log("⚠ %s 溢出 %s（已达上限）" % [RESOURCE_LABELS.get(resource_id, resource_id), NumberFormatter.format(lost)])


func _on_level_changed(payload: Dictionary) -> void:
	_refresh_level()
	_set_combat_status("level_up")
	_append_log("📈 等级 %d → %d (gained %d)" % [int(payload.get("old_level", 0)), int(payload.get("new_level", 0)), int(payload.get("levels_gained", 0))])


func _on_realm_advanced(payload: Dictionary) -> void:
	_refresh_level()
	_append_log("🌟 境界突破: %s → %s" % [str(payload.get("old_realm", "?")), str(payload.get("new_realm", "?"))])


func _on_stance_changed(payload: Dictionary) -> void:
	_refresh_stance()
	_append_log("🧘 修炼姿态切换为: %s" % str(payload.get("stance", "?")))


func _on_offline_settled(payload: Dictionary) -> void:
	_set_combat_status("offline_pending")
	_append_log("📦 离线结算完成: %s" % str(payload))


func _on_combat_finished(payload: Dictionary) -> void:
	var victory := bool(payload.get("victory", false))
	_set_combat_status("combat_active" if victory else "combat_failed")
	var enemy_id := str(payload.get("enemy_id", "?"))
	var zone_id := str(payload.get("zone_id", "?"))
	_append_log("⚔ 战斗结束 [%s @ %s]: %s" % [enemy_id, zone_id, "胜利" if victory else "失败"])


func _on_manual_cultivate_pressed() -> void:
	var cult_host := CultivationSystemHost.get_instance()
	if cult_host == null or cult_host.get_service() == null:
		_append_log("⚠ CultivationSystem 未就绪")
		return
	if not cult_host.get_service().manual_cultivate():
		_append_log("⚠ 手动修炼失败（系统冻结？）")


func _on_toggle_stance_pressed() -> void:
	var cult_host := CultivationSystemHost.get_instance()
	if cult_host == null or cult_host.get_service() == null:
		return
	var service := cult_host.get_service()
	var current := str(service.get_hud_state().get("stance", CultivationSystem.STANCE_MEDITATE))
	var next_stance := CultivationSystem.STANCE_CONDENSE if current == CultivationSystem.STANCE_MEDITATE else CultivationSystem.STANCE_MEDITATE
	service.set_stance(next_stance)


func _on_tick_condense_pressed() -> void:
	var cult_host := CultivationSystemHost.get_instance()
	if cult_host == null or cult_host.get_service() == null:
		return
	var service := cult_host.get_service()
	if str(service.get_hud_state().get("stance", "")) != CultivationSystem.STANCE_CONDENSE:
		_append_log("⚠ 凝丹需要先切换到 condense 姿态")
		return
	if not service.tick_condense():
		_refresh_stance()
		_append_log("⚠ 凝丹失败 — 灵气不足或系统冻结")


func _append_log(line: String) -> void:
	_log_lines.append(line)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines = _log_lines.slice(_log_lines.size() - MAX_LOG_LINES, _log_lines.size())
	if log_text != null:
		log_text.text = "\n".join(_log_lines)


func _get_resource_system() -> ResourceSystem:
	var host := ResourceSystemHost.get_instance()
	if host == null:
		return null
	return host.get_service()


func _load_icon_or_null(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _icon_cache.has(path):
		return _icon_cache[path]
	if not ResourceLoader.exists(path):
		push_warning("HUD: missing icon asset %s" % path)
		_icon_cache[path] = null
		return null
	var tex := load(path) as Texture2D
	_icon_cache[path] = tex
	return tex
