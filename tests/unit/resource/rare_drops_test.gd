# tests/unit/resource/rare_drops_test.gd
# Story 003: Rare Resource Drops
# Validates AC.2.3a, AC.2.3b, AC.2.4

extends Gut

# AC.2.3a: Normal battle fruit drop rate = 5%

func test_normal_fruit_drop_rate_low() -> void:
	var drops: int = 0
	for i in range(1000):
		if ResourceFormulas.check_fruit_drop(false, i + 1):
			drops += 1
	assert_true(drops > 20 and drops < 100, "Normal ~5%%, got %d/1000" % drops)

func test_normal_never_always() -> void:
	var always_drop: bool = true
	var never_drop: bool = true
	for i in range(100):
		if not ResourceFormulas.check_fruit_drop(false, i + 1):
			always_drop = false
		if ResourceFormulas.check_fruit_drop(false, i + 1):
			never_drop = false
	assert_false(always_drop, "Not 100% drop rate in normal")
	assert_false(never_drop, "Not 0% drop rate in normal")


# AC.2.3b: Boss battle fruit drop rate = 100%

func test_boss_always_drops_fruit() -> void:
	for i in range(100):
		assert_true(ResourceFormulas.check_fruit_drop(true, i + 1), "Boss always drops fruit")

func test_boss_fruit_count_1_or_2() -> void:
	for i in range(100):
		var count: int = ResourceFormulas.get_boss_fruit_count(i + 1)
		assert_true(count >= 1 and count <= 2, "Boss drops 1-2 fruits, got %d" % count)


# AC.2.4: Rare drop rates

func test_drop_rate_constants() -> void:
	assert_eq(ResourceFormulas.DROP_RATE_NORMAL_FRUIT, 0.05)
	assert_eq(ResourceFormulas.DROP_RATE_BOSS_FRUIT, 1.0)
	assert_eq(ResourceFormulas.DROP_RATE_HARD_RARE, 0.10)
	assert_eq(ResourceFormulas.DROP_RATE_HIDDEN_BOSS_RARE, 1.0)
	assert_eq(ResourceFormulas.DROP_RATE_HELL_RARE, 0.20)
	assert_eq(ResourceFormulas.DROP_RATE_HELL_PROTECT, 0.02)

func test_hard_rare_statistical() -> void:
	var drops: int = 0
	for i in range(1000):
		var rng := RandomNumberGenerator.new()
		rng.seed = i + 1
		if rng.randf() < ResourceFormulas.DROP_RATE_HARD_RARE:
			drops += 1
	assert_true(drops > 50 and drops < 200, "Hard ~10%%, got %d/1000" % drops)

func test_hidden_boss_always_rare() -> void:
	for i in range(50):
		var rng := RandomNumberGenerator.new()
		rng.seed = i + 1
		assert_true(rng.randf() < ResourceFormulas.DROP_RATE_HIDDEN_BOSS_RARE, "Hidden boss always drops rare")
