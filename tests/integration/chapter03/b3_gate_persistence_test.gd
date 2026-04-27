extends Gut

func test_b3_gate_round_trip_is_independent_from_later_belief_changes() -> void:
	var save_data := SaveData.new()
	save_data.story_progress = {"belief_values": {"ren": 50, "yi": 25, "zhi": 10}}
	B3GateEvaluator.evaluate_and_persist(save_data.story_progress)

	var loaded := SaveData.deserialize(save_data.serialize())
	loaded.story_progress["belief_values"] = {"ren": 0, "yi": 100, "zhi": 0}

	assert_eq(loaded.story_progress["b3_gate"]["dominant_route"], "ren")
	assert_eq(loaded.story_progress["b3_gate"]["margin"], 25)
	assert_true(loaded.story_progress["b3_gate"]["soft_lock_candidate"])

func test_old_save_without_b3_gate_falls_back_to_zhi() -> void:
	var save_data := SaveData.new()
	save_data.story_progress = {}
	var loaded := SaveData.deserialize(save_data.serialize())
	var result := B3GateEvaluator.evaluate(loaded.story_progress.get("belief_values", {}))
	assert_eq(result["dominant_route"], "zhi")
	assert_false(result["soft_lock_candidate"])
