# tests/unit/chapter02/boss_phase_test.gd
# Story CH2-c-005: Boss Phase Controller — three-phase + checkpoint + reinforcements
# Validates AC-CH2-005 + AC-CH2-006

extends Gut

var _boss: BossPhaseController

func before_each() -> void:
	_boss = BossPhaseController.new()
	_boss.init(130, 1)

func after_each() -> void:
	_boss = null

# --- Phase transitions ---

func test_starts_in_phase_1() -> void:
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_1)
	assert_eq(_boss.get_boss_hp(), 130)

func test_phase_1_to_2_at_65_percent() -> void:
	# 65% of 130 = 84.5 → HP=84 triggers phase 2
	var transitions := _boss.on_boss_hp_changed(84)
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_2,
		"HP=84/130 (64.6%) should trigger phase 2")

func test_phase_2_not_triggered_above_65_percent() -> void:
	# 66% of 130 ≈ 85.8 → HP=86 stays phase 1
	_boss.on_boss_hp_changed(86)
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_1,
		"HP=86/130 (66.2%) should stay phase 1")

func test_phase_2_to_3_at_30_percent() -> void:
	_boss.on_boss_hp_changed(84)  # phase 2
	var transitions := _boss.on_boss_hp_changed(39)
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_3,
		"HP=39/130 (30%) should trigger phase 3")

func test_phase_3_not_triggered_above_30_percent() -> void:
	_boss.on_boss_hp_changed(84)  # phase 2
	_boss.on_boss_hp_changed(40)  # 30.8% > 30%
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_2,
		"HP=40/130 (30.8%) should stay phase 2")

func test_boss_defeated_at_zero_hp() -> void:
	_boss.on_boss_hp_changed(84)  # phase 2
	_boss.on_boss_hp_changed(39)  # phase 3
	_boss.on_boss_hp_changed(0)   # defeated
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.DEFEATED,
		"HP=0 should trigger DEFEATED")

# --- Skip threshold: single hit crosses multiple phases ---

func test_single_hit_crosses_two_phases() -> void:
	# HP goes from 130 → 20 (15.4%) directly, crossing both 65% and 30%
	var transitions := _boss.on_boss_hp_changed(20)
	assert_eq(transitions.size(), 2,
		"Should produce 2 transitions when crossing both thresholds")
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_3)

func test_single_hit_to_zero_crosses_all() -> void:
	var transitions := _boss.on_boss_hp_changed(0)
	# Phase 1→2, 2→3, 3→DEFEATED = 3 transitions
	assert_eq(transitions.size(), 3)
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.DEFEATED)

# --- AC-CH2-005.1: Normal reinforcement at turn 12 ---

func test_ac_ch2_005_1_reinforcement_at_turn_12() -> void:
	var result := _boss.on_round_start(11)
	assert_false(result["spawn"], "Turn 11 should not spawn reinforcements")

	result = _boss.on_round_start(12)
	assert_true(result["spawn"], "Turn 12 should spawn reinforcements")
	assert_eq(result["count"], 2)
	assert_true(_boss.are_reinforcements_spawned())

func test_reinforcements_only_spawn_once() -> void:
	_boss.on_round_start(12)  # spawn
	var result := _boss.on_round_start(13)
	assert_false(result["spawn"], "Reinforcements should not spawn again")

# --- AC-CH2-005.2: Early reinforcement when phase 3 at turn < 10 ---

func test_ac_ch2_005_2_early_reinforcement_at_turn_10() -> void:
	# Boss enters phase 3 at turn 8
	_boss.on_boss_hp_changed(84)  # phase 2
	_boss.on_boss_hp_changed(39)  # phase 3 (turn still 1, < 10)

	# Reinforcement should be scheduled for turn 10
	assert_eq(_boss.get_reinforcement_turn(), 10,
		"Phase 3 at early turn should schedule reinforcements for turn 10")

	var result := _boss.on_round_start(10)
	assert_true(result["spawn"], "Reinforcements should spawn at turn 10 (early)")

func test_no_early_reinforcement_if_phase3_after_10() -> void:
	_boss.init(130, 11)
	_boss.on_round_start(11)
	_boss.on_boss_hp_changed(84)  # phase 2
	_boss.on_boss_hp_changed(39)  # phase 3 at turn >= 10

	# Already past early turn, keep default turn 12
	assert_eq(_boss.get_reinforcement_turn(), 12)

# --- AC-CH2-005.3: Reinforcements don't affect victory ---

func test_ac_ch2_005_3_victory_still_boss_hp_zero() -> void:
	_boss.on_round_start(12)  # spawn reinforcements
	_boss.on_boss_hp_changed(84)
	_boss.on_boss_hp_changed(39)
	_boss.on_boss_hp_changed(0)
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.DEFEATED,
		"Victory when boss HP=0 regardless of reinforcements")

# --- AC-CH2-006.1: Checkpoint saves on phase transition ---

func test_ac_ch2_006_1_checkpoint_saves_on_phase_transition() -> void:
	_boss.on_boss_hp_changed(84)  # phase 1→2, saves checkpoint
	# Checkpoint should exist with phase=PHASE_1
	var cp := _boss.restore_last_checkpoint()
	assert_eq(cp["phase"], BossPhaseController.Phase.PHASE_1,
		"Checkpoint should record the phase before transition")

func test_ac_ch2_006_1_checkpoint_hp_retained_at_15_percent() -> void:
	# max_hp=130, 15% = 19.5 → 19
	_boss.on_boss_hp_changed(84)
	var cp := _boss.restore_last_checkpoint()
	assert_eq(_boss.get_boss_hp(), 19,
		"Boss HP should be max_hp × 0.15 = 130 × 0.15 = 19.5 → 19")

# --- AC-CH2-006.2: Checkpoint restores player state ---

func test_ac_ch2_006_2_checkpoint_keeps_player_state() -> void:
	_boss.on_boss_hp_changed(84)
	var cp := _boss.restore_last_checkpoint()
	assert_true(cp.has("player_snapshot"),
		"Checkpoint must include player_snapshot field")

# --- Restore with no checkpoints ---

func test_restore_no_checkpoint_gives_full_hp() -> void:
	var cp := _boss.restore_last_checkpoint()
	assert_eq(cp["boss_hp"], 130,
		"No checkpoint should restore to full HP")
	assert_eq(cp["phase"], BossPhaseController.Phase.PHASE_1,
		"No checkpoint should restore to phase 1")

# --- Config: custom thresholds ---

func test_load_config_custom_thresholds() -> void:
	_boss.load_config({
		"boss_phase_thresholds": [0.70, 0.35],
		"boss_max_hp": 200,
		"reinforce_trigger_turn": 10,
		"reinforce_phase3_early_turn": 8,
	})
	_boss.init(200, 1)

	# Phase 2 at 70% = 140
	_boss.on_boss_hp_changed(139)  # 69.5% < 70%
	assert_eq(_boss.get_current_phase(), BossPhaseController.Phase.PHASE_2)
