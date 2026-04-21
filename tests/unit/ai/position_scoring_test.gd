# tests/unit/ai/position_scoring_test.gd
# Story 004: Position Scoring
# Validates AC-P1 through AC-P5

extends Gut

var _brain: AIBrain

func before_each() -> void:
	_brain = AIBrain.new(AI.AIType.BALANCED)

# AC-P2: Height scoring

func test_height_high_1_2() -> void:
	assert_eq(AI.get_height_score(TerrainTypes.HEIGHT_HIGH), 1.2)

func test_height_plain_1_0() -> void:
	assert_eq(AI.get_height_score(TerrainTypes.HEIGHT_PLAIN), 1.0)

func test_height_low_0_8() -> void:
	assert_eq(AI.get_height_score(TerrainTypes.HEIGHT_LOW), 0.8)


# Position score calculation

func test_position_score_normal() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_PLAIN, false, false, 1.0)
	assert_eq(score, 1.0)

func test_position_score_highland() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_HIGH, false, false, 1.0)
	assert_eq(score, 1.2)

func test_position_score_lowland() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_LOW, false, false, 1.0)
	assert_eq(score, 0.8)


# AC-P3: Element terrain avoidance

func test_dangerous_element_penalty() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_PLAIN, true, false, 1.0)
	assert_eq(score, 0.5, "Dangerous element = 0.5x")

func test_normal_element_no_penalty() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_PLAIN, false, false, 1.0)
	assert_eq(score, 1.0)


# AC-P4: Support range bonus

func test_support_range_bonus() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_PLAIN, false, true, 1.0)
	assert_eq(score, 1.2)

func test_no_support_range() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_PLAIN, false, false, 1.0)
	assert_eq(score, 1.0)


# Combined factors

func test_combined_highland_support() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_HIGH, false, true, 1.0)
	assert_eq(score, 1.44, "1.2 × 1.0 × 1.2 = 1.44")

func test_combined_lowland_danger() -> void:
	var score: float = _brain.calculate_position_score(TerrainTypes.HEIGHT_LOW, true, false, 1.0)
	assert_eq(score, 0.4, "0.8 × 0.5 × 1.0 = 0.4")


# AC-P1: Best position selection

func test_select_best_position() -> void:
	var positions: Array[Dictionary] = [
		{"height": 0, "dangerous": false, "support": false, "distance_score": 0.5},
		{"height": 1, "dangerous": false, "support": false, "distance_score": 0.8},
		{"height": 2, "dangerous": false, "support": true,  "distance_score": 1.0},
		{"height": 1, "dangerous": false, "support": false, "distance_score": 0.3},
		{"height": 1, "dangerous": false, "support": false, "distance_score": 0.9},
	]
	var idx: int = _brain.select_position(positions, 0.0)
	assert_eq(idx, 2, "Position 2 (highland + support) is best")


# AC-P5: Stay if no improvement

func test_stay_when_no_better_position() -> void:
	var positions: Array[Dictionary] = [
		{"height": 0, "dangerous": false, "support": false, "distance_score": 0.3},
		{"height": 0, "dangerous": true,  "support": false, "distance_score": 0.2},
	]
	var idx: int = _brain.select_position(positions, 1.5)
	assert_eq(idx, -1, "Stay at current position (1.5 > all candidates)")

func test_only_current_reachable() -> void:
	var positions: Array[Dictionary] = []
	var idx: int = _brain.select_position(positions, 1.0)
	assert_eq(idx, -1, "No candidates → stay")
