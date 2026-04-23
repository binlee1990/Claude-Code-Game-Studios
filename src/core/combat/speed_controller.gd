class_name SpeedController
extends RefCounted

## Controls combat speed presentation tier.
## Affects animation playback rate and AI decision delay.
## Combat outcomes are identical at all tiers — only presentation changes.
## Implements GDD C.6 and E.6 (design/gdd/turn-based-mode.md), Story 006.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

## The three speed tiers available to the player.
## Ordinal values (0/1/2) are used as Dictionary keys in the lookup tables below.
enum SpeedTier { NORMAL = 0, FAST = 1, MAX = 2 }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Animation playback multiplier per tier. Float values consumed by the
## presentation layer (AnimationPlayer.speed_scale or equivalent).
const _ANIM_MULTIPLIER: Dictionary = {
	SpeedTier.NORMAL: 1.0,
	SpeedTier.FAST: 2.0,
	SpeedTier.MAX: 3.0,
}

## AI decision delay range [min, max] seconds per tier.
## At MAX tier both values are 0.0 so delay is always exactly 0.
const _AI_DELAY_RANGE: Dictionary = {
	SpeedTier.NORMAL: Vector2(0.5, 1.5),
	SpeedTier.FAST: Vector2(0.2, 0.5),
	SpeedTier.MAX: Vector2(0.0, 0.0),  # MAX — no delay, animations may be skipped
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Internal mirror of GameEvents.speed_tier_changed.
## Listeners on this instance use this; cross-system listeners use GameEvents.
signal tier_changed(old_tier: int, new_tier: int)

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _tier: int = SpeedTier.NORMAL
var _rng: RandomNumberGenerator

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

## Inject a RandomNumberGenerator for deterministic testing.
## Pass a seeded RNG in tests; leave null in production (a fresh RNG is created).
##
## Example:
##   var rng := RandomNumberGenerator.new()
##   rng.seed = 12345
##   var sc := SpeedController.new(rng)
func _init(rng: RandomNumberGenerator = null) -> void:
	if rng != null:
		_rng = rng
	else:
		_rng = RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# Tier API
# ---------------------------------------------------------------------------

## Set the active speed tier. Idempotent: no signal emitted if tier is unchanged.
## Invalid tier values log an error and leave state unchanged.
##
## Example:
##   speed_controller.set_tier(SpeedController.SpeedTier.FAST)
func set_tier(new_tier: int) -> void:
	if new_tier == _tier:
		return
	if not _ANIM_MULTIPLIER.has(new_tier):
		push_error("SpeedController.set_tier: invalid tier value %d" % new_tier)
		return
	var old_tier: int = _tier
	_tier = new_tier
	# Emission order: GameEvents first, then instance signal — matches the
	# AutoBattleController convention so cross-system listeners and local
	# listeners see a consistent broadcast-then-local sequence across the codebase.
	GameEvents.speed_tier_changed.emit(old_tier, new_tier)
	tier_changed.emit(old_tier, new_tier)

## Returns the current speed tier as a SpeedTier enum integer.
##
## Example:
##   var t: int = speed_controller.get_tier()  # SpeedController.SpeedTier.NORMAL
func get_tier() -> int:
	return _tier

# ---------------------------------------------------------------------------
# Presentation helpers
# ---------------------------------------------------------------------------

## Returns the animation playback rate multiplier for the current tier.
## Apply to AnimationPlayer.speed_scale (or equivalent) in the presentation layer.
##
## Example:
##   animation_player.speed_scale = speed_controller.get_animation_multiplier()
func get_animation_multiplier() -> float:
	return _ANIM_MULTIPLIER[_tier]

## Returns the AI decision delay in seconds for the current tier.
## At MAX tier this is always 0.0. At other tiers the value is randomised
## within the range defined by _AI_DELAY_RANGE.
##
## Example:
##   await get_tree().create_timer(speed_controller.get_ai_delay()).timeout
func get_ai_delay() -> float:
	var range_vec: Vector2 = _AI_DELAY_RANGE[_tier]
	if range_vec.x == range_vec.y:
		return range_vec.x
	return _rng.randf_range(range_vec.x, range_vec.y)

## Returns the [min, max] AI delay range for the current tier.
## Useful for inspection and testing without consuming an RNG sample.
##
## Example:
##   var r: Vector2 = speed_controller.get_ai_delay_range()  # Vector2(0.5, 1.5)
func get_ai_delay_range() -> Vector2:
	return _AI_DELAY_RANGE[_tier]

## Returns true when animations should be skipped entirely (MAX tier only).
## At MAX tier the presentation layer shows only results (damage numbers remain visible).
## Implements GDD E.6.
##
## Example:
##   if speed_controller.should_skip_animations():
##       apply_results_immediately()
func should_skip_animations() -> bool:
	return _tier == SpeedTier.MAX

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

## Serialize current speed tier to a Dictionary for save/load integration.
## Implements Story 007 (design/gdd/turn-based-mode.md AC-S3).
func serialize() -> Dictionary:
	return {"tier": _tier}

## Restore speed tier from serialized data. Unknown keys ignored.
## Invalid tier values fall back to NORMAL.
## Direct assignment — does NOT emit tier_changed (loading is not a user action).
func deserialize(data: Dictionary) -> void:
	var t: int = data.get("tier", SpeedTier.NORMAL)
	if not _ANIM_MULTIPLIER.has(t):
		t = SpeedTier.NORMAL
	_tier = t
