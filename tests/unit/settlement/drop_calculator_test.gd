# tests/unit/settlement/drop_calculator_test.gd
# Story BS-004: Material & Equipment Drops
# Validates AC.2.2, AC.2.3, AC-D1 — drop rates and quality distribution.
# GDD reference: battle-settlement.md C.3, C.4.

extends Gut

# ---------------------------------------------------------------------------
# AC.2.2 — Gold calculation (delegates to ResourceFormulas)
# ---------------------------------------------------------------------------

func test_ac_2_2_gold_matches_qa_scenario() -> void:
	# Arrange
	var base_reward: int  = 100
	var damage_dealt: int = 500
	var is_boss: bool     = true

	# Act
	var result: int = DropCalculator.calculate_gold(base_reward, damage_dealt, is_boss)

	# Assert — 100 + floor(500*0.1) + 20 = 170
	assert_eq(result, 170,
		"AC.2.2: boss kill QA scenario must yield 170 gold (GDD D.1)")


func test_ac_2_2_gold_normal_kill_no_bonus() -> void:
	# Arrange
	var base_reward: int  = 100
	var damage_dealt: int = 500
	var is_boss: bool     = false

	# Act
	var result: int = DropCalculator.calculate_gold(base_reward, damage_dealt, is_boss)

	# Assert — 100 + 50 + 0 = 150
	assert_eq(result, 150,
		"AC.2.2: normal kill must yield 150 gold — no boss bonus (GDD D.1)")


func test_ac_2_2_gold_zero_damage_returns_base_only() -> void:
	# Arrange
	var base_reward: int  = 100
	var damage_dealt: int = 0
	var is_boss: bool     = false

	# Act
	var result: int = DropCalculator.calculate_gold(base_reward, damage_dealt, is_boss)

	# Assert
	assert_eq(result, 100,
		"AC.2.2: zero damage must yield base reward only (GDD D.1 edge case)")

# ---------------------------------------------------------------------------
# AC.2.3 — Material drops (tier multiplier via TIER_MATERIAL_MULTIPLIER)
# ---------------------------------------------------------------------------

func test_ac_2_3_materials_tier_multiplier_deterministic() -> void:
	# Arrange — NORMAL maps to multiplier=1; result must be in [1, 3]
	var tier: int     = DropCalculator.EnemyTier.NORMAL
	var rng_seed: int = 42

	# Act
	var result: int = DropCalculator.calculate_materials(tier, rng_seed)

	# Assert — TIER_MATERIAL_MULTIPLIER[NORMAL]=1, so result = 1 * rand(1..3) in [1,3]
	assert_true(result >= 1 and result <= 3,
		"AC.2.3: NORMAL tier must yield 1-3 materials (multiplier=1, GDD C.3)")


func test_ac_2_3_materials_boss_tier_higher_yield() -> void:
	# Arrange — BOSS multiplier=4 vs NORMAL multiplier=1, same seed
	var seed: int          = 99
	var boss_result: int   = DropCalculator.calculate_materials(DropCalculator.EnemyTier.BOSS, seed)
	var normal_result: int = DropCalculator.calculate_materials(DropCalculator.EnemyTier.NORMAL, seed)

	# Act / Assert — same random roll, BOSS multiplier must yield strictly more
	assert_true(boss_result > normal_result,
		"AC.2.3: BOSS tier (multiplier=4) must yield more materials than NORMAL (multiplier=1) at same seed (GDD C.3)")

# ---------------------------------------------------------------------------
# AC.2.3 — Equipment drop rate
# ---------------------------------------------------------------------------

func test_ac_2_3_normal_enemy_drops_only_10_percent() -> void:
	# Arrange — 1000 seeded iterations for statistical stability
	var drop_count: int = 0
	var iterations: int = 1000
	for i in range(iterations):
		if DropCalculator.rolls_equipment_drop(DropCalculator.EnemyTier.NORMAL, i + 1):
			drop_count += 1

	# Act / Assert — expect ~100 drops ±50 (10% ± 5%)
	assert_true(drop_count >= 50 and drop_count <= 150,
		"AC.2.3: NORMAL tier 10%% drop rate; 1000 rolls must land 50-150 drops, got %d" % drop_count)


func test_ac_2_3_boss_always_drops_equipment() -> void:
	# Arrange / Act — 50 iterations, all must drop
	var all_drop: bool = true
	for i in range(50):
		if not DropCalculator.rolls_equipment_drop(DropCalculator.EnemyTier.BOSS, i + 1):
			all_drop = false
			break

	# Assert
	assert_true(all_drop,
		"AC.2.3: BOSS tier drop rate=1.0 must always return true (GDD C.4)")

# ---------------------------------------------------------------------------
# AC-D1 — Quality boundary tests (pure roll_quality_from)
# ---------------------------------------------------------------------------

func test_ac_d1_roll_quality_boundary_gold() -> void:
	# Arrange — roll < 0.005 → GOLD
	var result: int = DropCalculator.roll_quality_from(0.001)

	# Assert
	assert_eq(result, DropCalculator.Quality.GOLD,
		"AC-D1: roll=0.001 must return GOLD (cutoff 0.005)")


func test_ac_d1_roll_quality_boundary_purple() -> void:
	# Arrange — 0.005 <= roll < 0.025 → PURPLE
	var result: int = DropCalculator.roll_quality_from(0.010)

	# Assert
	assert_eq(result, DropCalculator.Quality.PURPLE,
		"AC-D1: roll=0.010 must return PURPLE (cutoff 0.025)")


func test_ac_d1_roll_quality_boundary_blue() -> void:
	# Arrange — 0.025 <= roll < 0.125 → BLUE
	var result: int = DropCalculator.roll_quality_from(0.100)

	# Assert
	assert_eq(result, DropCalculator.Quality.BLUE,
		"AC-D1: roll=0.100 must return BLUE (cutoff 0.125)")


