# tests/integration/ai/ai_integration_test.gd
# Story 006: AI Save/Load Integration
# Validates full AI state round-trip

extends Gut

func test_ai_brain_round_trip() -> void:
	var brain := AIBrain.new(AI.AIType.AGGRESSIVE)
	brain.threat_system.add_damage_threat(1, 100)
	brain.threat_system.add_heal_threat(2, 50)
	brain.check_boss_phase(0.60)

	var data: Dictionary = brain.get_data()
	var loaded := AIBrain.new(AI.AIType.BALANCED)
	loaded.load_data(data)

	assert_eq(loaded.ai_type, AI.AIType.AGGRESSIVE, "AI type restored")
	assert_eq(loaded.threat_system.get_threat(1), 10.0, "Threat 1 restored")
	assert_eq(loaded.threat_system.get_threat(2), 10.0, "Threat 2 restored")
	assert_true(loaded.is_boss_enraged(), "Boss state restored")
	assert_eq(loaded.get_boss_phase(), 1)

func test_ai_brain_double_round_trip() -> void:
	var brain := AIBrain.new(AI.AIType.SUPPORT)
	brain.threat_system.add_damage_threat(1, 80)
	brain.threat_system.add_buff_threat(3)

	var saved1: Dictionary = brain.get_data()
	var loaded1 := AIBrain.new()
	loaded1.load_data(saved1)
	var saved2: Dictionary = loaded1.get_data()
	var loaded2 := AIBrain.new()
	loaded2.load_data(saved2)

	assert_eq(loaded2.ai_type, loaded1.ai_type)
	assert_eq(loaded2.threat_system.get_threat(1), loaded1.threat_system.get_threat(1))
	assert_eq(loaded2.threat_system.get_threat(3), loaded1.threat_system.get_threat(3))

func test_different_ai_types_preserved() -> void:
	for type in AI.AIType.values():
		var brain := AIBrain.new(type)
		var data: Dictionary = brain.get_data()
		var loaded := AIBrain.new()
		loaded.load_data(data)
		assert_eq(loaded.ai_type, type, "%s preserved" % AI.AIType.keys()[type])
