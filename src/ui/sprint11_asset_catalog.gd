## Sprint11AssetCatalog centralizes every Sprint 11 visual asset path.
##
## UI code uses this catalog instead of reconstructing paths ad hoc. The
## asset-coverage smoke script also scans this file, so future asset changes
## have one stable place to update.
class_name Sprint11AssetCatalog
extends RefCounted


const THEME := "res://assets/ui/theme.tres"

const FRAMES := {
	"panel_primary": "res://assets/ui/frames/panel_primary.png",
	"panel_secondary": "res://assets/ui/frames/panel_secondary.png",
	"panel_elevated": "res://assets/ui/frames/panel_elevated.png",
	"button_states": "res://assets/ui/frames/button_states.png",
}

const RESOURCE_ICONS := {
	"lingqi": "res://assets/ui/icons/resources/lingqi.png",
	"xiuwei": "res://assets/ui/icons/resources/xiuwei.png",
	"lingshi": "res://assets/ui/icons/resources/lingshi.png",
	"herb": "res://assets/ui/icons/resources/herb.png",
	"exp": "res://assets/ui/icons/resources/exp.png",
}

const REALM_ICONS := {
	"fanren": "res://assets/ui/icons/realm/mortal.png",
	"lianqi": "res://assets/ui/icons/realm/qi_refining.png",
	"zhuji": "res://assets/ui/icons/realm/foundation.png",
	"jindan": "res://assets/ui/icons/realm/golden_core.png",
	"yuanying": "res://assets/ui/icons/realm/yuanying.png",
	"huashen": "res://assets/ui/icons/realm/huashen.png",
	"heti": "res://assets/ui/icons/realm/heti.png",
}

const STANCE_ICONS := {
	"meditate": "res://assets/ui/icons/stances/meditate.png",
	"condense": "res://assets/ui/icons/stances/condense.png",
	"closed_door": "res://assets/ui/icons/stances/closed_door.png",
	"idle": "res://assets/ui/icons/stances/idle.png",
}

const STATUS_ICONS := {
	"combat_active": "res://assets/ui/icons/status/combat_active.png",
	"combat_failed": "res://assets/ui/icons/status/combat_failed.png",
	"level_up": "res://assets/ui/icons/status/level_up.png",
	"offline_pending": "res://assets/ui/icons/status/offline_pending.png",
	"overflow_warn": "res://assets/ui/icons/status/overflow_warn.png",
}

const RARITY_FRAMES := {
	"common": "res://assets/ui/icons/rarity/common_frame.png",
	"uncommon": "res://assets/ui/icons/rarity/uncommon_frame.png",
	"rare": "res://assets/ui/icons/rarity/rare_frame.png",
	"epic": "res://assets/ui/icons/rarity/epic_frame.png",
	"legendary": "res://assets/ui/icons/rarity/legendary_frame.png",
	"mythic": "res://assets/ui/icons/rarity/mythic_frame.png",
	"innate": "res://assets/ui/icons/rarity/innate_frame.png",
	"chaos": "res://assets/ui/icons/rarity/chaos_frame.png",
}

const SEALS := {
	"burst_gold": "res://assets/ui/seals/burst_gold.png",
	"failure_red": "res://assets/ui/seals/failure_red.png",
	"ink_default": "res://assets/ui/seals/ink_default.png",
}

const MAPS := {
	"main_base": "res://assets/map/main_base.png",
	"starter_forest": "res://assets/map/starter_forest.png",
	"east_sea_shore": "res://assets/map/east_sea_shore.png",
	"ruined_temple": "res://assets/map/ruined_temple.png",
	"town_economy": "res://assets/map/town_economy.png",
}

const OVERLAYS := {
	"failure_grey": "res://assets/overlays/failure_grey.png",
	"offline_paper": "res://assets/overlays/offline_paper.png",
}

const PLAYER := {
	"portrait": "res://assets/characters/player/portrait.png",
	"idle": "res://assets/characters/player/idle_sheet.png",
	"attack": "res://assets/characters/player/attack_sheet.png",
	"hurt": "res://assets/characters/player/hurt_sheet.png",
	"death": "res://assets/characters/player/death_sheet.png",
}

