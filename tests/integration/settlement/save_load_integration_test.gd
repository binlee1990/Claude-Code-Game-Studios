# tests/integration/settlement/save_load_integration_test.gd
# Story BS-005: Settlement Save/Load Integration
# Validates AC-S1 (rewards fields round-trip), AC-S2 (battle history persistence),
# AC-S3 (multiple save/load cycles produce identical state)

extends Gut

# ---------------------------------------------------------------------------
# Fixtures — BattleHistoryLog is pure data; no scene tree setup needed.
# ---------------------------------------------------------------------------

var _log: BattleHistoryLog

func before_each() -> void:
	_log = BattleHistoryLog.new()

func after_each() -> void:
	_log = null


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_record(battle_id: String, result_type: int, rating: int,
		rewards_enabled: bool, exp: int = 0, gold: int = 0,
		materials: int = 0, equip: int = 0, ts: int = 0) -> Dictionary:
	return {
		"battle_id":         battle_id,
		"result_type":       result_type,
		"rating":            rating,
		"rewards_enabled":   rewards_enabled,
		"exp_awarded":       exp,
		"gold_awarded":      gold,
		"materials_awarded": materials,
		"equipment_count":   equip,
		"timestamp":         ts,
	}


# ---------------------------------------------------------------------------
# Append + count (AC-S2 baseline)
# ---------------------------------------------------------------------------

func test_append_battle_increments_count() -> void:
	# Arrange / Act
	_log.append_battle(_make_record("map_01", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true))

	# Assert
	assert_eq(_log.count(), 1, "One appended record yields count == 1")

func test_append_multiple_battles_preserves_order() -> void:
	# Arrange
	_log.append_battle(_make_record("map_01", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true))
	_log.append_battle(_make_record("map_02", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false))
	_log.append_battle(_make_record("map_03", SettlementResult.SettlementType.RETREAT,
		BattleEvaluation.Rating.NORMAL, false))

	# Act
	var records: Array = _log.get_records()

	# Assert
	assert_eq(records.size(), 3, "Three appended records yield count == 3")
	assert_eq(records[0]["battle_id"], "map_01", "First record is map_01")
	assert_eq(records[1]["battle_id"], "map_02", "Second record is map_02")
	assert_eq(records[2]["battle_id"], "map_03", "Third record is map_03")

func test_count_by_result_victory() -> void:
	# Arrange
	_log.append_battle(_make_record("v1", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true))
	_log.append_battle(_make_record("v2", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.EXCELLENT, true))
	_log.append_battle(_make_record("d1", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false))

	# Act / Assert
	assert_eq(_log.count_by_result(SettlementResult.SettlementType.VICTORY), 2,
		"count_by_result(VICTORY) == 2 with 2 victories and 1 defeat")

func test_count_by_result_defeat() -> void:
	# Arrange
	_log.append_battle(_make_record("v1", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true))
	_log.append_battle(_make_record("v2", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.EXCELLENT, true))
	_log.append_battle(_make_record("d1", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false))

	# Act / Assert
	assert_eq(_log.count_by_result(SettlementResult.SettlementType.DEFEAT), 1,
		"count_by_result(DEFEAT) == 1 with 2 victories and 1 defeat")

func test_append_fills_optional_fields_with_defaults() -> void:
	# Arrange — only required keys provided
	_log.append_battle({
		"battle_id":   "minimal",
		"result_type": SettlementResult.SettlementType.VICTORY,
	})

	# Act
	var r: Dictionary = _log.get_records()[0]

	# Assert
	assert_eq(r["exp_awarded"],       0, "exp_awarded defaults to 0")
	assert_eq(r["gold_awarded"],      0, "gold_awarded defaults to 0")
	assert_eq(r["materials_awarded"], 0, "materials_awarded defaults to 0")
	assert_eq(r["equipment_count"],   0, "equipment_count defaults to 0")
	assert_eq(r["timestamp"],         0, "timestamp defaults to 0")
	assert_eq(r["rating"],            0, "rating defaults to 0")
	assert_false(r["rewards_enabled"],   "rewards_enabled defaults to false")


# ---------------------------------------------------------------------------
# Round-trip (AC-S1, AC-S2)
# ---------------------------------------------------------------------------

