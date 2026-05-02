class_name HUD extends CanvasLayer

const TurnState = preload("res://src/core/turn_state.gd")

var _turn_manager: TurnManager

@onready var _turn_label: Label = %TurnLabel
@onready var _faction_label: Label = %FactionLabel
@onready var _end_turn_button: Button = %EndTurnButton

func _ready() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)

func initialize(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager
	if not turn_manager.match_started.is_connected(_on_match_started):
		turn_manager.match_started.connect(_on_match_started)
	if not turn_manager.turn_started.is_connected(_on_turn_started):
		turn_manager.turn_started.connect(_on_turn_started)
	if not turn_manager.faction_activated.is_connected(_on_faction_activated):
		turn_manager.faction_activated.connect(_on_faction_activated)
	if not turn_manager.faction_phase_ended.is_connected(_on_faction_phase_ended):
		turn_manager.faction_phase_ended.connect(_on_faction_phase_ended)
	if not turn_manager.match_ended.is_connected(_on_match_ended):
		turn_manager.match_ended.connect(_on_match_ended)
	hide_all()

func hide_all() -> void:
	_turn_label.visible = false
	_faction_label.visible = false
	_end_turn_button.visible = false

func _on_match_started() -> void:
	_turn_label.visible = true
	_faction_label.visible = true
	_end_turn_button.visible = true

func _on_turn_started(turn_number: int) -> void:
	_turn_label.text = "Turn %d/%d" % [turn_number, _turn_manager.turn_cap]

func _on_faction_activated(faction: Faction.Type) -> void:
	match faction:
		Faction.Type.PLAYER:
			_faction_label.text = "Player Turn"
			_faction_label.modulate = Color("#3B82F6")
		Faction.Type.ENEMY:
			_faction_label.text = "Enemy Turn"
			_faction_label.modulate = Color("#EF4444")
	_end_turn_button.visible = true

func _on_faction_phase_ended(_faction: Faction.Type) -> void:
	_end_turn_button.visible = false

func _on_match_ended(_reason: String, _winner: Faction.Type) -> void:
	_end_turn_button.visible = false

func _on_end_turn_pressed() -> void:
	_turn_manager.end_current_faction_turn()
