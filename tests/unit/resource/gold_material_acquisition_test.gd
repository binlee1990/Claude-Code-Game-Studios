# tests/unit/resource/gold_material_acquisition_test.gd
# Story 002: Gold & Material Acquisition
# Validates AC.2.1 through AC.2.3

extends Gut

# AC.2.1: Gold reward formula

func test_gold_normal_battle() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(50, 300, false)
	assert_eq(gold, 80, "50 + floor(300*0.1) + 0 = 80")

func test_gold_boss_kill() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(100, 800, true)
	assert_eq(gold, 200, "100 + floor(800*0.1) + 20 = 200")

func test_gold_zero_damage() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(50, 0, false)
	assert_eq(gold, 50, "Only base reward when 0 damage")

func test_gold_fractional_truncated() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(100, 55, false)
	assert_eq(gold, 105, "100 + floor(5.5) = 105")

func test_gold_large_damage() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(50, 5000, false)
	assert_eq(gold, 550, "50 + 500 = 550")

func test_gold_zero_base() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(0, 100, false)
	assert_eq(gold, 10, "0 + 10 = 10")


# AC.2.2: Material reward by tier

func test_material_tier1() -> void:
	for i in range(20):
		var mat: int = ResourceFormulas.calculate_material_reward(1, i + 1)
		assert_true(mat >= 1 and mat <= 3, "Tier 1: 1-3 materials, got %d" % mat)

func test_material_tier4_boss() -> void:
	for i in range(20):
		var mat: int = ResourceFormulas.calculate_material_reward(4, i + 1)
		assert_true(mat >= 4 and mat <= 12, "Tier 4: 4-12 materials, got %d" % mat)

func test_material_tier2() -> void:
	for i in range(20):
		var mat: int = ResourceFormulas.calculate_material_reward(2, i + 1)
		assert_true(mat >= 2 and mat <= 6, "Tier 2: 2-6 materials, got %d" % mat)


# AC.2.3: Zero damage still awards base gold

func test_zero_damage_base_gold() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(50, 0, false)
	assert_eq(gold, 50, "Base reward always awarded")

func test_zero_damage_with_boss() -> void:
	var gold: int = ResourceFormulas.calculate_gold_reward(50, 0, true)
	assert_eq(gold, 70, "50 + 0 + 20 boss kill bonus")
