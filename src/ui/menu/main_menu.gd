class_name MainMenu
extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var continue_button: Button = $VBox/ContinueButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	# 检查是否有存档
	continue_button.disabled = not SaveManager.has_save(1)

func _on_start_pressed() -> void:
	# 开始新游戏
	SceneManager.switch_scene("battle")

func _on_continue_pressed() -> void:
	# 加载存档
	SaveManager.load_game(1)
	SceneManager.switch_scene("battle")
