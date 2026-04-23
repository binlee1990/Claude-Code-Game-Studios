# tests/unit/turn/speed_up_mode_test.gd
# Story 006: Speed-Up Mode
# Validates AC.4.1 (normal 1×), AC.4.2 (fast 2×), AC.4.3 (max 3×/skip)

extends Gut

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

var _sc: SpeedController

func before_each() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_sc = SpeedController.new(rng)

func after_each() -> void:
	_sc = null

# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------

func test_speed_default_tier_is_normal() -> void:
	# Arrange — fresh controller from before_each

	# Act
	var tier: int = _sc.get_tier()

	# Assert
	assert_eq(tier, SpeedController.SpeedTier.NORMAL,
		"Default tier must be NORMAL on construction")

# ---------------------------------------------------------------------------
# AC.4.1: Normal mode — 1× animation speed, AI delay ∈ [0.5, 1.5]s
# ---------------------------------------------------------------------------

func test_ac_4_1_normal_animation_multiplier_is_1x() -> void:
	# Arrange — tier is NORMAL by default

	# Act
	var multiplier: float = _sc.get_animation_multiplier()

	# Assert
	assert_eq(multiplier, 1.0, "NORMAL tier animation multiplier must be 1.0")

func test_ac_4_1_normal_ai_delay_within_range() -> void:
	# Arrange — tier is NORMAL by default
	var min_delay: float = 0.5
	var max_delay: float = 1.5

	# Act + Assert — 50 samples must all fall within [0.5, 1.5]
	for i in range(50):
		var delay: float = _sc.get_ai_delay()
		assert_true(delay >= min_delay and delay <= max_delay,
			"NORMAL AI delay sample %d (%f) must be in [0.5, 1.5]" % [i, delay])

# ---------------------------------------------------------------------------
# AC.4.2: Fast mode — 2× animation speed, AI delay ∈ [0.2, 0.5]s
# ---------------------------------------------------------------------------

func test_ac_4_2_fast_animation_multiplier_is_2x() -> void:
	# Arrange
	_sc.set_tier(SpeedController.SpeedTier.FAST)

	# Act
	var multiplier: float = _sc.get_animation_multiplier()

	# Assert
	assert_eq(multiplier, 2.0, "FAST tier animation multiplier must be 2.0")

func test_ac_4_2_fast_ai_delay_within_range() -> void:
	# Arrange
	_sc.set_tier(SpeedController.SpeedTier.FAST)
	var min_delay: float = 0.2
	var max_delay: float = 0.5

	# Act + Assert — 50 samples must all fall within [0.2, 0.5]
	for i in range(50):
		var delay: float = _sc.get_ai_delay()
		assert_true(delay >= min_delay and delay <= max_delay,
			"FAST AI delay sample %d (%f) must be in [0.2, 0.5]" % [i, delay])

# ---------------------------------------------------------------------------
# AC.4.3: Max speed — 3× animation speed, AI delay = 0s, skip animations
# ---------------------------------------------------------------------------

func test_ac_4_3_max_animation_multiplier_is_3x() -> void:
	# Arrange
	_sc.set_tier(SpeedController.SpeedTier.MAX)

	# Act
	var multiplier: float = _sc.get_animation_multiplier()

	# Assert
	assert_eq(multiplier, 3.0, "MAX tier animation multiplier must be 3.0")

func test_ac_4_3_max_ai_delay_is_zero() -> void:
	# Arrange
	_sc.set_tier(SpeedController.SpeedTier.MAX)

	# Act + Assert — 20 samples must always be exactly 0.0 (no randomness at MAX)
	for i in range(20):
		var delay: float = _sc.get_ai_delay()
		assert_eq(delay, 0.0,
			"MAX AI delay sample %d must be exactly 0.0" % i)

func test_ac_4_3_max_should_skip_animations() -> void:
	# Arrange + Act (NORMAL)
	assert_false(_sc.should_skip_animations(),
		"NORMAL tier must NOT skip animations")

	# Arrange + Act (FAST)
	_sc.set_tier(SpeedController.SpeedTier.FAST)
	assert_false(_sc.should_skip_animations(),
		"FAST tier must NOT skip animations")

	# Arrange + Act (MAX)
	_sc.set_tier(SpeedController.SpeedTier.MAX)
	assert_true(_sc.should_skip_animations(),
		"MAX tier MUST skip animations (GDD E.6)")

# ---------------------------------------------------------------------------
# Signal: GameEvents.speed_tier_changed
# ---------------------------------------------------------------------------

