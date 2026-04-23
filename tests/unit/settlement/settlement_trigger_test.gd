# tests/unit/settlement/settlement_trigger_test.gd
# Story BS-001: Settlement Trigger & Flow
# Validates AC.1.1 (victory), AC.1.2 (defeat), AC.1.3 (retreat), edge cases, signal emission

extends Gut

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

var _trigger: SettlementTrigger
var _units: Array = []

func before_each() -> void:
	_trigger = SettlementTrigger.new()

func after_each() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	_trigger = null

func _make_unit(uid: StringName = &"u") -> Unit:
	var unit := Unit.new()
	unit.name = "SettlementUnit_" + str(uid)
	unit.unit_id = uid
	add_child(unit)
	_units.append(unit)
	return unit

# ---------------------------------------------------------------------------
# AC.1.1: Victory settlement
# ---------------------------------------------------------------------------

func test_ac_1_1_victory_triggers_victory_type() -> void:
	# Arrange
	var players: Array = [_make_unit(&"p1")]

	# Act
	var result: SettlementResult = _trigger.trigger_victory(players)

	# Assert
	assert_eq(result.type, SettlementResult.SettlementType.VICTORY,
		"trigger_victory must produce type VICTORY")
	assert_true(result.rewards_enabled,
		"VICTORY must set rewards_enabled = true (GDD C.1)")

func test_ac_1_1_victory_preserves_surviving_players() -> void:
	# Arrange
	var players: Array = [_make_unit(&"p1"), _make_unit(&"p2")]

	# Act
	var result: SettlementResult = _trigger.trigger_victory(players)

	# Assert
	assert_eq(result.surviving_players.size(), 2,
		"VICTORY result must contain all 2 surviving players")

func test_ac_1_1_victory_last_enemy_counterattack_edge() -> void:
	# Arrange — GDD E.1 edge: last enemy killed by counterattack is still victory.
	# Semantically: trigger_victory is called with correct survivors regardless of
	# the kill source; we verify the result is always VICTORY.
	var players: Array = [_make_unit(&"p1")]

	# Act — simulate: combat flow called trigger_victory after counterattack kill
	var result: SettlementResult = _trigger.trigger_victory(players)

	# Assert
	assert_eq(result.type, SettlementResult.SettlementType.VICTORY,
		"Counterattack kill of last enemy must still yield VICTORY (GDD E.1)")
	assert_true(result.rewards_enabled,
		"rewards_enabled must be true even when last kill was a counterattack")

# ---------------------------------------------------------------------------
# AC.1.2: Defeat settlement
# ---------------------------------------------------------------------------

func test_ac_1_2_defeat_triggers_defeat_type() -> void:
	# Arrange
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.trigger_defeat(enemies)

	# Assert
	assert_eq(result.type, SettlementResult.SettlementType.DEFEAT,
		"trigger_defeat must produce type DEFEAT")
	assert_false(result.rewards_enabled,
		"DEFEAT must set rewards_enabled = false (GDD C.1 — no EXP, no gold)")

func test_ac_1_2_defeat_clears_surviving_players() -> void:
	# Arrange
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.trigger_defeat(enemies)

	# Assert
	assert_eq(result.surviving_players.size(), 0,
		"DEFEAT result surviving_players must be empty")

# ---------------------------------------------------------------------------
# AC.1.3: Retreat settlement
# ---------------------------------------------------------------------------

func test_ac_1_3_retreat_triggers_retreat_type_when_allowed() -> void:
	# Arrange
	var players: Array = [_make_unit(&"p1")]
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.trigger_retreat(true, players, enemies)

	# Assert
	assert_ne(result, null,
		"trigger_retreat with can_retreat=true must return a result")
	assert_eq(result.type, SettlementResult.SettlementType.RETREAT,
		"Allowed retreat must produce type RETREAT")
	assert_false(result.rewards_enabled,
		"RETREAT must set rewards_enabled = false (treated as defeat, GDD C.1)")

func test_ac_1_3_retreat_returns_null_when_not_allowed() -> void:
	# Arrange — GDD E.5: no retreat skill/item → cannot trigger retreat
	var players: Array = [_make_unit(&"p1")]
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.trigger_retreat(false, players, enemies)

	# Assert
	assert_eq(result, null,
		"trigger_retreat with can_retreat=false must return null (GDD E.5)")

# ---------------------------------------------------------------------------
# GDD E.2 precedence: both sides die same action → victory
# ---------------------------------------------------------------------------

func test_precedence_both_dead_resolves_to_victory() -> void:
	# Arrange — GDD E.2: enemies checked first, so even if all players also die,
	# the result is still VICTORY
	var players: Array = []
	var enemies: Array = []

	# Act
	var result: SettlementResult = _trigger.resolve(false, false, players, enemies)

	# Assert
	assert_ne(result, null,
		"resolve with both sides dead must return a result, not null")
	assert_eq(result.type, SettlementResult.SettlementType.VICTORY,
		"GDD E.2: enemies checked first → simultaneous death resolves as VICTORY")

