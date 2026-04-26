# tests/unit/chapter02/branch_gate_test.gd
# Story CH2-c-001: Belief Gate — B2-GATE routing
# Validates AC-CH2-001 (three routing scenarios) + AC-CH2-007 edge cases

extends Gut

var _gate: BeliefGate

func before_each() -> void:
	_gate = BeliefGate.new()

func after_each() -> void:
	_gate = null

# --- AC-CH2-001.1: Yi leads → suppression ---

func test_ac_ch2_001_1_yi_leads_suppression() -> void:
	# Arrange: yi=15, ren=5, zhi=8  →  margin = 15 - max(5,8) = 15 - 8 = 7 >= 5
	var bv := {"ren": 5, "yi": 15, "zhi": 8}

	# Act
	var result: Dictionary = _gate.evaluate(bv)

	# Assert
	assert_eq(result["variant"], BeliefGate.BranchVariant.SUPPRESSION,
		"yi=15, ren=5, zhi=8 → suppression (margin=7 >= 5)")
	assert_eq(result["branch_key"], "suppression")

func test_ac_ch2_001_1_yi_leads_by_exact_threshold() -> void:
	# Arrange: yi=10, ren=5, zhi=5  →  margin = 10 - 5 = 5 (exact threshold)
	var bv := {"ren": 5, "yi": 10, "zhi": 5}

	var result: Dictionary = _gate.evaluate(bv)

	assert_eq(result["variant"], BeliefGate.BranchVariant.SUPPRESSION,
		"yi=10, ren=5, zhi=5 → suppression (margin=5 == 5)")

# --- AC-CH2-001.2: Ren leads → mercy ---

func test_ac_ch2_001_2_ren_leads_mercy() -> void:
	# Arrange: yi=10, ren=12, zhi=8  →  margin = 10 - max(12,8) = 10 - 12 = -2 < 5
	var bv := {"ren": 12, "yi": 10, "zhi": 8}

	var result: Dictionary = _gate.evaluate(bv)

	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY,
		"yi=10, ren=12, zhi=8 → mercy (margin=-2 < 5)")
	assert_eq(result["branch_key"], "mercy_default")

func test_ac_ch2_001_2_zhi_leads_mercy() -> void:
	# Arrange: yi=10, ren=8, zhi=15  →  margin = 10 - 15 = -5 < 5
	var bv := {"ren": 8, "yi": 10, "zhi": 15}

	var result: Dictionary = _gate.evaluate(bv)

	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY,
		"yi=10, zhi=15 → mercy (margin=-5 < 5)")

# --- AC-CH2-001.3: Triple tie → mercy_default ---

func test_ac_ch2_001_3_triple_equal_mercy_default() -> void:
	# Arrange: yi=ren=zhi=10  →  margin = 10 - 10 = 0 < 5
	var bv := {"ren": 10, "yi": 10, "zhi": 10}

	var result: Dictionary = _gate.evaluate(bv)

	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY,
		"triple equal → mercy")
	assert_eq(result["branch_key"], "mercy_default",
		"triple equal must set branch_key='mercy_default'")

func test_ac_ch2_001_3_yi_ties_with_max_mercy_default() -> void:
	# Arrange: yi=10, ren=10, zhi=8  →  margin = 10 - 10 = 0 < 5
	var bv := {"ren": 10, "yi": 10, "zhi": 8}

	var result: Dictionary = _gate.evaluate(bv)

	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY)
	assert_eq(result["branch_key"], "mercy_default",
		"yi ties with max but below threshold → mercy_default")

# --- Edge: margin just below threshold ---

func test_margin_4_routes_to_mercy() -> void:
	# yi=9, ren=5, zhi=5 → margin=9-5=4 < 5 → mercy
	var bv := {"ren": 5, "yi": 9, "zhi": 5}
	var result: Dictionary = _gate.evaluate(bv)
	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY,
		"margin=4 (< 5) must route to mercy")

# --- Edge: missing keys default to 0 ---

func test_missing_belief_keys_default_to_zero() -> void:
	var bv := {}  # empty dict

	var result: Dictionary = _gate.evaluate(bv)

	# All zeros: yi=0, max(ren,zhi)=0, margin=0 < 5
	assert_eq(result["variant"], BeliefGate.BranchVariant.MERCY)
	assert_eq(result["margin"], 0)

# --- evaluate_and_persist: writes to SaveData ---

func test_evaluate_and_persist_writes_belief_branch() -> void:
	var system := BeliefSystem.new()
	system._values[BeliefSystem.BeliefType.REN] = 5
	system._values[BeliefSystem.BeliefType.YI]  = 15
	system._values[BeliefSystem.BeliefType.ZHI] = 8
	var data := SaveData.new()

	var result: Dictionary = _gate.evaluate_and_persist(system, data)

	assert_eq(data.story_progress["belief_branch"], "suppression")
	assert_eq(result["variant"], BeliefGate.BranchVariant.SUPPRESSION)

	system = null

func test_evaluate_and_persist_mercy_default() -> void:
	var system := BeliefSystem.new()
	system._values[BeliefSystem.BeliefType.REN] = 10
	system._values[BeliefSystem.BeliefType.YI]  = 10
	system._values[BeliefSystem.BeliefType.ZHI] = 10
	var data := SaveData.new()

	_gate.evaluate_and_persist(system, data)

	assert_eq(data.story_progress["belief_branch"], "mercy_default")

	system = null

# --- get_json_branch_key ---

func test_get_json_branch_key_suppression() -> void:
	assert_eq(_gate.get_json_branch_key(BeliefGate.BranchVariant.SUPPRESSION), "suppression")

func test_get_json_branch_key_mercy() -> void:
	assert_eq(_gate.get_json_branch_key(BeliefGate.BranchVariant.MERCY), "mercy")
