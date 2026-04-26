extends Gut

func before_each() -> void:
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)

func after_each() -> void:
	SRPGLocalization.set_locale(SRPGLocalization.DEFAULT_LOCALE)

func test_catalog_keys_are_symmetric_between_supported_locales() -> void:
	var zh_missing := SRPGLocalization.missing_keys("zh_CN", "en_US")
	var en_missing := SRPGLocalization.missing_keys("en_US", "zh_CN")

	assert_eq(zh_missing.size(), 0, "zh_CN should not be missing keys present in en_US")
	assert_eq(en_missing.size(), 0, "en_US should not be missing keys present in zh_CN")
	assert_eq(
		SRPGLocalization.catalog_size("zh_CN"),
		SRPGLocalization.catalog_size("en_US"),
		"Localization catalogs should have 100% key parity"
	)

func test_runtime_locale_changes_translate_output() -> void:
	assert_true(SRPGLocalization.set_locale("en_US"))
	assert_eq(SRPGLocalization.get_locale(), "en_US")
	assert_eq(SRPGLocalization.translate("main.base"), "Base")

	assert_true(SRPGLocalization.set_locale("zh_CN"))
	assert_eq(SRPGLocalization.translate("main.base"), "基地")

func test_display_text_localizes_data_driven_names_for_current_locale() -> void:
	assert_true(SRPGLocalization.set_locale("zh_CN"))
	assert_eq(SRPGLocalization.display_text("Swordsman"), "剑士")
	assert_eq(SRPGLocalization.display_text("Bronze Sword"), "青铜剑")
	assert_eq(SRPGLocalization.display_text("Defend"), "防御")
	assert_eq(SRPGLocalization.display_text("First Playthrough Tutorial"), "首次游玩教学")

	assert_true(SRPGLocalization.set_locale("en_US"))
	assert_eq(SRPGLocalization.display_text("Swordsman"), "Swordsman")

func test_unsupported_locale_is_rejected() -> void:
	SRPGLocalization.set_locale("zh_CN")

	assert_false(SRPGLocalization.set_locale("fr_FR"))
	assert_eq(SRPGLocalization.get_locale(), "zh_CN")

func test_save_data_serializes_locale_field() -> void:
	var data := SaveData.new()
	data.locale = "en_US"
	data.settings["locale"] = "en_US"

	var restored := SaveData.deserialize(data.serialize())

	assert_eq(restored.locale, "en_US")
	assert_eq(String(restored.settings.get("locale", "")), "en_US")
