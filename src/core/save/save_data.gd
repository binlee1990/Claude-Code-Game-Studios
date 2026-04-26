class_name SaveData
extends Resource

## Serializable game state container.
## All persistent data that survives between sessions is stored here.

@export var version: int = 1
@export var timestamp: int = 0
@export var playtime: int = 0
@export var locale: String = ""

@export var party_units: Array = []
@export var inventory_items: Array = []
@export var story_progress: Dictionary = {}
@export var achievement_points: int = 0
@export var current_scene_key: String = ""
@export var settings: Dictionary = {}
@export var battle_state: Dictionary = {}
@export var camera_preferences: Dictionary = {}
@export var ui_preferences: Dictionary = {}
@export var inventory_state: Dictionary = {}
@export var battle_history: Dictionary = {}

func serialize() -> Dictionary:
	return {
		"version": version,
		"timestamp": timestamp,
		"playtime": playtime,
		"locale": locale,
		"party_units": party_units,
		"inventory_items": inventory_items,
		"story_progress": story_progress,
		"achievement_points": achievement_points,
		"current_scene_key": current_scene_key,
		"settings": settings,
		"battle_state": battle_state,
		"camera_preferences": camera_preferences,
		"ui_preferences": ui_preferences,
		"inventory_state": inventory_state,
		"battle_history": battle_history,
	}

static func deserialize(data: Dictionary) -> SaveData:
	var sd := SaveData.new()
	sd.version = data.get("version", 1)
	sd.timestamp = data.get("timestamp", 0)
	sd.playtime = data.get("playtime", 0)
	sd.locale = data.get("locale", "")
	sd.party_units = data.get("party_units", [])
	sd.inventory_items = data.get("inventory_items", [])
	sd.story_progress = data.get("story_progress", {})
	sd.achievement_points = data.get("achievement_points", 0)
	sd.current_scene_key = data.get("current_scene_key", "")
	sd.settings = data.get("settings", {})
	sd.battle_state = data.get("battle_state", {})
	sd.camera_preferences = data.get("camera_preferences", {})
	sd.ui_preferences = data.get("ui_preferences", {})
	sd.inventory_state = data.get("inventory_state", {})
	sd.battle_history = data.get("battle_history", {})
	return sd
