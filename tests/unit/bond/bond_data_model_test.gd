extends Gut

const BondRegistry := preload("res://src/core/bond/bond_registry.gd")

func test_pair_key_is_stable_for_reverse_order() -> void:
	assert_eq(BondRegistry.make_pair_key("P2", "P1"), "P1::P2")
	assert_eq(BondRegistry.make_pair_key("P1", "P2"), "P1::P2")
	assert_eq(BondRegistry.make_pair_key("P1", "P1"), "")

func test_affinity_thresholds_and_round_trip() -> void:
	var registry := BondRegistry.new()
	var result := registry.add_affinity("P1", "P2", 155, "comrade", "test")
	assert_true(result["success"])
	assert_eq(result["new_rank"], "B")

	var save_data := SaveData.new()
	save_data.story_progress = registry.save_to_story_progress(save_data.story_progress)
	var loaded := BondRegistry.load_from_story_progress(save_data.story_progress)
	var rows := loaded.top_bonds_for_unit(&"P1")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["pair_key"], "P1::P2")
	assert_eq(rows[0]["affinity"], 155)
	assert_eq(rows[0]["rank"], "B")

func test_reverse_duplicate_writes_update_same_pair() -> void:
	var registry := BondRegistry.new()
	registry.add_affinity("P1", "P2", 20)
	registry.add_affinity("P2", "P1", 35)
	var payload := registry.serialize()

	assert_eq(payload.keys().size(), 1)
	assert_true(payload.has("P1::P2"))
	assert_eq(payload["P1::P2"]["affinity"], 55)
	assert_eq(payload["P1::P2"]["rank"], "C")

func test_old_numeric_payload_is_migrated() -> void:
	var registry := BondRegistry.new()
	registry.deserialize({"P2::P1": 50})
	var payload := registry.serialize()

	assert_true(payload.has("P1::P2"))
	assert_eq(payload["P1::P2"]["unit_a"], "P1")
	assert_eq(payload["P1::P2"]["unit_b"], "P2")
	assert_eq(payload["P1::P2"]["rank"], "C")
