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

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

# ZONE SELECTOR
@onready var main_area: HBoxContainer = $MainArea
@onready var zone_tabs: HBoxContainer = %ZoneTabs
@onready var current_zone_label: Label = %CurrentZoneLabel

# ENEMY ZONE
@onready var zone_background: TextureRect = %ZoneBackground
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_name_label: Label = %EnemyNameLabel

# PLAYER STATUS
@onready var player_sprite: TextureRect = %PlayerSprite
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_atk_label: Label = %PlayerATKLabel

# CONTROL
@onready var pause_toggle: Button = %PauseToggle
@onready var resolve_btn: Button = %ResolveBtn

const ZONE_BACKGROUNDS: Dictionary = {
	"starter_valley": "res://assets/map/starter_forest.png",
	"pine_forest": "res://assets/map/starter_forest.png",
	"mist_peak": "res://assets/map/ruined_temple.png",
	"east_sea_shore": "res://assets/map/east_sea_shore.png",
}

var _combat_service: RefCounted = null
var _zone_service: RefCounted = null
var _attribute_service: RefCounted = null
var _enemy_database: RefCounted = null
var _zone_buttons: Array[Button] = []
var _zone_ids: Array[String] = []
var _active_zone_id: String = ""
var _paused: bool = false


func _ready() -> void:
	super._ready()
	_apply_compact_visual_layout()
	_resolve_services()
	_setup_player_spriteframes()
	_build_zone_tabs()
	_connect_buttons()
	_refresh_player_status()


func _apply_compact_visual_layout() -> void:
	if main_area != null:
		main_area.offset_bottom = -88.0
	if player_sprite != null:
		player_sprite.custom_minimum_size = Vector2(220, 220)


func on_activated() -> void:
	_subscribe("combat.finished", _on_encounter_finished)
	_subscribe("zone.changed", _on_zone_changed)
	_subscribe("level.changed", _refresh_player_status)
	_refresh_all()


func on_deactivated() -> void:
	_unsubscribe("combat.finished", _on_encounter_finished)
	_unsubscribe("zone.changed", _on_zone_changed)
	_unsubscribe("level.changed", _refresh_player_status)


func _resolve_services() -> void:
	var host := SemiAutoCombatSystemHost.get_instance()
	if host != null: _combat_service = host.get_service()
	var zone_host := ZoneSystemHost.get_instance()
	if zone_host != null: _zone_service = zone_host.get_service()
	var attr_host := AttributeSystemHost.get_instance()
	if attr_host != null: _attribute_service = attr_host.get_service()
	var enemy_host := EnemyDatabaseHost.get_instance()
	if enemy_host != null: _enemy_database = enemy_host.get_service()


func _build_zone_tabs() -> void:
	if zone_tabs == null:
		return
	for child in zone_tabs.get_children():
		child.queue_free()
	_zone_buttons.clear()
	_zone_ids.clear()
	var zones := _get_available_zones()
	for zone in zones:
		var zone_id := str(zone.get("id", ""))
		if zone_id.is_empty():
			continue
		var btn := Button.new()
		btn.text = tr(str(zone.get("name", zone_id)))
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(160, 44)
		btn.disabled = not bool(zone.get("unlocked", true))
		btn.pressed.connect(_on_zone_tab_pressed.bind(zone_id))
		zone_tabs.add_child(btn)
		_zone_buttons.append(btn)
		_zone_ids.append(zone_id)


func _connect_buttons() -> void:
	if pause_toggle != null:
		pause_toggle.pressed.connect(_on_pause_toggled)
	if resolve_btn != null:
		resolve_btn.pressed.connect(_on_resolve_pressed)


func _refresh_all() -> void:
	_refresh_zone_display()
	_refresh_enemy_display()
	_refresh_player_status()


