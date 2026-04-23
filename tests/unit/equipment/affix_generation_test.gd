extends Gut

func test_blue_attack_affix_value_range() -> void:
	var affix: Dictionary = EquipmentAffixGenerator.generate_affix(
		EquipmentDefinitions.Quality.BLUE,
		EquipmentDefinitions.AffixType.STR,
		42
	)
	assert_eq(affix["attribute_type"], AttributeNames.Attribute.STR)
	assert_true(affix["value"] >= 8 and affix["value"] <= 24)

func test_affix_type_variety_and_special_rarity() -> void:
	var counts: Dictionary = {
		EquipmentDefinitions.AffixCategory.ATTACK: 0,
		EquipmentDefinitions.AffixCategory.DEFENSE: 0,
		EquipmentDefinitions.AffixCategory.SURVIVAL: 0,
		EquipmentDefinitions.AffixCategory.SPECIAL: 0,
	}
	for i in range(1, 201):
		var affix: Dictionary = EquipmentAffixGenerator.generate_affix(EquipmentDefinitions.Quality.PURPLE, -1, i)
		counts[affix["category"]] += 1
	assert_true(counts[EquipmentDefinitions.AffixCategory.ATTACK] > 0)
	assert_true(counts[EquipmentDefinitions.AffixCategory.DEFENSE] > 0)
	assert_true(counts[EquipmentDefinitions.AffixCategory.SURVIVAL] > 0)
	assert_true(counts[EquipmentDefinitions.AffixCategory.SPECIAL] > 0)
	assert_true(counts[EquipmentDefinitions.AffixCategory.SPECIAL] < counts[EquipmentDefinitions.AffixCategory.ATTACK])

func test_quality_range_mapping_for_purple_and_gold() -> void:
	var purple: Dictionary = EquipmentAffixGenerator.generate_affix(
		EquipmentDefinitions.Quality.PURPLE,
		EquipmentDefinitions.AffixType.STR,
		9
	)
	var gold: Dictionary = EquipmentAffixGenerator.generate_affix(
		EquipmentDefinitions.Quality.GOLD,
		EquipmentDefinitions.AffixType.STR,
		15
	)
	assert_true(purple["value"] >= 24 and purple["value"] <= 60)
	assert_true(gold["value"] >= 60 and gold["value"] <= 150)
