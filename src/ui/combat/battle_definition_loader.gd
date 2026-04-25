extends RefCounted

## Load a battle definition from a JSON file under res://.
static func load_definition(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Battle definition not found: " + path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Battle definition must be a JSON object: " + path)
		return {}

	return parsed

## Convert a team name from a battle definition into a CombatSystem team enum.
static func resolve_team(value: String) -> int:
	if value == "player":
		return CombatSystem.Team.PLAYER
	if value == "enemy":
		return CombatSystem.Team.ENEMY
	return CombatSystem.Team.ENEMY

## Convert a resource id from a battle definition into a ResourceTypes id.
static func resolve_resource_id(value: String) -> int:
	match value:
		"gold":
			return ResourceTypes.ResourceId.GOLD
		"basic_material":
			return ResourceTypes.ResourceId.BASIC_MATERIAL
		"fruit_str":
			return ResourceTypes.ResourceId.FRUIT_STR
		"protect_symbol":
			return ResourceTypes.ResourceId.PROTECT_SYMBOL
		_:
			return ResourceTypes.ResourceId.GOLD

## Convert an equipment slot id from a battle definition into an equipment slot enum.
static func resolve_equipment_slot(value: String) -> int:
	match value:
		"weapon":
			return EquipmentDefinitions.Slot.WEAPON
		"armor":
			return EquipmentDefinitions.Slot.ARMOR
		"helmet":
			return EquipmentDefinitions.Slot.HELMET
		"legs":
			return EquipmentDefinitions.Slot.LEGS
		"boots":
			return EquipmentDefinitions.Slot.BOOTS
		"accessory":
			return EquipmentDefinitions.Slot.ACCESSORY
		_:
			return EquipmentDefinitions.Slot.WEAPON

## Convert an equipment quality id from a battle definition into a quality enum.
static func resolve_equipment_quality(value: String) -> int:
	match value:
		"white":
			return EquipmentDefinitions.Quality.WHITE
		"green":
			return EquipmentDefinitions.Quality.GREEN
		"blue":
			return EquipmentDefinitions.Quality.BLUE
		"purple":
			return EquipmentDefinitions.Quality.PURPLE
		"gold":
			return EquipmentDefinitions.Quality.GOLD
		_:
			return EquipmentDefinitions.Quality.WHITE

## Convert a class id from a battle definition into a ClassNames id.
static func resolve_class_id(value: String) -> int:
	match value:
		"basic_mage":
			return ClassNames.ClassID.BASIC_MAGE
		"basic_archer":
			return ClassNames.ClassID.BASIC_ARCHER
		"basic_rogue":
			return ClassNames.ClassID.BASIC_ROGUE
		"basic_cleric":
			return ClassNames.ClassID.BASIC_CLERIC
		"basic_knight":
			return ClassNames.ClassID.BASIC_KNIGHT
		"adv_swordmaster":
			return ClassNames.ClassID.ADV_SWORDMASTER
		"adv_battlemage":
			return ClassNames.ClassID.ADV_BATTLEMAGE
		"adv_marksman":
			return ClassNames.ClassID.ADV_MARKSMAN
		"adv_assassin":
			return ClassNames.ClassID.ADV_ASSASSIN
		"adv_highcleric":
			return ClassNames.ClassID.ADV_HIGHCLERIC
		"adv_paladin":
			return ClassNames.ClassID.ADV_PALADIN
		"spc_dragonknight":
			return ClassNames.ClassID.SPC_DRAGONKNIGHT
		"spc_nightshade":
			return ClassNames.ClassID.SPC_NIGHTSHADE
		"spc_sovereign":
			return ClassNames.ClassID.SPC_SOVEREIGN
		_:
			return ClassNames.ClassID.BASIC_WARRIOR

## Convert an enemy reward tier from a battle definition into settlement tiers.
static func resolve_enemy_tier(value: String) -> int:
	match value:
		"elite":
			return DropCalculator.EnemyTier.ELITE
		"hard":
			return DropCalculator.EnemyTier.HARD
		"boss":
			return DropCalculator.EnemyTier.BOSS
		_:
			return DropCalculator.EnemyTier.NORMAL

## Convert a weapon type id from a battle definition into a tactical enum.
static func resolve_weapon_type(value: String) -> int:
	match value:
		"spear":
			return TacticalFormulas.WeaponType.SPEAR
		"axe":
			return TacticalFormulas.WeaponType.AXE
		"bow":
			return TacticalFormulas.WeaponType.BOW
		"magic":
			return TacticalFormulas.WeaponType.MAGIC
		"fist":
			return TacticalFormulas.WeaponType.FIST
		_:
			return TacticalFormulas.WeaponType.SWORD

## Convert an element id from a battle definition into a tactical enum.
static func resolve_element(value: String) -> int:
	match value:
		"fire":
			return TacticalFormulas.Element.FIRE
		"water":
			return TacticalFormulas.Element.WATER
		"wind":
			return TacticalFormulas.Element.WIND
		"earth":
			return TacticalFormulas.Element.EARTH
		"electric":
			return TacticalFormulas.Element.ELECTRIC
		_:
			return TacticalFormulas.Element.NONE

## Convert a terrain id from a battle definition into a terrain enum.
static func resolve_terrain(value: String) -> int:
	match value:
		"grass":
			return TerrainTypes.Terrain.GRASS
		"water":
			return TerrainTypes.Terrain.WATER_PUDDLE
		"sand":
			return TerrainTypes.Terrain.SAND
		"mud":
			return TerrainTypes.Terrain.MUD
		"highland":
			return TerrainTypes.Terrain.HIGHLAND
		"obstacle":
			return TerrainTypes.Terrain.OBSTACLE
		_:
			return TerrainTypes.Terrain.NORMAL

## Convert an AI type id from a battle definition into an AI enum.
static func resolve_ai_type(value: String) -> int:
	match value:
		"aggressive":
			return AI.AIType.AGGRESSIVE
		"defensive":
			return AI.AIType.DEFENSIVE
		"support":
			return AI.AIType.SUPPORT
		"control":
			return AI.AIType.CONTROL
		_:
			return AI.AIType.BALANCED

## Convert an affix type id from a battle definition into an affix enum.
static func resolve_affix_type(value: String) -> int:
	match value:
		"str":
			return EquipmentDefinitions.AffixType.STR
		"agi":
			return EquipmentDefinitions.AffixType.AGI
		"hp":
			return EquipmentDefinitions.AffixType.HP
		"mp":
			return EquipmentDefinitions.AffixType.INT
		_:
			return EquipmentDefinitions.AffixType.STR

## Convert an attribute id from a battle definition into an attribute enum.
static func resolve_attribute(value: String) -> int:
	match value:
		"str":
			return AttributeNames.Attribute.STR
		"agi":
			return AttributeNames.Attribute.AGI
		_:
			return AttributeNames.Attribute.STR