func test_ac_s2_single_battle_round_trip() -> void:
	# Arrange
	_log.append_battle(_make_record("map_01", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true, 333, 170, 5, 1, 1000))

	# Act
	var data: Dictionary = _log.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data)

	# Assert
	assert_eq(log2.count(), 1, "Deserialized log has 1 record")
	var r: Dictionary = log2.get_records()[0]
	assert_eq(r["battle_id"],         "map_01",                                 "battle_id preserved")
	assert_eq(r["result_type"],       SettlementResult.SettlementType.VICTORY,  "result_type preserved")
	assert_eq(r["rating"],            BattleEvaluation.Rating.PERFECT,          "rating preserved")
	assert_true(r["rewards_enabled"],                                            "rewards_enabled preserved")
	assert_eq(r["exp_awarded"],       333,                                       "exp_awarded preserved")
	assert_eq(r["gold_awarded"],      170,                                       "gold_awarded preserved")
	assert_eq(r["materials_awarded"], 5,                                         "materials_awarded preserved")
	assert_eq(r["equipment_count"],   1,                                         "equipment_count preserved")
	assert_eq(r["timestamp"],         1000,                                      "timestamp preserved")

func test_ac_s2_multiple_battles_round_trip() -> void:
	# Arrange — 5 records: 3 victory, 1 defeat, 1 retreat
	_log.append_battle(_make_record("m1", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT,   true,  300, 150, 4, 1, 100))
	_log.append_battle(_make_record("m2", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.EXCELLENT, true,  240, 120, 3, 0, 200))
	_log.append_battle(_make_record("m3", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL,      false,   0,   0, 0, 0, 300))
	_log.append_battle(_make_record("m4", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.NORMAL,    true,  180,  90, 2, 0, 400))
	_log.append_battle(_make_record("m5", SettlementResult.SettlementType.RETREAT,
		BattleEvaluation.Rating.FAIL,      false,   0,   0, 0, 0, 500))

	# Act
	var data: Dictionary = _log.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data)

	# Assert — count and insertion order
	assert_eq(log2.count(), 5, "5 records preserved after round-trip")
	var records: Array = log2.get_records()
	assert_eq(records[0]["battle_id"], "m1", "Record 0 order preserved")
	assert_eq(records[1]["battle_id"], "m2", "Record 1 order preserved")
	assert_eq(records[2]["battle_id"], "m3", "Record 2 order preserved")
	assert_eq(records[3]["battle_id"], "m4", "Record 3 order preserved")
	assert_eq(records[4]["battle_id"], "m5", "Record 4 order preserved")
	# Result types preserved
	assert_eq(records[2]["result_type"], SettlementResult.SettlementType.DEFEAT,
		"Defeat record result_type preserved")
	assert_eq(records[4]["result_type"], SettlementResult.SettlementType.RETREAT,
		"Retreat record result_type preserved")

func test_ac_s2_empty_log_round_trip() -> void:
	# Arrange — new log, nothing appended

	# Act
	var data: Dictionary = _log.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data)

	# Assert
	assert_eq(log2.count(), 0, "Empty log round-trip yields count == 0")

func test_ac_s1_rewards_fields_round_trip() -> void:
	# Arrange — record with all reward fields populated
	_log.append_battle(_make_record("rewards_test",
		SettlementResult.SettlementType.VICTORY, BattleEvaluation.Rating.PERFECT,
		true, 333, 170, 5, 2, 9999))

	# Act
	var data: Dictionary = _log.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data)

	# Assert
	var r: Dictionary = log2.get_records()[0]
	assert_eq(r["exp_awarded"],       333, "exp_awarded 333 preserved (AC-S1)")
	assert_eq(r["gold_awarded"],      170, "gold_awarded 170 preserved (AC-S1)")
	assert_eq(r["materials_awarded"],   5, "materials_awarded 5 preserved (AC-S1)")
	assert_eq(r["equipment_count"],     2, "equipment_count 2 preserved (AC-S1)")


# ---------------------------------------------------------------------------
# Double round-trip (AC-S3)
# ---------------------------------------------------------------------------

