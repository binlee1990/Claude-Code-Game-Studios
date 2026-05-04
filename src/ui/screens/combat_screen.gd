## CombatScreen — 战斗屏 (S11-010).
##
## Layout per combat-screen UX spec:
##   ZONE SELECTOR (top): 3 horizontal zone tabs
##   ENEMY ZONE (center-left): zone background + enemy portrait + HP bar
##   PLAYER STATUS (center-right): 4-state sprite + HP/ATK bars
##   COMBAT LOG: P-FBK-03 in RIGHT PANEL (HUD shell)
##   CONTROL BAR (bottom): pause/resume toggle
##
## Follows BaseScreen lifecycle. Auto-combat runs via SemiAutoCombatSystem.
## Player selects zone, watches combat, switches zones when ready.
class_name CombatScreen
extends BaseScreen


# ZONE SELECTOR
@onready var zone_tabs: HBoxContainer = %ZoneTabs
@onready var current_zone_label: Label = %CurrentZoneLabel

# ENEMY ZONE
@onready var zone_background: TextureRect = %ZoneBackground
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_name_label: Label = %EnemyNameLabel

# PLAYER STATUS
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_atk_label: Label = %PlayerATKLabel

# CONTROL
@onready var pause_toggle: Button = %PauseToggle

const ZONE_BACKGROUNDS: Dictionary = {
	"starter_forest": "res://assets/ui/maps/starter_forest.png",
	"east_sea_shore": "res://assets/ui/maps/east_sea_shore.png",
	"ruined_temple": "res://assets/ui/maps/ruined_temple.png",
}

var _combat_service: RefCounted = null
var _zone_service: RefCounted = null
var _attribute_service: RefCounted = null
var _zone_buttons: Array[Button] = []
var _active_zone_id: String = ""
var _paused: bool = false


func _ready() -> void:
	super._ready()
	_resolve_services()
	_build_zone_tabs()
	_connect_buttons()
	_refresh_player_status()


func on_activated() -> void:
	_subscribe("combat.encounter_started", _on_encounter_started)
	_subscribe("combat.encounter_finished", _on_encounter_finished)
	_subscribe("zone.changed", _on_zone_changed)
	_subscribe("level.changed", _refresh_player_status)
	_refresh_all()


func on_deactivated() -> void:
	_unsubscribe("combat.encounter_started", _on_encounter_started)
	_unsubscribe("combat.encounter_finished", _on_encounter_finished)
	_unsubscribe("zone.changed", _on_zone_changed)
	_unsubscribe("level.changed", _refresh_player_status)


func _resolve_services() -> void:
	var host := SemiAutoCombatSystemHost.get_instance()
	if host != null: _combat_service = host.get_service()
	var zone_host := ZoneSystemHost.get_instance()
	if zone_host != null: _zone_service = zone_host.get_service()
	var attr_host := AttributeSystemHost.get_instance()
	if attr_host != null: _attribute_service = attr_host.get_service()


func _build_zone_tabs() -> void:
	if zone_tabs == null:
		return
	for child in zone_tabs.get_children():
		child.queue_free()
	_zone_buttons.clear()
	# MVP 3 zones: starter_forest, east_sea_shore, ruined_temple
	var zones := ["starter_forest", "east_sea_shore", "ruined_temple"]
	var zone_names := {"starter_forest": "新手森林", "east_sea_shore": "东海海岸", "ruined_temple": "破败神庙"}
	for zone_id in zones:
		var btn := Button.new()
		btn.text = tr(zone_names.get(zone_id, zone_id))
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(160, 44)
		btn.pressed.connect(_on_zone_tab_pressed.bind(zone_id))
		zone_tabs.add_child(btn)
		_zone_buttons.append(btn)


func _connect_buttons() -> void:
	if pause_toggle != null:
		pause_toggle.pressed.connect(_on_pause_toggled)


func _refresh_all() -> void:
	_refresh_zone_display()
	_refresh_enemy_display()
	_refresh_player_status()


