extends Gut

const BondRegistry := preload("res://src/core/bond/bond_registry.gd")

func test_bond_level_up_signal_fires_when_affinity_crosses_threshold() -> void:
	var events: Array = []
	var handler := func(pair_key: String, old_rank: String, new_rank: String, affinity: int) -> void:
		events.append({
			"pair_key": pair_key,
			"old_rank": old_rank,
			"new_rank": new_rank,
			"affinity": affinity,
		})
	GameEvents.bond_level_up.connect(handler)

	var registry := BondRegistry.new()
	registry.add_affinity("P1", "P2", 48, "comrade", "setup")
	var result := registry.add_affinity("P2", "P1", 5, "comrade", "battle_settlement")

	GameEvents.bond_level_up.disconnect(handler)

	assert_true(result["success"])
	assert_true(result["rank_changed"])
	assert_eq(events.size(), 1)
	assert_eq(events[0]["pair_key"], "P1::P2")
	assert_eq(events[0]["old_rank"], "None")
	assert_eq(events[0]["new_rank"], "C")
	assert_eq(events[0]["affinity"], 53)

func test_battle_settlement_affinity_payload_round_trips() -> void:
	var story_progress := {
		"bond_levels": {
			"P1::P2": {
				"unit_a": "P1",
				"unit_b": "P2",
				"affinity": 48,
				"rank": "None",
				"bond_type": "comrade",
			}
		}
	}
	var registry := BondRegistry.load_from_story_progress(story_progress)
	registry.add_affinity("P1", "P2", 5, "comrade", "battle_settlement:chapter_01_tutorial")
	var saved := SaveData.new()
	saved.story_progress = registry.save_to_story_progress(story_progress)

	var loaded := BondRegistry.load_from_story_progress(saved.story_progress)
	var rows := loaded.top_bonds_for_unit(&"P2")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["affinity"], 53)
	assert_eq(rows[0]["rank"], "C")
