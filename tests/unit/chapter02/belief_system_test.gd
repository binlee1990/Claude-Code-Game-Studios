# tests/unit/chapter02/belief_system_test.gd
# Story CH2-c-001: Belief System — clamped arithmetic + signal emission
# Validates AC-CH2-007 (belief value clamp)

extends Gut

var _system: BeliefSystem

func before_each() -> void:
	_system = BeliefSystem.new()

func after_each() -> void:
	_system = null

# --- AC-CH2-007.1: Positive overflow clamp ---

func test_ac_ch2_007_1_positive_overflow_clamps_to_100() -> void:
	# Arrange: ren = 95, delta = +10
	_system._values[BeliefSystem.BeliefType.REN] = 95

	# Act
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.REN, 10)

	# Assert: should only add +5 (clamp to 100)
	assert_eq(applied, 5, "95 + 10 should clamp to +5 applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 100,
		"ren should be clamped to 100")

func test_ac_ch2_007_1_exact_cap_no_overflow() -> void:
	# Arrange: ren = 100, delta = +10
	_system._values[BeliefSystem.BeliefType.REN] = 100

	# Act
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.REN, 10)

	# Assert
	assert_eq(applied, 0, "Already at cap, no change applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 100)

# --- AC-CH2-007.2: Negative overflow clamp ---

func test_ac_ch2_007_2_negative_overflow_clamps_to_0() -> void:
	# Arrange: yi = 3, delta = -8
	_system._values[BeliefSystem.BeliefType.YI] = 3

	# Act
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.YI, -8)

	# Assert: should only subtract -3 (clamp to 0)
	assert_eq(applied, -3, "3 - 8 should clamp to -3 applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI), 0,
		"yi should be clamped to 0")

func test_ac_ch2_007_2_exact_floor_no_overflow() -> void:
	# Arrange: yi = 0, delta = -5
	_system._values[BeliefSystem.BeliefType.YI] = 0

	# Act
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.YI, -5)

	# Assert
	assert_eq(applied, 0, "Already at floor, no change applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI), 0)

# --- General: normal arithmetic ---

func test_normal_positive_delta_fully_applied() -> void:
	_system._values[BeliefSystem.BeliefType.REN] = 50
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.REN, 10)
	assert_eq(applied, 10, "Normal positive delta fully applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 60)

func test_normal_negative_delta_fully_applied() -> void:
	_system._values[BeliefSystem.BeliefType.YI] = 50
	var applied: int = _system.apply_change(BeliefSystem.BeliefType.YI, -10)
	assert_eq(applied, -10, "Normal negative delta fully applied")
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI), 40)

# --- Signal: belief_changed emits ---

func test_belief_changed_signal_fires_on_apply() -> void:
	var bag := {"fired": false, "belief": -1, "delta": 0, "applied": 0, "new_val": 0}
	GameEvents.belief_changed.connect(func(b, d, a, n):
		bag["fired"] = true
		bag["belief"] = b
		bag["delta"] = d
		bag["applied"] = a
		bag["new_val"] = n
	, CONNECT_ONE_SHOT)

	_system.apply_change(BeliefSystem.BeliefType.ZHI, 5)

	assert_true(bag["fired"], "belief_changed signal must fire")
	assert_eq(bag["belief"], BeliefSystem.BeliefType.ZHI)
	assert_eq(bag["delta"], 5)
	assert_eq(bag["applied"], 5)
	assert_eq(bag["new_val"], 5)

func test_belief_changed_signal_reports_clamped_applied() -> void:
	_system._values[BeliefSystem.BeliefType.REN] = 95
	var bag := {"applied": 0}
	GameEvents.belief_changed.connect(func(_b, _d, a, _n):
		bag["applied"] = a
	, CONNECT_ONE_SHOT)

	_system.apply_change(BeliefSystem.BeliefType.REN, 10)

	assert_eq(bag["applied"], 5, "Signal reports clamped amount (+5, not +10)")

# --- Save/Load: persistence ---

func test_save_to_save_data_preserves_values() -> void:
	_system._values[BeliefSystem.BeliefType.REN] = 42
	_system._values[BeliefSystem.BeliefType.YI]  = 55
	_system._values[BeliefSystem.BeliefType.ZHI] = 13

	var data := SaveData.new()
	_system.save_to_save_data(data)

	var bv: Dictionary = data.story_progress["belief_values"]
	assert_eq(bv["ren"], 42)
	assert_eq(bv["yi"],  55)
	assert_eq(bv["zhi"], 13)

func test_load_from_save_data_restores_values() -> void:
	var data := SaveData.new()
	data.story_progress["belief_values"] = {"ren": 30, "yi": 60, "zhi": 10}

	_system.load_from_save_data(data)

	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 30)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI),  60)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.ZHI), 10)

func test_load_from_save_data_missing_key_defaults_to_zero() -> void:
	var data := SaveData.new()
	data.story_progress = {}

	_system.load_from_save_data(data)

	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 0)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI),  0)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.ZHI), 0)

func test_reset_clears_all_values() -> void:
	_system._values[BeliefSystem.BeliefType.REN] = 99
	_system._values[BeliefSystem.BeliefType.YI]  = 99
	_system._values[BeliefSystem.BeliefType.ZHI] = 99

	_system.reset()

	assert_eq(_system.get_value(BeliefSystem.BeliefType.REN), 0)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.YI),  0)
	assert_eq(_system.get_value(BeliefSystem.BeliefType.ZHI), 0)