# --- Zone ---
func _refresh_zone_display() -> void:
	if _zone_service == null:
		return
	var zone_id: String = ""
	if _zone_service.has_method("get_current_zone"):
		zone_id = _zone_service.get_current_zone()
	elif _zone_service.has_method("get_hud_state"):
		var state: Dictionary = _zone_service.get_hud_state()
		zone_id = str(state.get("current_zone", ""))
	_active_zone_id = zone_id
	if current_zone_label != null:
		current_zone_label.text = tr(zone_id) if not zone_id.is_empty() else tr("未选择区域")
	# Zone background
	if zone_background != null and not zone_id.is_empty():
		var bg_path: String = ZONE_BACKGROUNDS.get(zone_id, "")
		if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
			zone_background.texture = load(bg_path) as Texture2D
	# Highlight active tab
	for i in range(_zone_buttons.size()):
		var btn := _zone_buttons[i]
		var zones := ["starter_forest", "east_sea_shore", "ruined_temple"]
		if i < zones.size() and zones[i] == _active_zone_id:
			var style := StyleBoxFlat.new()
			style.border_width_bottom = 2
			style.border_color = Color(0.961, 0.784, 0.259)
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.remove_theme_stylebox_override("normal")


# --- Enemy ---
func _refresh_enemy_display() -> void:
	if _combat_service == null:
		return
	if _combat_service.has_method("get_current_encounter"):
		var encounter: Dictionary = _combat_service.get_current_encounter()
		_display_encounter(encounter)


func _display_encounter(encounter: Dictionary) -> void:
	if encounter.is_empty():
		if enemy_name_label != null:
			enemy_name_label.text = tr("待机中 — 选择区域开始战斗")
		if enemy_hp_bar != null:
			enemy_hp_bar.value = 0
		return
	var enemy_name := str(encounter.get("enemy_name", "?"))
	var hp_current: float = encounter.get("hp_current", 0.0)
	var hp_max: float = encounter.get("hp_max", 1.0)
	if enemy_name_label != null:
		enemy_name_label.text = tr(enemy_name)
	if enemy_hp_bar != null:
		enemy_hp_bar.max_value = hp_max
		enemy_hp_bar.value = hp_current


# --- Player ---
func _refresh_player_status(_payload: Dictionary = {}) -> void:
	if _attribute_service == null:
		return
	var hp: float = 100.0
	var hp_max: float = 100.0
	var atk: float = 10.0
	if _attribute_service.has_method("get_snapshot"):
		var snap: Dictionary = _attribute_service.get_snapshot("player")
		hp = float(snap.get("hp_current", 100.0))
		hp_max = float(snap.get("hp_max", 100.0))
		atk = float(snap.get("atk", 10.0))
	if player_hp_bar != null:
		player_hp_bar.max_value = hp_max
		player_hp_bar.value = hp
	if player_atk_label != null:
		player_atk_label.text = "%s: %.0f" % [tr("攻击"), atk]


# --- Callbacks ---
func _on_zone_tab_pressed(zone_id: String) -> void:
	if _zone_service != null and _zone_service.has_method("set_current_zone"):
		_zone_service.set_current_zone(zone_id)
	_refresh_all()


func _on_pause_toggled() -> void:
	_paused = not _paused
	if _combat_service != null and _combat_service.has_method("toggle_pause"):
		_combat_service.toggle_pause()
	if pause_toggle != null:
		pause_toggle.text = tr("继续战斗") if _paused else tr("暂停战斗")


func _on_encounter_started(_payload: Dictionary) -> void:
	_refresh_enemy_display()
	if player_sprite != null and player_sprite.sprite_frames != null:
		player_sprite.play("attack")


func _on_encounter_finished(payload: Dictionary) -> void:
	if player_sprite != null and player_sprite.sprite_frames != null:
		var victory := bool(payload.get("victory", false))
		player_sprite.play("idle" if victory else "death")


func _on_zone_changed(_payload: Dictionary) -> void:
	_refresh_zone_display()
	_refresh_enemy_display()
