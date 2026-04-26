# tests/unit/chapter02/wang_xiu_ai_test.gd
# Story CH2-c-002: Wang Xiu Escort AI — hesitation + safe zone + departure
# Validates AC-CH2-002 + AC-CH2-004

extends Gut

var _ai: WangXiuAI


func _make_grid(w: int = 10, h: int = 10) -> Array:
	var grid := []
	for y in h:
		var row := []
		for x in w:
			row.append(TerrainTypes.Terrain.NORMAL)
		grid.append(row)
	return grid


func _nearest_safe_zone_dist() -> int:
	var best := 999999
	for y in 3:
		for x in 3:
			var d := absi(_ai.get_position().x - x) + absi(_ai.get_position().y - y)
			if d < best:
				best = d
	return best


func before_each() -> void:
	_ai = WangXiuAI.new()
	_ai.init(_make_grid(), Vector2i(5, 5), 30)


func after_each() -> void:
	_ai = null


# --- AC-CH2-002.1: Normal movement toward safe zone ---

func test_ac_ch2_002_1_moves_closer_each_turn() -> void:
	for i in 5:
		var prev_dist := _nearest_safe_zone_dist()
		_ai.decide_action([])
		var new_dist := _nearest_safe_zone_dist()
		assert_true(new_dist < prev_dist,
			"Turn %d: should be closer to safe zone" % (i + 1))


func test_moves_exactly_one_cell_per_turn() -> void:
	var prev := _ai.get_position()
	_ai.decide_action([])
	var next := _ai.get_position()
	var moved := absi(prev.x - next.x) + absi(prev.y - next.y)
	assert_eq(moved, 1, "Should move exactly 1 cell per turn")


func test_reaches_safe_zone_within_6_turns_from_5_5() -> void:
	for i in 10:
		_ai.decide_action([])
		if _ai.has_reached_safe_zone():
			assert_true(i + 1 < 7, "Should reach safe zone within 6 turns from (5,5)")
			return
	assert_true(false, "Should have reached safe zone within 10 turns")


# --- AC-CH2-002.2: Hesitation when enemy nearby ---

func test_ac_ch2_002_2_hesitates_enemy_distance_1() -> void:
	var result := _ai.decide_action([Vector2i(4, 5)])
	assert_eq(result["action"], "hesitate")
	assert_eq(_ai.get_position(), Vector2i(5, 5), "Should not move when hesitating")


func test_hesitates_enemy_distance_2() -> void:
	var result := _ai.decide_action([Vector2i(3, 5)])
	assert_eq(result["action"], "hesitate")


func test_moves_when_enemy_distance_3() -> void:
	var result := _ai.decide_action([Vector2i(2, 5)])
	assert_ne(result["action"], "hesitate")


func test_multiple_enemies_one_close_triggers_hesitation() -> void:
	var result := _ai.decide_action([Vector2i(8, 8), Vector2i(4, 5)])
	assert_eq(result["action"], "hesitate")


func test_hesitation_resumes_movement_after_enemy_leaves() -> void:
	_ai.decide_action([Vector2i(4, 5)])
	assert_eq(_ai.get_position(), Vector2i(5, 5))
	_ai.decide_action([])
	assert_ne(_ai.get_position(), Vector2i(5, 5),
		"Should move after enemy leaves")


# --- AC-CH2-004.1: Departure on HP = 0 ---

func test_ac_ch2_004_1_departure_on_hp_zero() -> void:
	_ai.take_damage(30)
	assert_true(_ai.is_departed())
	var result := _ai.decide_action([])
	assert_eq(result["action"], "none")


func test_not_departed_above_zero_hp() -> void:
	_ai.take_damage(29)
	assert_false(_ai.is_departed())


func test_departed_emits_signal() -> void:
	var signal_data := {}
	_ai.npc_departed.connect(func(uid: String) -> void:
		signal_data["unit_id"] = uid
	)
	_ai.take_damage(30)
	assert_eq(signal_data.get("unit_id", ""), "wang_xiu")


func test_take_damage_clamps_to_zero() -> void:
	_ai.take_damage(50)
	assert_eq(_ai.get_hp(), 0)


# --- AC-CH2-004.2: Departure flag queryable for belief settlement ---

func test_ac_ch2_004_2_departed_flag_for_ren_penalty() -> void:
	_ai.take_damage(30)
	assert_true(_ai.is_departed(),
		"Settlement checks departed for ren-8 instead of ren+12")


func test_no_belief_bonus_without_safe_zone_or_departure() -> void:
	assert_false(_ai.is_departed())
	assert_false(_ai.has_reached_safe_zone())


# --- Safe zone arrival ---

func test_arrives_safe_zone_from_adjacent() -> void:
	_ai.set_position(Vector2i(3, 0))
	_ai.decide_action([])
	assert_true(_ai.has_reached_safe_zone())


func test_already_in_safe_zone_triggers_immediately() -> void:
	_ai.set_position(Vector2i(1, 1))
	var result := _ai.decide_action([])
	assert_eq(result["action"], "safe_zone_reached")
	assert_true(_ai.has_reached_safe_zone())


func test_no_action_after_safe_zone_reached() -> void:
	_ai.set_position(Vector2i(1, 1))
	_ai.decide_action([])
	var result := _ai.decide_action([])
	assert_eq(result["action"], "none")


func test_safe_zone_signal_emits_belief_reward() -> void:
	var signal_data := {}
	_ai.safe_zone_reached.connect(
		func(uid: String, reward: Dictionary) -> void:
			signal_data["unit_id"] = uid
			signal_data["reward"] = reward
	)
	_ai.set_position(Vector2i(1, 1))
	_ai.decide_action([])
	assert_eq(signal_data.get("unit_id", ""), "wang_xiu")
	assert_eq(signal_data.get("reward", {}).get("ren", 0), 12)


# --- Obstacle avoidance ---

func test_pathfinds_around_obstacle() -> void:
	var grid := _make_grid()
	grid[5][4] = TerrainTypes.Terrain.OBSTACLE  # block left
	_ai = WangXiuAI.new()
	_ai.init(grid, Vector2i(5, 5), 30)
	var prev := _ai.get_position()
	_ai.decide_action([])
	assert_ne(_ai.get_position(), prev, "Should still move when left is blocked")
