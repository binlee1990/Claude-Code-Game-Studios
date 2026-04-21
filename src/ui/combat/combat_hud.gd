class_name CombatHUD
extends Control

func _ready() -> void:
	GameEvents.turn_started.connect(_on_turn_started)
	GameEvents.health_changed.connect(_on_health_changed)

func _on_turn_started(actor_id: int, turn_number: int) -> void:
	pass # Update UI

func _on_health_changed(unit_id: int, old_hp: int, new_hp: int, cause: String) -> void:
	pass # Update HP bar
