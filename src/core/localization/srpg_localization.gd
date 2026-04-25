class_name SRPGLocalization
extends RefCounted

## Small runtime text catalog for the current production slice.
## It keeps player-facing labels centralized until full Godot Translation
## resources are warranted.

const DEFAULT_LOCALE := "zh_CN"

const _CATALOG := {
	"zh_CN": {
		"game.title": "江湖试锋",
		"main.subtitle": "第一章三战闭环已接入正式存档路径",
		"main.seal": "斩敌不是炫技，是一招定局。",
		"menu.manage": "管理大屏",
		"management.title": "战役整备",
		"management.rewards": "奖励结算",
		"management.camp": "回营训练",
		"management.party": "队伍编成",
		"management.equipment": "装备管理",
		"management.close": "关闭",
		"audio.enabled": "生成式音效已启用",
		"release.channel": "本地 Windows Release",
	},
	"en_US": {
		"game.title": "Edge of Jianghu",
		"main.subtitle": "Chapter 1 three-battle loop is now on the formal save path",
		"main.seal": "A clean strike decides the field.",
		"menu.manage": "Manage",
		"management.title": "Campaign Readiness",
		"management.rewards": "Rewards",
		"management.camp": "Camp",
		"management.party": "Party",
		"management.equipment": "Equipment",
		"management.close": "Close",
		"audio.enabled": "Generated audio cues enabled",
		"release.channel": "Local Windows Release",
	},
}

static func translate(key: String, locale: String = DEFAULT_LOCALE) -> String:
	var bundle: Dictionary = _CATALOG.get(locale, {})
	if bundle.has(key):
		return String(bundle[key])
	var fallback: Dictionary = _CATALOG.get(DEFAULT_LOCALE, {})
	return String(fallback.get(key, key))

static func supported_locales() -> Array[String]:
	var locales: Array[String] = []
	for locale in _CATALOG.keys():
		locales.append(String(locale))
	locales.sort()
	return locales

static func catalog_size(locale: String = DEFAULT_LOCALE) -> int:
	return (_CATALOG.get(locale, {}) as Dictionary).size()