# --- Zone ---
func _refresh_zone_display() -> void:
	if _zone_service == null:
		return
	var zone_id: String = ""
	var current_zone_value: Variant = _zone_service.get("current_zone_id")
	if current_zone_value != null:
		zone_id = str(current_zone_value)
	elif _zone_service.has_method("get_hud_state"):
		var state: Dictionary = _zone_service.get_hud_state()
		zone_id = str(state.get("current_zone", ""))
	if zone_id.is_empty() and not _zone_ids.is_empty():
		zone_id = _zone_ids[0]
	_active_zone_id = zone_id
	var zone_data := _get_zone_data(zone_id)
	if current_zone_label != null:
		current_zone_label.text = tr(str(zone_data.get("name", zone_id))) if not zone_id.is_empty() else tr("未选择区域")
	# Zone background
	if zone_background != null and not zone_id.is_empty():
		var bg_path: String = str(zone_data.get("background_path", ZONE_BACKGROUNDS.get(zone_id, Sprint11AssetCatalog.MAPS.get("starter_forest", ""))))
		if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
			zone_background.texture = load(bg_path) as Texture2D
	# Highlight active tab
	for i in range(_zone_buttons.size()):
		var btn := _zone_buttons[i]
		if i < _zone_ids.size() and _zone_ids[i] == _active_zone_id:
			var style := StyleBoxFlat.new()
			style.border_width_bottom = 2
			style.border_color = Color(0.961, 0.784, 0.259)
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.remove_theme_stylebox_override("normal")


# --- Enemy ---
func _refresh_enemy_display() -> void:
	if _combat_service == null:
		_display_preview_enemy()
		return
	if _combat_service.has_method("get_current_encounter"):
		var encounter: Dictionary = _combat_service.get_current_encounter()
		_display_encounter(encounter)
	else:
		_display_preview_enemy()


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
	var enemy_id := str(encounter.get("enemy_id", encounter.get("id", "")))
	_apply_enemy_texture(enemy_id)


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
	if _zone_service != null and _zone_service.has_method("select_zone"):
		var result: Dictionary = _zone_service.select_zone(zone_id)
		if not bool(result.get("ok", false)):
			_show_toast(tr("区域未解锁"))
	_refresh_all()


func _on_pause_toggled() -> void:
	_paused = not _paused
	if _combat_service != null and _combat_service.has_method("toggle_pause"):
		_combat_service.toggle_pause()
	if pause_toggle != null:
		pause_toggle.text = tr("继续战斗") if _paused else tr("暂停战斗")


func _on_resolve_pressed() -> void:
	if _combat_service == null or not _combat_service.has_method("resolve_encounter"):
		_show_toast(tr("战斗系统不可用"))
		return
	var player_snapshot := _player_combat_snapshot()
	if player_snapshot.is_empty():
		_show_toast(tr("玩家属性不可用"))
		return
	var result: Dictionary = _combat_service.resolve_encounter(player_snapshot, Time.get_ticks_msec())
	if result.has("result"):
		var combat_result: Dictionary = result["result"]
		if enemy_hp_bar != null:
			enemy_hp_bar.value = max(0.0, float(combat_result.get("enemy_hp", 0.0)))
		if player_hp_bar != null:
			player_hp_bar.value = max(0.0, float(combat_result.get("player_hp", player_hp_bar.value)))


func _on_encounter_finished(payload: Dictionary) -> void:
	if player_sprite != null:
		var victory := bool(payload.get("victory", false))
		_apply_player_state("idle" if victory else "death")
	_play_combat_vfx(bool(payload.get("victory", false)))
	_apply_enemy_texture(str(payload.get("enemy_id", "")))


func _on_zone_changed(_payload: Dictionary) -> void:
	_refresh_zone_display()
	_refresh_enemy_display()


func _get_available_zones() -> Array:
	if _zone_service != null and _zone_service.has_method("get_sorted_zones"):
		var zones: Array = _zone_service.get_sorted_zones()
		if not zones.is_empty():
			return zones
	return [
		{"id": "starter_valley", "name": "新手谷", "unlocked": true, "background_path": Sprint11AssetCatalog.MAPS["starter_forest"]},
		{"id": "pine_forest", "name": "松林", "unlocked": false, "background_path": Sprint11AssetCatalog.MAPS["starter_forest"]},
		{"id": "mist_peak", "name": "雾峰", "unlocked": false, "background_path": Sprint11AssetCatalog.MAPS["ruined_temple"]},
	]


