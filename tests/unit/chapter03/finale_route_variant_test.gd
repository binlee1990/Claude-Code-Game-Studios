extends Gut

func test_finale_route_key_uses_persisted_gate_value() -> void:
	var progress := {"b3_gate": {"dominant_route": "yi", "margin": 12, "soft_lock_candidate": false}}
	assert_eq(B3GateEvaluator.get_persisted_route(progress), "yi")

func test_invalid_finale_route_falls_back_to_zhi() -> void:
	var progress := {"b3_gate": {"dominant_route": "unknown"}}
	assert_eq(B3GateEvaluator.get_persisted_route(progress), "zhi")

func test_boss_phase_thresholds_match_sprint_008_three_phase_shape() -> void:
	var boss := BossPhaseController.new()
	boss.initialize({
		"max_hp": 135,
		"current_hp": 135,
		"boss_phase_thresholds": [0.60, 0.25],
	})
	boss.update_hp(80)
	assert_eq(boss.get_current_phase(), BossPhaseController.Phase.PHASE_2)
	boss.update_hp(30)
	assert_eq(boss.get_current_phase(), BossPhaseController.Phase.PHASE_3)
