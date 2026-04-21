# Autoload: SaveManager
extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 8

var _current_slot: int = -1

func save_game(slot: int) -> bool:
	var save_data := SaveData.new()
	save_data.timestamp = Time.get_unix_time_from_system()

	var path := SAVE_DIR + "save_%d.tres" % slot
	var result := ResourceSaver.save(save_data, path)
	if result == OK:
		_current_slot = slot
		GameEvents.game_saved.emit(slot, save_data.timestamp)
		return true
	return false

func load_game(slot: int) -> bool:
	var path := SAVE_DIR + "save_%d.tres" % slot
	if not FileAccess.file_exists(path):
		return false

	var save_data := load(path) as SaveData
	if save_data == null:
		return false

	_current_slot = slot
	GameEvents.game_loaded.emit(slot)
	return true

func has_save(slot: int) -> bool:
	var path := SAVE_DIR + "save_%d.tres" % slot
	return FileAccess.file_exists(path)