func test_resolve_neither_defeated_returns_null() -> void:
	# Arrange — combat still in progress, no side eliminated
	var players: Array = [_make_unit(&"p1")]
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.resolve(true, true, players, enemies)

	# Assert
	assert_eq(result, null,
		"resolve when both sides have survivors must return null (combat ongoing)")

func test_resolve_only_players_dead_resolves_to_defeat() -> void:
	# Arrange — all players dead, enemies remain
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	var result: SettlementResult = _trigger.resolve(true, false, [], enemies)

	# Assert
	assert_ne(result, null,
		"resolve with all players dead must return a result")
	assert_eq(result.type, SettlementResult.SettlementType.DEFEAT,
		"All players dead with enemies alive must resolve as DEFEAT")

# ---------------------------------------------------------------------------
# Signal: GameEvents.settlement_triggered
# ---------------------------------------------------------------------------

func test_victory_emits_settlement_triggered_signal() -> void:
	# Arrange
	var bag := {"fired": false, "result_type": -1}
	GameEvents.settlement_triggered.connect(func(r: SettlementResult) -> void:
		bag["fired"] = true
		bag["result_type"] = r.type
	, CONNECT_ONE_SHOT)
	var players: Array = [_make_unit(&"p1")]

	# Act
	_trigger.trigger_victory(players)

	# Assert
	assert_true(bag["fired"],
		"GameEvents.settlement_triggered must fire on trigger_victory")
	assert_eq(bag["result_type"], SettlementResult.SettlementType.VICTORY,
		"Signal result.type must be VICTORY")

func test_defeat_emits_settlement_triggered_signal() -> void:
	# Arrange
	var bag := {"fired": false, "result_type": -1}
	GameEvents.settlement_triggered.connect(func(r: SettlementResult) -> void:
		bag["fired"] = true
		bag["result_type"] = r.type
	, CONNECT_ONE_SHOT)
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	_trigger.trigger_defeat(enemies)

	# Assert
	assert_true(bag["fired"],
		"GameEvents.settlement_triggered must fire on trigger_defeat")
	assert_eq(bag["result_type"], SettlementResult.SettlementType.DEFEAT,
		"Signal result.type must be DEFEAT")

func test_retreat_allowed_emits_signal() -> void:
	# Arrange
	var bag := {"fired": false, "result_type": -1}
	GameEvents.settlement_triggered.connect(func(r: SettlementResult) -> void:
		bag["fired"] = true
		bag["result_type"] = r.type
	, CONNECT_ONE_SHOT)
	var players: Array = [_make_unit(&"p1")]
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	_trigger.trigger_retreat(true, players, enemies)

	# Assert
	assert_true(bag["fired"],
		"GameEvents.settlement_triggered must fire when retreat is allowed")
	assert_eq(bag["result_type"], SettlementResult.SettlementType.RETREAT,
		"Signal result.type must be RETREAT")

func test_retreat_blocked_does_not_emit_signal() -> void:
	# Arrange — GDD E.5: blocked retreat must emit nothing
	var bag := {"count": 0}
	GameEvents.settlement_triggered.connect(func(_r: SettlementResult) -> void:
		bag["count"] += 1
	, CONNECT_ONE_SHOT)
	var players: Array = [_make_unit(&"p1")]
	var enemies: Array = [_make_unit(&"e1")]

	# Act
	_trigger.trigger_retreat(false, players, enemies)

	# Assert
	assert_eq(bag["count"], 0,
		"GameEvents.settlement_triggered must NOT fire when retreat is blocked (GDD E.5)")

# ---------------------------------------------------------------------------
# Serialization: to_dict
# ---------------------------------------------------------------------------

func test_to_dict_serializes_surviving_unit_ids() -> void:
	# Arrange
	var p1: Unit = _make_unit(&"hero_001")
	var p2: Unit = _make_unit(&"hero_002")
	var players: Array = [p1, p2]

	# Act
	var result: SettlementResult = _trigger.trigger_victory(players)
	var d: Dictionary = result.to_dict()

	# Assert
	assert_true(d.has("surviving_player_ids"),
		"to_dict must include surviving_player_ids key")
	assert_eq(d["surviving_player_ids"].size(), 2,
		"to_dict surviving_player_ids must contain 2 entries")
	assert_true(d["surviving_player_ids"].has("hero_001"),
		"to_dict must include unit_id 'hero_001'")
	assert_true(d["surviving_player_ids"].has("hero_002"),
		"to_dict must include unit_id 'hero_002'")
	assert_eq(d["type"], SettlementResult.SettlementType.VICTORY,
		"to_dict type field must match VICTORY")
	assert_true(d["rewards_enabled"],
		"to_dict rewards_enabled must be true for VICTORY")