func test_ac_d1_roll_quality_boundary_green() -> void:
	# Arrange — 0.125 <= roll < 0.400 → GREEN
	var result: int = DropCalculator.roll_quality_from(0.300)

	# Assert
	assert_eq(result, DropCalculator.Quality.GREEN,
		"AC-D1: roll=0.300 must return GREEN (cutoff 0.400)")


func test_ac_d1_roll_quality_boundary_white() -> void:
	# Arrange — 0.400 <= roll < 1.0 → WHITE
	var result: int = DropCalculator.roll_quality_from(0.900)

	# Assert
	assert_eq(result, DropCalculator.Quality.WHITE,
		"AC-D1: roll=0.900 must return WHITE (range 0.400-1.000)")


func test_ac_d1_roll_quality_at_cutoff_gold_to_purple() -> void:
	# Arrange — roll == 0.005 is NOT < 0.005, so must be PURPLE not GOLD
	var result: int = DropCalculator.roll_quality_from(0.005)

	# Assert
	assert_eq(result, DropCalculator.Quality.PURPLE,
		"AC-D1: roll=0.005 (exact Gold cutoff) must return PURPLE — cutoff is exclusive upper bound")


func test_ac_d1_quality_distribution_large_sample_matches_approx() -> void:
	# Arrange — 10000 iterations for statistical confidence
	var counts: Dictionary = {
		DropCalculator.Quality.GOLD:   0,
		DropCalculator.Quality.PURPLE: 0,
		DropCalculator.Quality.BLUE:   0,
		DropCalculator.Quality.GREEN:  0,
		DropCalculator.Quality.WHITE:  0,
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(10000):
		var q: int = DropCalculator.roll_quality_from(rng.randf())
		counts[q] += 1

	# Assert — tolerances per GDD AC-D1 (±50% of expected counts)
	assert_true(counts[DropCalculator.Quality.GOLD] <= 100,
		"AC-D1: Gold (0.5%%) must be <=100 in 10000 rolls, got %d" % counts[DropCalculator.Quality.GOLD])
	assert_true(counts[DropCalculator.Quality.PURPLE] <= 300,
		"AC-D1: Purple (2%%) must be <=300 in 10000 rolls, got %d" % counts[DropCalculator.Quality.PURPLE])
	assert_true(counts[DropCalculator.Quality.BLUE] >= 850 and counts[DropCalculator.Quality.BLUE] <= 1150,
		"AC-D1: Blue (10%%) must be 850-1150 in 10000 rolls, got %d" % counts[DropCalculator.Quality.BLUE])
	var white_green: int = counts[DropCalculator.Quality.WHITE] + counts[DropCalculator.Quality.GREEN]
	assert_true(white_green > 8000,
		"AC-D1: White+Green (87.5%%) must dominate (>8000 of 10000), got %d" % white_green)

# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------

func test_aggregate_drops_returns_gold_materials_equipment_keys() -> void:
	# Arrange — empty enemy list
	var specs: Array = []

	# Act
	var result: Dictionary = DropCalculator.aggregate_drops(specs, 1)

	# Assert
	assert_eq(result["gold"], 0,
		"aggregate: empty enemy list must yield gold=0")
	assert_eq(result["materials"], 0,
		"aggregate: empty enemy list must yield materials=0")
	assert_eq(result["equipment"].size(), 0,
		"aggregate: empty enemy list must yield empty equipment array")


func test_aggregate_drops_sums_gold_across_enemies() -> void:
	# Arrange — 2 enemies, base_gold=50 each, 0 damage, no boss
	var specs: Array = [
		{"tier": DropCalculator.EnemyTier.NORMAL, "damage_dealt": 0,
		 "is_boss_kill": false, "base_gold": 50},
		{"tier": DropCalculator.EnemyTier.NORMAL, "damage_dealt": 0,
		 "is_boss_kill": false, "base_gold": 50},
	]

	# Act
	var result: Dictionary = DropCalculator.aggregate_drops(specs, 1)

	# Assert — each yields 50 + 0 + 0 = 50, total = 100
	assert_eq(result["gold"], 100,
		"aggregate: 2 enemies base_gold=50, 0 damage must sum to 100 gold")


func test_aggregate_drops_all_bosses_always_produce_equipment() -> void:
	# Arrange — 3 BOSS enemies (drop rate=1.0, always drops)
	var specs: Array = [
		{"tier": DropCalculator.EnemyTier.BOSS, "damage_dealt": 0,
		 "is_boss_kill": true, "base_gold": 0},
		{"tier": DropCalculator.EnemyTier.BOSS, "damage_dealt": 0,
		 "is_boss_kill": true, "base_gold": 0},
		{"tier": DropCalculator.EnemyTier.BOSS, "damage_dealt": 0,
		 "is_boss_kill": true, "base_gold": 0},
	]

	# Act
	var result: Dictionary = DropCalculator.aggregate_drops(specs, 7)

	# Assert — BOSS drop rate=1.0, all 3 must produce equipment
	assert_eq(result["equipment"].size(), 3,
		"aggregate: 3 BOSS enemies must produce exactly 3 equipment drops (rate=1.0)")

# ---------------------------------------------------------------------------
# Defensive
# ---------------------------------------------------------------------------

func test_rolls_equipment_drop_unknown_tier_returns_false() -> void:
	# Arrange — tier=999 is not in EQUIPMENT_DROP_RATE
	var result: bool = DropCalculator.rolls_equipment_drop(999, 1)

	# Assert
	assert_false(result,
		"defensive: unknown tier 999 must return false (not in EQUIPMENT_DROP_RATE)")
