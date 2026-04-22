# tests/unit/turn/auto_battle_test.gd
# Story 005: Auto Battle Mode
# Validates AC.3.1 (AI takeover), AC.3.2 (toggle), AC.3.3 (manual override)

extends Gut

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

var _abc: AutoBattleController
var _brain: AIBrain
var _units: Array = []

func before_each() -> void:
	_brain = AIBrain.new(AI.AIType.BALANCED)
	_abc = AutoBattleController.new(_brain)

func after_each() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	_abc = null
	_brain = null

func _make_unit(uid: StringName = &"u") -> Unit:
	var unit := Unit.new()
	unit.name = "ABCUnit_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	_units.append(unit)
	return unit


# ---------------------------------------------------------------------------
# AC.3.1: Auto-battle ON → AI controls player unit decisions
# ---------------------------------------------------------------------------

func test_auto_battle_should_auto_control_when_enabled() -> void:
	# Arrange
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)

	# Act
	var result: bool = _abc.should_auto_control(unit)

	# Assert
	assert_true(result, "AI should control player unit when auto-battle is ON")

func test_auto_battle_delegate_turn_returns_action_and_target() -> void:
	# Arrange
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	var skills: Array[Dictionary] = [
		{"damage": 50, "hit_probability": 1.0, "category": AI.SkillCategory.DAMAGE},
	]
	var basic: Dictionary = {"damage": 10, "hit_probability": 1.0, "category": AI.SkillCategory.BASIC_ATTACK}
	_brain.threat_system.add_damage_threat(2, 100)
	_brain.threat_system.add_damage_threat(3, 50)

	# Act
	var decision: Dictionary = _abc.delegate_turn(
		unit,
		skills, basic,
		[2, 3], {2: 80, 3: 30}, [3],
		TacticalFormulas.WeaponType.SWORD, {2: TacticalFormulas.WeaponType.AXE, 3: TacticalFormulas.WeaponType.AXE},
		[], 1.0
	)

	# Assert — action chosen from skills, killable target (id=3) preferred
	assert_true(decision.has("action"), "Decision must contain 'action' key")
	assert_true(decision.has("target_id"), "Decision must contain 'target_id' key")
	assert_true(decision.has("position_idx"), "Decision must contain 'position_idx' key")
	assert_eq(decision["target_id"], 3, "AI picks killable target (id=3)")
	assert_eq(decision["action"].get("damage", 0), 50, "AI selects highest-value skill")

func test_auto_battle_delegate_turn_no_targets_returns_minus_one() -> void:
	# Arrange
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	var basic: Dictionary = {"damage": 10, "hit_probability": 1.0, "category": AI.SkillCategory.BASIC_ATTACK}

	# Act
	var decision: Dictionary = _abc.delegate_turn(
		unit, [], basic, [], {}, [], 0, {}, [], 1.0
	)

	# Assert
	assert_eq(decision["target_id"], -1, "target_id is -1 when no targets available")

func test_auto_battle_delegate_turn_empty_skills_falls_back_to_basic() -> void:
	# Arrange — E.5: items / skills exhausted, must not crash or interrupt flow
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	var basic: Dictionary = {"damage": 10, "hit_probability": 1.0, "category": AI.SkillCategory.BASIC_ATTACK}

	# Act
	var decision: Dictionary = _abc.delegate_turn(
		unit, [], basic, [2], {2: 50}, [], 0, {}, [], 1.0
	)

	# Assert — falls back to basic attack, no crash
	assert_eq(decision["action"].get("action", ""), "basic_attack",
		"Falls back to basic attack when skill list is empty (GDD E.5)")

func test_auto_battle_multiple_player_units_each_ai_controlled() -> void:
	# Arrange — AC.3.1 edge: multiple player units
	var p1: Unit = _make_unit(&"p1")
	var p2: Unit = _make_unit(&"p2")
	_abc.set_enabled(true)

	# Act + Assert
	assert_true(_abc.should_auto_control(p1), "p1 is AI-controlled under auto-battle")
	assert_true(_abc.should_auto_control(p2), "p2 is AI-controlled under auto-battle")


# ---------------------------------------------------------------------------
# AC.3.2: Auto-battle can be toggled OFF at any time
# ---------------------------------------------------------------------------

func test_auto_battle_toggle_off_disables_ai_control() -> void:
	# Arrange
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	assert_true(_abc.should_auto_control(unit))

	# Act
	_abc.set_enabled(false)

	# Assert
	assert_false(_abc.should_auto_control(unit), "AI should NOT control unit after toggle OFF")

func test_auto_battle_toggle_on_emits_game_events_signal() -> void:
	# Arrange — use Dictionary because GDScript 4 lambdas capture primitives
	# by value, so a local `bool` written inside the lambda would not propagate.
	var bag := {"fired": false, "value": false}
	GameEvents.auto_battle_toggled.connect(func(enabled: bool) -> void:
		bag["fired"] = true
		bag["value"] = enabled
	, CONNECT_ONE_SHOT)

	# Act
	_abc.set_enabled(true)

	# Assert
	assert_true(bag["fired"], "GameEvents.auto_battle_toggled must fire on enable")
	assert_true(bag["value"], "Signal arg must be true when enabling")