const ENEMY_ASSETS := {
	"forest_wolf": {
		"portrait": "res://assets/enemies/starter_zone/forest_wolf_portrait.png",
		"idle": "res://assets/enemies/starter_zone/forest_wolf_idle.png",
		"attack": "res://assets/enemies/starter_zone/forest_wolf_attack.png",
	},
	"low_yao_qi": {
		"portrait": "res://assets/enemies/starter_zone/low_yao_qi_portrait.png",
		"idle": "res://assets/enemies/starter_zone/low_yao_qi_idle.png",
		"attack": "res://assets/enemies/starter_zone/low_yao_qi_attack.png",
	},
	"mountain_rat": {
		"portrait": "res://assets/enemies/starter_zone/mountain_rat_portrait.png",
		"idle": "res://assets/enemies/starter_zone/mountain_rat_idle.png",
		"attack": "res://assets/enemies/starter_zone/mountain_rat_attack.png",
	},
	"cold_corpse": {
		"portrait": "res://assets/enemies/mid_zone/cold_corpse_portrait.png",
		"idle": "res://assets/enemies/mid_zone/cold_corpse_idle.png",
		"attack": "res://assets/enemies/mid_zone/cold_corpse_attack.png",
	},
	"evil_disciple": {
		"portrait": "res://assets/enemies/mid_zone/evil_disciple_portrait.png",
		"idle": "res://assets/enemies/mid_zone/evil_disciple_idle.png",
		"attack": "res://assets/enemies/mid_zone/evil_disciple_attack.png",
	},
	"ghost_flame": {
		"portrait": "res://assets/enemies/mid_zone/ghost_flame_portrait.png",
		"idle": "res://assets/enemies/mid_zone/ghost_flame_idle.png",
		"projectile": "res://assets/enemies/mid_zone/ghost_flame_projectile.png",
	},
	"broken_dragon_shadow": {
		"portrait": "res://assets/enemies/end_zone/broken_dragon_shadow_portrait.png",
		"idle": "res://assets/enemies/end_zone/broken_dragon_shadow_idle.png",
		"attack": "res://assets/enemies/end_zone/broken_dragon_shadow_attack.png",
	},
	"reef_shark": {
		"portrait": "res://assets/enemies/end_zone/reef_shark_portrait.png",
		"idle": "res://assets/enemies/end_zone/reef_shark_idle.png",
		"attack": "res://assets/enemies/end_zone/reef_shark_attack.png",
	},
	"sea_yao": {
		"portrait": "res://assets/enemies/end_zone/sea_yao_portrait.png",
		"idle": "res://assets/enemies/end_zone/sea_yao_idle.png",
		"attack": "res://assets/enemies/end_zone/sea_yao_attack.png",
	},
	"mountain_bandit": {
		"portrait": "res://assets/enemies/current/mountain_bandit_portrait.png",
		"idle": "res://assets/enemies/current/mountain_bandit_idle.png",
		"attack": "res://assets/enemies/current/mountain_bandit_attack.png",
	},
	"training_dummy": {
		"portrait": "res://assets/enemies/current/training_dummy_portrait.png",
		"idle": "res://assets/enemies/current/training_dummy_idle.png",
		"attack": "res://assets/enemies/current/training_dummy_attack.png",
	},
	"wild_wolf": {
		"portrait": "res://assets/enemies/current/wild_wolf_portrait.png",
		"idle": "res://assets/enemies/current/wild_wolf_idle.png",
		"attack": "res://assets/enemies/current/wild_wolf_attack.png",
	},
}

const ITEM_ICONS := {
	"low_lingshi": "res://assets/items/low_lingshi.png",
	"mid_lingshi": "res://assets/items/mid_lingshi.png",
	"high_lingshi": "res://assets/items/high_lingshi.png",
	"pure_qi_crystal": "res://assets/items/pure_qi_crystal.png",
	"talisman_paper": "res://assets/items/talisman_paper.png",
	"blood_ginseng": "res://assets/items/blood_ginseng.png",
	"ling_grass": "res://assets/items/ling_grass.png",
	"iron_ore": "res://assets/items/iron_ore.png",
	"dragon_scale": "res://assets/items/dragon_scale.png",
	"sea_pearl": "res://assets/items/sea_pearl.png",
	"evil_dust": "res://assets/items/evil_dust.png",
	"low_pill": "res://assets/items/low_pill.png",
	"item_pack_basic_sheet": "res://assets/items/item_pack_basic_sheet.png",
	"item_pack_rare_sheet": "res://assets/items/item_pack_rare_sheet.png",
}

const VFX := {
	"crit_hit_spark": "res://assets/vfx/crit_hit_spark.png",
	"level_up_ring": "res://assets/vfx/level_up_ring.png",
	"manual_click_pulse": "res://assets/vfx/manual_click_pulse.png",
	"overflow_warn_flash": "res://assets/vfx/overflow_warn_flash.png",
	"victory_burst_gold": "res://assets/vfx/victory_burst_gold.png",
	"zone_transition_ink_wipe_01": "res://assets/vfx/zone_transition_ink_wipe_01.png",
	"zone_transition_ink_wipe_02": "res://assets/vfx/zone_transition_ink_wipe_02.png",
	"zone_transition_ink_wipe_03": "res://assets/vfx/zone_transition_ink_wipe_03.png",
	"zone_transition_ink_wipe_04": "res://assets/vfx/zone_transition_ink_wipe_04.png",
}


static func texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func get_texture(group: Dictionary, key: String) -> Texture2D:
	return texture(str(group.get(key, "")))


static func enemy_texture(enemy_id: String, kind: String) -> Texture2D:
	var entry: Dictionary = ENEMY_ASSETS.get(enemy_id, {})
	return texture(str(entry.get(kind, "")))