func test_ac_s3_double_round_trip_identical() -> void:
	# Arrange — 3 records
	_log.append_battle(_make_record("a", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true, 100, 50, 2, 1, 1))
	_log.append_battle(_make_record("b", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false, 0, 0, 0, 0, 2))
	_log.append_battle(_make_record("c", SettlementResult.SettlementType.RETREAT,
		BattleEvaluation.Rating.FAIL, false, 0, 0, 0, 0, 3))

	# First save -> load
	var data1: Dictionary = _log.serialize()
	var log1 := BattleHistoryLog.new()
	log1.deserialize(data1)

	# Second save -> load
	var data2: Dictionary = log1.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data2)

	# Assert — count and all fields match between log1 and log2
	assert_eq(log2.count(), log1.count(), "count identical after double round-trip (AC-S3)")
	var r1: Array = log1.get_records()
	var r2: Array = log2.get_records()
	for i in r1.size():
		assert_eq(r2[i]["battle_id"],         r1[i]["battle_id"],
			"battle_id[%d] identical" % i)
		assert_eq(r2[i]["result_type"],       r1[i]["result_type"],
			"result_type[%d] identical" % i)
		assert_eq(r2[i]["rating"],            r1[i]["rating"],
			"rating[%d] identical" % i)
		assert_eq(r2[i]["exp_awarded"],       r1[i]["exp_awarded"],
			"exp_awarded[%d] identical" % i)
		assert_eq(r2[i]["gold_awarded"],      r1[i]["gold_awarded"],
			"gold_awarded[%d] identical" % i)
		assert_eq(r2[i]["materials_awarded"], r1[i]["materials_awarded"],
			"materials_awarded[%d] identical" % i)
		assert_eq(r2[i]["equipment_count"],   r1[i]["equipment_count"],
			"equipment_count[%d] identical" % i)

func test_ac_s3_double_round_trip_preserves_order() -> void:
	# Arrange
	_log.append_battle(_make_record("x1", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.NORMAL, true))
	_log.append_battle(_make_record("x2", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false))
	_log.append_battle(_make_record("x3", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.EXCELLENT, true))

	# First round-trip
	var log1 := BattleHistoryLog.new()
	log1.deserialize(_log.serialize())

	# Second round-trip
	var log2 := BattleHistoryLog.new()
	log2.deserialize(log1.serialize())

	# Assert — insertion order stable
	var records: Array = log2.get_records()
	assert_eq(records[0]["battle_id"], "x1", "Order[0] x1 preserved after double round-trip")
	assert_eq(records[1]["battle_id"], "x2", "Order[1] x2 preserved after double round-trip")
	assert_eq(records[2]["battle_id"], "x3", "Order[2] x3 preserved after double round-trip")


# ---------------------------------------------------------------------------
# Edge / defensive
# ---------------------------------------------------------------------------

func test_deserialize_unknown_version_starts_empty() -> void:
	# Arrange — inject unsupported version number
	var bad_data: Dictionary = {"version": 999, "records": [
		{"battle_id": "should_be_dropped", "result_type": 0, "rating": 0,
		 "rewards_enabled": false, "exp_awarded": 0, "gold_awarded": 0,
		 "materials_awarded": 0, "equipment_count": 0, "timestamp": 0}
	]}

	# Act
	_log.deserialize(bad_data)

	# Assert
	assert_eq(_log.count(), 0, "Unknown version 999 results in empty log")

func test_deserialize_missing_records_key_starts_empty() -> void:
	# Arrange — data has only the version key
	var data: Dictionary = {"version": BattleHistoryLog.VERSION}

	# Act
	_log.deserialize(data)

	# Assert
	assert_eq(_log.count(), 0, "Missing 'records' key results in empty log")

func test_deserialize_non_dict_record_skipped() -> void:
	# Arrange — records array contains 2 valid dicts and 1 non-dict string
	var data: Dictionary = {
		"version": BattleHistoryLog.VERSION,
		"records": [
			{"battle_id": "ok1", "result_type": 0, "rating": 0,
			 "rewards_enabled": false, "exp_awarded": 0, "gold_awarded": 0,
			 "materials_awarded": 0, "equipment_count": 0, "timestamp": 0},
			"not a dict",
			{"battle_id": "ok2", "result_type": 0, "rating": 0,
			 "rewards_enabled": false, "exp_awarded": 0, "gold_awarded": 0,
			 "materials_awarded": 0, "equipment_count": 0, "timestamp": 0},
		]
	}

	# Act
	_log.deserialize(data)

	# Assert
	assert_eq(_log.count(), 2, "Non-dict entry skipped; 2 valid records retained")