func _get_zone_data(zone_id: String) -> Dictionary:
	if _zone_service != null and _zone_service.has_method("get_zone"):
		var zone: Dictionary = _zone_service.get_zone(zone_id)
		if not zone.is_empty():
			return zone
	for zone in _get_available_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _display_preview_enemy() -> void:
	var enemy_id := "training_dummy"
	if _zone_service != null and _zone_service.has_method("get_enemy_pool"):
		var pool: Array = _zone_service.get_enemy_pool(_active_zone_id)
		if not pool.is_empty():
			enemy_id = str(pool[0].get("enemy_id", enemy_id))
	var enemy_name := enemy_id
	var hp := 100.0
	if _enemy_database != null and _enemy_database.has_method("get_enemy"):
		var enemy: Dictionary = _enemy_database.get_enemy(enemy_id)
		if not enemy.is_empty():
			enemy_name = str(enemy.get("name", enemy_id))
			var attrs: Dictionary = enemy.get("base_attributes", {})
			hp = float(attrs.get("hp_max", 100.0))
	if enemy_name_label != null:
		enemy_name_label.text = tr(enemy_name)
	if enemy_hp_bar != null:
		enemy_hp_bar.max_value = hp
		enemy_hp_bar.value = hp
	_apply_enemy_texture(enemy_id)


func _apply_enemy_texture(enemy_id: String) -> void:
	if enemy_portrait == null:
		return
	var texture: Texture2D = null
	if _enemy_database != null and _enemy_database.has_method("get_enemy"):
		var enemy: Dictionary = _enemy_database.get_enemy(enemy_id)
		var art_paths: Dictionary = enemy.get("art_paths", {})
		texture = Sprint11AssetCatalog.texture(str(art_paths.get("portrait", "")))
	if texture == null:
		texture = Sprint11AssetCatalog.enemy_texture(enemy_id, "portrait")
	if texture == null:
		texture = Sprint11AssetCatalog.enemy_texture("training_dummy", "portrait")
	enemy_portrait.texture = texture


func _setup_player_spriteframes() -> void:
	if player_sprite == null:
		return
	player_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_apply_player_state("idle")


func _apply_player_state(state: String) -> void:
	if player_sprite == null:
		return
	var texture := _first_frame_from_player_sheet(state)
	if texture != null:
		player_sprite.texture = texture


func _first_frame_from_player_sheet(state: String) -> Texture2D:
	var sheet := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.PLAYER, state)
	if sheet == null:
		return null
	var frame_width := int(min(256.0, float(sheet.get_width())))
	var frame_height := int(min(256.0, float(sheet.get_height())))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, frame_width, frame_height)
	return atlas


func _play_combat_vfx(victory: bool) -> void:
	var tex := Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.VFX, "victory_burst_gold" if victory else "crit_hit_spark")
	if tex == null:
		return
	var burst := TextureRect.new()
	burst.texture = tex
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(burst)
	var tween := burst.create_tween().set_parallel(true)
	burst.modulate = Color(1, 1, 1, 0.85)
	tween.tween_property(burst, "modulate:a", 0.0, 0.8)
	tween.tween_property(burst, "scale", Vector2(1.08, 1.08), 0.8)
	tween.tween_callback(burst.queue_free)


func _show_toast(message: String) -> void:
	var rv := UIManagerHost.find_root_viewport()
	if rv != null:
		rv.show_toast(message)


func _player_combat_snapshot() -> Dictionary:
	if _attribute_service == null:
		return {}
	var raw := {}
	if _attribute_service.has_method("get_final_set"):
		raw = _attribute_service.get_final_set("player")
	elif _attribute_service.has_method("get_attribute_set"):
		raw = _attribute_service.get_attribute_set("player")
	var result := {}
	for field in ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"]:
		var value: Variant = raw.get(field, 0.0)
		if value is BigNumber:
			result[field] = value.to_float()
		else:
			result[field] = float(value)
	return result
