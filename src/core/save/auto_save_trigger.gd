extends Node

## Auto-save trigger that listens to combat end and saves the game.
## Attached to an autoloaded scene or a persistent node.

const AUTO_SAVE_SLOT := 0  # Dedicated slot for auto-saves

func _ready() -> void:
	GameEvents.combat_ended.connect(_on_combat_ended)

## Called when combat ends and triggers an auto-save.
func _on_combat_ended(winner: Node) -> void:
	_save_game()

func _save_game() -> void:
	var save_manager: SaveManager = SaveManager
	var success: bool = save_manager.save_game(AUTO_SAVE_SLOT)
	if not success:
		push_warning("Auto-save failed for slot %d" % AUTO_SAVE_SLOT)
