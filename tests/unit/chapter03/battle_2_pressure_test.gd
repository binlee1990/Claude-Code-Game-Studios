extends Gut

func test_low_civilian_rescue_adds_enemy_morale_pressure() -> void:
	var state := Chapter03PressureModel.evaluate_pressure({
		"chapter_03_battle_1_civilians_rescued": 1,
		"chapter_03_act_a_e1_defeated_in_6_turns": true,
	})
	assert_eq(state["enemy_morale_bonus"], 1)
	assert_true(state["advance_hint"])

func test_missing_battle_one_data_defaults_to_neutral_start() -> void:
	var state := Chapter03PressureModel.evaluate_pressure({})
	assert_eq(state["civilian_rescued_count"], 2)
	assert_eq(state["enemy_morale_bonus"], 0)
	assert_false(state["advance_hint"])

func test_beacon_hold_requires_two_consecutive_player_turns() -> void:
	var state := Chapter03PressureModel.update_beacon_hold({}, "player", 2)
	assert_false(state["victory_ready"])
	state = Chapter03PressureModel.update_beacon_hold(state, "enemy", 2)
	assert_eq(state["held_turns"], 0)
	state = Chapter03PressureModel.update_beacon_hold(state, "player", 2)
	state = Chapter03PressureModel.update_beacon_hold(state, "player", 2)
	assert_true(state["victory_ready"])

func test_behavior_scoring_applies_b3_n2_deltas() -> void:
	var progress := {"belief_values": {"ren": 10, "yi": 10, "zhi": 10}}
	var result := Chapter03PressureModel.apply_behavior_scoring(progress, {
		"total_civilians": 3,
		"fast_clear_turn": 8,
		"default_supply_interactions": 1,
	})
	assert_eq(result["belief_values"]["ren"], 16)
	assert_eq(result["belief_values"]["yi"], 16)
	assert_eq(result["belief_values"]["zhi"], 16)
	assert_eq(progress["chapter_03_act_b_behavior_deltas"]["ren"], 6)

func test_civilian_death_penalty_can_shift_behavior_score() -> void:
	var progress := {
		"belief_values": {"ren": 20, "yi": 10, "zhi": 10},
		"chapter_03_act_b_civilian_deaths": 1,
		"chapter_03_act_b_civilians_rescued": 2,
	}
	Chapter03PressureModel.apply_behavior_scoring(progress, {"total_civilians": 3, "default_supply_interactions": 0})
	assert_eq(progress["belief_values"]["ren"], 15)
	assert_eq(progress["belief_values"]["yi"], 18)
