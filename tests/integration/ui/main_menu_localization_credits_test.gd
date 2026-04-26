extends Gut

var _menu: MainMenu

func before_each() -> void:
	_remove_settings_file()
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)
	var scene: PackedScene = load("res://src/ui/menu/main_menu.tscn")
	_menu = scene.instantiate()
	add_child(_menu)

func after_each() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)
	_remove_settings_file()

func test_language_button_switches_current_menu_text_and_persists_locale() -> void:
	var language_button := _menu.find_child("LanguageButton", true, false) as Button
	assert_ne(language_button, null, "Main menu should expose a language switch button")
	assert_eq(_menu.start_button.text, SRPGLocalization.translate("main.start_ch1"))

	language_button.pressed.emit()

	assert_eq(SRPGLocalization.get_locale(), "en_US")
	assert_eq(_menu.start_button.text, "Start Game (Chapter 1)")
	assert_eq(SaveManager.load_locale_preference(), "en_US")

func test_credits_route_renders_required_attribution() -> void:
	var credits_button := _menu.find_child("CreditsButton", true, false) as Button
	assert_ne(credits_button, null, "Main menu should expose a Credits button")

	credits_button.pressed.emit()

	assert_true(_menu._credits_layer.visible, "Credits layer should become visible from the main menu")
	var credits_text := _menu.get_credits_text()
	assert_true(credits_text.contains("Music by Kevin MacLeod (incompetech.com)"))
	assert_true(credits_text.contains("Creative Commons: By Attribution 3.0"))
	assert_true(credits_text.contains("SIL Open Font License 1.1"))

func _remove_settings_file() -> void:
	var path := "user://saves/settings.tres"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
