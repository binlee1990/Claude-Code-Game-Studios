class_name SaveData
extends Resource

## Serializable game state container.
## All persistent data that survives between sessions is stored here.

@export var version: int = 1
@export var timestamp: int = 0
@export var playtime: int = 0

@export var party_units: Array = []
@export var inventory_items: Array = []
@export var story_progress: Dictionary = {}
@export var achievement_points: int = 0

func serialize() -> Dictionary:
	return {
		"version": version,
		"timestamp": timestamp,
		"playtime": playtime,
		"party_units": party_units,
		"inventory_items": inventory_items,
		"story_progress": story_progress,
		"achievement_points": achievement_points
	}

static func deserialize(data: Dictionary) -> SaveData:
	var sd := SaveData.new()
	sd.version = data.get("version", 1)
	sd.timestamp = data.get("timestamp", 0)
	sd.playtime = data.get("playtime", 0)
	sd.party_units = data.get("party_units", [])
	sd.inventory_items = data.get("inventory_items", [])
	sd.story_progress = data.get("story_progress", {})
	sd.achievement_points = data.get("achievement_points", 0)
	return sd
