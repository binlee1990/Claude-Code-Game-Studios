# Autoload: SceneManager
extends Node

const SCENES := {
	"main_menu": "res://src/ui/menu/main_menu.tscn",
	"battle": "res://src/ui/combat/battle_arena.tscn"
}

func switch_scene(scene_key: String) -> void:
	var path: String = SCENES.get(scene_key, "")
	if path.is_empty():
		push_error("Unknown scene: " + scene_key)
		return

	get_tree().change_scene_to_file(path)