func test_clear_removes_all_records() -> void:
	# Arrange
	_log.append_battle(_make_record("c1", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.NORMAL, true))
	_log.append_battle(_make_record("c2", SettlementResult.SettlementType.DEFEAT,
		BattleEvaluation.Rating.FAIL, false))
	_log.append_battle(_make_record("c3", SettlementResult.SettlementType.RETREAT,
		BattleEvaluation.Rating.FAIL, false))
	assert_eq(_log.count(), 3, "Pre-condition: 3 records before clear")

	# Act
	_log.clear()

	# Assert
	assert_eq(_log.count(), 0, "clear() removes all records")

func test_get_records_returns_defensive_copy() -> void:
	# Arrange
	_log.append_battle(_make_record("orig", SettlementResult.SettlementType.VICTORY,
		BattleEvaluation.Rating.PERFECT, true, 0, 100, 0, 0, 0))

	# Act — mutate the copy's inner dict
	var copy: Array = _log.get_records()
	copy[0]["gold_awarded"] = 9999

	# Assert — internal record is unaffected
	var fresh: Array = _log.get_records()
	assert_eq(fresh[0]["gold_awarded"], 100,
		"Mutating copy's dict must not affect internal _records (defensive copy)")


# ---------------------------------------------------------------------------
# End-to-end integration with settlement classes (AC-S1, AC-S2, AC-S3)
# ---------------------------------------------------------------------------

func test_settlement_outcome_records_full_round_trip() -> void:
	# Arrange — run the real settlement pipeline to produce values.
	# trigger_victory emits GameEvents.settlement_triggered (autoload); no
	# listener is connected here so the signal fires safely into the void.
	var trigger := SettlementTrigger.new()
	var result: SettlementResult = trigger.trigger_victory([])

	var exp_per_unit: int = ExperienceDistribution.distribute(
		[ExperienceDistribution.EnemyTier.BOSS], 1, 0.5)

	var gold: int = DropCalculator.calculate_gold(50, 300, true)

	var eval: Dictionary = BattleEvaluation.evaluate(0, 0)

	# Act — assemble and append to history log
	_log.append_battle({
		"battle_id":         "e2e_test_01",
		"result_type":       result.type,
		"rating":            eval["rating"],
		"rewards_enabled":   result.rewards_enabled,
		"exp_awarded":       exp_per_unit,
		"gold_awarded":      gold,
		"materials_awarded": 3,
		"equipment_count":   1,
		"timestamp":         12345,
	})

	# Serialize -> deserialize
	var data: Dictionary = _log.serialize()
	var log2 := BattleHistoryLog.new()
	log2.deserialize(data)

	# Assert — all pipeline-produced values round-trip cleanly
	assert_eq(log2.count(), 1, "E2E: 1 record in deserialized log")
	var r: Dictionary = log2.get_records()[0]
	assert_eq(r["battle_id"],         "e2e_test_01",                            "E2E: battle_id preserved")
	assert_eq(r["result_type"],       SettlementResult.SettlementType.VICTORY,  "E2E: VICTORY result_type preserved")
	assert_eq(r["rating"],            BattleEvaluation.Rating.PERFECT,          "E2E: PERFECT rating preserved")
	assert_true(r["rewards_enabled"],                                            "E2E: rewards_enabled=true preserved")
	assert_eq(r["exp_awarded"],       exp_per_unit,                             "E2E: exp_awarded matches pipeline output")
	assert_eq(r["gold_awarded"],      gold,                                     "E2E: gold_awarded matches pipeline output")
	assert_eq(r["materials_awarded"], 3,                                        "E2E: materials_awarded preserved")
	assert_eq(r["equipment_count"],   1,                                        "E2E: equipment_count preserved")
	assert_eq(r["timestamp"],         12345,                                    "E2E: timestamp preserved")
