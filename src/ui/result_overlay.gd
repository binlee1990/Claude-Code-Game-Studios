class_name ResultOverlay extends CanvasLayer

@onready var _background: ColorRect = %Background
@onready var _title_label: Label = %TitleLabel
@onready var _reason_label: Label = %ReasonLabel
@onready var _play_again_button: Button = %PlayAgainButton

func _ready() -> void:
	_play_again_button.pressed.connect(_on_play_again_pressed)

func initialize(turn_manager: TurnManager) -> void:
	if not turn_manager.match_ended.is_connected(_on_match_ended):
		turn_manager.match_ended.connect(_on_match_ended)
	_background.visible = false
	_title_label.visible = false
	_reason_label.visible = false
	_play_again_button.visible = false

func _on_match_ended(reason: String, winner: Faction.Type) -> void:
	_background.visible = true
	_title_label.visible = true
	_reason_label.visible = true
	_play_again_button.visible = true

	match winner:
		Faction.Type.PLAYER:
			_title_label.text = "VICTORY"
			_title_label.modulate = Color("#10B981")
		Faction.Type.ENEMY:
			_title_label.text = "DEFEAT"
			_title_label.modulate = Color("#EF4444")
		_:
			_title_label.text = "DRAW"
			_title_label.modulate = Color("#9CA3AF")

	_reason_label.text = reason

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()