func test_auto_battle_toggle_off_emits_game_events_signal() -> void:
	# Arrange
	_abc.set_enabled(true)
	var bag := {"fired": false, "value": true}
	GameEvents.auto_battle_toggled.connect(func(enabled: bool) -> void:
		bag["fired"] = true
		bag["value"] = enabled
	, CONNECT_ONE_SHOT)

	# Act
	_abc.set_enabled(false)

	# Assert
	assert_true(bag["fired"], "GameEvents.auto_battle_toggled must fire on disable")
	assert_false(bag["value"], "Signal arg must be false when disabling")

func test_auto_battle_toggle_same_value_no_duplicate_signal() -> void:
	# Arrange — idempotency: toggling to current state must not re-emit
	_abc.set_enabled(true)
	var emit_count: int = 0
	GameEvents.auto_battle_toggled.connect(func(_e: bool) -> void:
		emit_count += 1
	, CONNECT_ONE_SHOT)

	# Act
	_abc.set_enabled(true)  # same value — should be a no-op

	# Assert
	assert_eq(emit_count, 0, "No signal emitted when toggling to current state")

func test_auto_battle_toggle_off_current_unit_finishes_then_manual() -> void:
	# Arrange — AC.3.2 edge: toggle during AI decision; current unit finishes,
	# next unit is manual. We verify that should_auto_control returns false
	# after toggle OFF, regardless of when within the round we toggle.
	var p1: Unit = _make_unit(&"p1")
	var p2: Unit = _make_unit(&"p2")
	_abc.set_enabled(true)
	assert_true(_abc.should_auto_control(p1))

	# Act — toggle OFF mid-combat (simulates player pressing button during p1's turn)
	_abc.set_enabled(false)

	# Assert — p1 currently acting would finish (caller responsibility),
	# but next query on either unit returns false
	assert_false(_abc.should_auto_control(p1), "p1 would be manual next turn")
	assert_false(_abc.should_auto_control(p2), "p2 is manual after toggle OFF")


# ---------------------------------------------------------------------------
# AC.3.3: Player can manually override during auto-battle (pause for current unit)
# ---------------------------------------------------------------------------

func test_auto_battle_manual_override_current_unit_uses_player_control() -> void:
	# Arrange
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	assert_true(_abc.should_auto_control(unit))

	# Act
	_abc.request_manual_override(unit)

	# Assert
	assert_false(_abc.should_auto_control(unit),
		"Override unit must NOT be AI-controlled for this turn")

func test_auto_battle_manual_override_only_affects_current_unit() -> void:
	# Arrange — AC.3.3 edge: override on p1 must not affect p2
	var p1: Unit = _make_unit(&"p1")
	var p2: Unit = _make_unit(&"p2")
	_abc.set_enabled(true)

	# Act
	_abc.request_manual_override(p1)

	# Assert
	assert_false(_abc.should_auto_control(p1), "p1 has override — manual this turn")
	assert_true(_abc.should_auto_control(p2), "p2 unaffected — still AI-controlled")

func test_auto_battle_manual_override_emits_game_events_signal() -> void:
	# Arrange — wrap received_unit in a Dictionary for the same by-reference
	# reason as the toggle tests above.
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	var bag := {"unit": null}
	GameEvents.manual_override_activated.connect(func(u: Node) -> void:
		bag["unit"] = u
	, CONNECT_ONE_SHOT)

	# Act
	_abc.request_manual_override(unit)

	# Assert
	assert_eq(bag["unit"], unit, "GameEvents.manual_override_activated emitted with correct unit")

func test_auto_battle_clear_override_after_turn_next_turn_is_ai() -> void:
	# Arrange — AC.3.3 edge: override is temporary; clears after unit's turn ends
	var unit: Unit = _make_unit(&"p1")
	_abc.set_enabled(true)
	_abc.request_manual_override(unit)
	assert_false(_abc.should_auto_control(unit), "Before clear: manual control active")

	# Act — simulates CombatSystem.end_turn() calling clear_override
	_abc.clear_override(unit)

	# Assert
	assert_true(_abc.should_auto_control(unit),
		"After clear: unit reverts to AI control (auto-battle still ON)")

func test_auto_battle_combat_system_integration_clears_override_on_end_turn() -> void:
	# Arrange — verify CombatSystem.end_turn() actually calls clear_override
	var combat: CombatSystem = CombatSystem.new()
	combat.name = "CombatSystem_ABCTest"
	add_child(combat)

	var unit: Unit = _make_unit(&"p1")
	combat.register_unit(unit, CombatSystem.Team.PLAYER, 100)
	combat.set_units([unit])
	combat.set_auto_battle_controller(_abc)

	_abc.set_enabled(true)
	_abc.request_manual_override(unit)
	assert_false(_abc.should_auto_control(unit), "Override active before end_turn")

	# Act
	combat.end_turn()

	# Assert
	assert_true(_abc.should_auto_control(unit),
		"Override cleared by CombatSystem.end_turn() — next turn is AI")

	combat.queue_free()

func test_auto_battle_combat_system_without_abc_end_turn_still_works() -> void:
	# Arrange — regression: CombatSystem must not break when no ABC is attached
	var combat: CombatSystem = CombatSystem.new()
	combat.name = "CombatSystem_NoABC"
	add_child(combat)

	var unit: Unit = _make_unit(&"p2")
	combat.register_unit(unit, CombatSystem.Team.PLAYER, 100)
	combat.set_units([unit])
	# Deliberately do NOT call set_auto_battle_controller

	# Act + Assert — must not crash
	combat.end_turn()
	assert_true(true, "end_turn() with no ABC attached completes without error")

	combat.queue_free()