func test_set_tier_emits_game_events_signal() -> void:
	# Arrange
	var bag := {"fired": false, "old_tier": -1, "new_tier": -1}
	GameEvents.speed_tier_changed.connect(func(old: int, new_t: int) -> void:
		bag["fired"] = true
		bag["old_tier"] = old
		bag["new_tier"] = new_t
	, CONNECT_ONE_SHOT)

	# Act
	_sc.set_tier(SpeedController.SpeedTier.FAST)

	# Assert
	assert_true(bag["fired"], "GameEvents.speed_tier_changed must fire on tier change")
	assert_eq(bag["old_tier"], SpeedController.SpeedTier.NORMAL,
		"old_tier arg must be NORMAL")
	assert_eq(bag["new_tier"], SpeedController.SpeedTier.FAST,
		"new_tier arg must be FAST")

func test_set_tier_emits_internal_tier_changed_signal() -> void:
	# Arrange
	var bag := {"fired": false, "old_tier": -1, "new_tier": -1}
	_sc.tier_changed.connect(func(old: int, new_t: int) -> void:
		bag["fired"] = true
		bag["old_tier"] = old
		bag["new_tier"] = new_t
	, CONNECT_ONE_SHOT)

	# Act
	_sc.set_tier(SpeedController.SpeedTier.MAX)

	# Assert
	assert_true(bag["fired"], "Internal tier_changed signal must fire on tier change")
	assert_eq(bag["old_tier"], SpeedController.SpeedTier.NORMAL,
		"old_tier arg must be NORMAL")
	assert_eq(bag["new_tier"], SpeedController.SpeedTier.MAX,
		"new_tier arg must be MAX")

# ---------------------------------------------------------------------------
# Edge cases: idempotency and invalid input
# ---------------------------------------------------------------------------

func test_set_tier_same_value_no_signal() -> void:
	# Arrange — tier is already NORMAL; use Dictionary bags so counter writes propagate
	var ge_bag := {"count": 0}
	var int_bag := {"count": 0}
	GameEvents.speed_tier_changed.connect(func(_o: int, _n: int) -> void:
		ge_bag["count"] += 1
	, CONNECT_ONE_SHOT)
	_sc.tier_changed.connect(func(_o: int, _n: int) -> void:
		int_bag["count"] += 1
	, CONNECT_ONE_SHOT)

	# Act — set same tier
	_sc.set_tier(SpeedController.SpeedTier.NORMAL)

	# Assert
	assert_eq(ge_bag["count"], 0,
		"GameEvents.speed_tier_changed must NOT fire when tier is unchanged")
	assert_eq(int_bag["count"], 0,
		"Internal tier_changed must NOT fire when tier is unchanged")

func test_set_tier_invalid_value_pushes_error_state_unchanged() -> void:
	# Arrange — tier starts as NORMAL; connect to detect any spurious signal
	var int_bag := {"count": 0}
	_sc.tier_changed.connect(func(_o: int, _n: int) -> void:
		int_bag["count"] += 1
	, CONNECT_ONE_SHOT)

	# Act — invalid tier (push_error is expected internally; we verify state only)
	_sc.set_tier(99)

	# Assert — state must remain NORMAL, no signal emitted
	assert_eq(_sc.get_tier(), SpeedController.SpeedTier.NORMAL,
		"State must remain NORMAL after invalid set_tier call")
	assert_eq(int_bag["count"], 0,
		"No signal must be emitted for invalid tier values")

# ---------------------------------------------------------------------------
# Edge case: mid-combat speed switch applies immediately to next action
# ---------------------------------------------------------------------------

func test_speed_mid_combat_switch_applies_to_next_action() -> void:
	# Arrange — start at NORMAL, verify multiplier
	assert_eq(_sc.get_animation_multiplier(), 1.0,
		"Initial multiplier must be 1.0 (NORMAL)")

	# Act — switch mid-combat to MAX
	_sc.set_tier(SpeedController.SpeedTier.MAX)

	# Assert — next query returns new multiplier immediately
	assert_eq(_sc.get_animation_multiplier(), 3.0,
		"After switching to MAX, multiplier is immediately 3.0 (GDD E.6 edge case)")

# ---------------------------------------------------------------------------
# get_ai_delay_range: all three tiers return correct Vector2 pairs
# ---------------------------------------------------------------------------

func test_get_ai_delay_range_returns_expected_pairs() -> void:
	# Arrange / Act / Assert — NORMAL
	_sc.set_tier(SpeedController.SpeedTier.NORMAL)
	assert_eq(_sc.get_ai_delay_range(), Vector2(0.5, 1.5),
		"NORMAL delay range must be Vector2(0.5, 1.5)")

	# Act / Assert — FAST
	_sc.set_tier(SpeedController.SpeedTier.FAST)
	assert_eq(_sc.get_ai_delay_range(), Vector2(0.2, 0.5),
		"FAST delay range must be Vector2(0.2, 0.5)")

	# Act / Assert — MAX
	_sc.set_tier(SpeedController.SpeedTier.MAX)
	assert_eq(_sc.get_ai_delay_range(), Vector2(0.0, 0.0),
		"MAX delay range must be Vector2(0.0, 0.0)")
