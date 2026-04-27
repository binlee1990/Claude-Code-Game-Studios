extends Gut

func test_dominant_route_and_soft_lock_margin() -> void:
	var result := B3GateEvaluator.evaluate({"ren": 50, "yi": 25, "zhi": 10})
	assert_eq(result["dominant_route"], "ren")
	assert_eq(result["margin"], 25)
	assert_true(result["soft_lock_candidate"])

func test_narrow_margin_is_not_soft_locked() -> void:
	var result := B3GateEvaluator.evaluate({"ren": 30, "yi": 25, "zhi": 20})
	assert_eq(result["dominant_route"], "ren")
	assert_eq(result["margin"], 5)
	assert_false(result["soft_lock_candidate"])

func test_tied_or_missing_values_fallback_to_zhi() -> void:
	var missing := B3GateEvaluator.evaluate({})
	assert_eq(missing["dominant_route"], "zhi")
	assert_true(missing["fallback_used"])
	var tied := B3GateEvaluator.evaluate({"ren": 30, "yi": 30, "zhi": 10})
	assert_eq(tied["dominant_route"], "zhi")
	assert_eq(tied["margin"], 0)

func test_evaluate_and_persist_writes_story_progress_payload() -> void:
	var progress := {"belief_values": {"ren": 4, "yi": 12, "zhi": 1}}
	var result := B3GateEvaluator.evaluate_and_persist(progress, "chapter_03_act_b")
	assert_eq(result["dominant_route"], "yi")
	assert_eq(progress["b3_gate"]["dominant_route"], "yi")
	assert_eq(progress["b3_gate"]["evaluated_after"], "chapter_03_act_b")

func test_belief_system_applies_runtime_narrative_choice_once_payload() -> void:
	var progress := {"belief_values": {"ren": 0, "yi": 0, "zhi": 0}}
	var result := BeliefSystem.apply_runtime_narrative_choice(progress, {
		"node_id": "B3-N1",
		"runtime_branching": true,
		"default_option_id": "cut_supply",
		"options": [
			{"id": "cut_supply", "belief_delta": {"zhi": 10, "ren": 1, "yi": -2}}
		],
	})
	assert_true(result["success"])
	assert_eq(progress["belief_values"]["zhi"], 10)
	assert_eq(progress["belief_values"]["yi"], 0)
	assert_eq(progress["narrative_choices"]["B3-N1"], "cut_supply")
