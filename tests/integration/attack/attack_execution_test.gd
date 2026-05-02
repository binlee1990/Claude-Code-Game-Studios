extends RefCounted

const AttackResolver = preload("res://src/attack/attack_resolver.gd")

var atk_resolver: AttackResolver
var gs: GridSpace
var mp: Map

func before() -> void:
	atk_resolver = AttackResolver.new()
	gs = GridSpace.new()
	mp = Map.new()
	mp.grid_space = gs

func _make_open_map() -> void:
	mp._rows = 5
	mp._cols = 5
	for r in range(5):
		for c in range(5):
			mp._tile_states[Vector2i(r, c)] = Map.TileState.WALKABLE

func _make_unit(faction: Faction.Type, pos: Vector2i, hp_val: int = 10, atk_val: int = 5, def_val: int = 2, rng_val: int = 1) -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	stats.max_hp = maxi(hp_val, 5)
	stats.atk = clampi(atk_val, 3, 8)
	stats.def = def_val
	stats.rng = rng_val
	u.initialize(stats, faction)
	u.grid_position = pos
	u.hp = hp_val
	u.atk = atk_val
	mp.place_unit(u, pos)
	return u

func test_execute_attack_applies_damage() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(result.is_valid)
	assert(result.damage == 3)
	assert(target.hp == 7)
	assert(attacker.has_acted_this_turn)
	assert(attacker.action_state == Unit.UnitState.ACTED)

func test_execute_attack_lethal_kill() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 8, 0, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 3, 3, 1, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(result.lethal)
	assert(target.is_dead())

func test_execute_attack_dead_attacker_rejected() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 0, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(not result.is_valid)

func test_execute_attack_already_acted_rejected() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	attacker.has_acted_this_turn = true
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(not result.is_valid)

func test_execute_attack_wrong_action_state_rejected() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(not result.is_valid)

func test_execute_attack_same_faction_rejected() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var ally := _make_unit(Faction.Type.PLAYER, Vector2i(2, 3), 10, 3, 1, 1)
	var result := atk_resolver.execute_attack(attacker, ally)
	assert(not result.is_valid)

func test_execute_attack_out_of_range_rejected() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(0, 0), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(4, 4), 10, 3, 1, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(not result.is_valid)

func test_execute_attack_moved_state() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.MOVED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(result.is_valid)
	assert(result.damage == 3)

func test_execute_attack_no_counter() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 5, 0, 1)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(result.is_valid)
	assert(attacker.hp == 10, "attacker must not take counter damage")

func test_damage_dealt_signal_emitted() -> void:
	_make_open_map()
	var attacker := _make_unit(Faction.Type.PLAYER, Vector2i(2, 2), 10, 5, 2, 1)
	attacker.action_state = Unit.UnitState.SELECTED
	var target := _make_unit(Faction.Type.ENEMY, Vector2i(2, 3), 10, 3, 2, 1)
	var sig_data := {"fired": false, "damage": 0}
	atk_resolver.damage_dealt.connect(func(_a, _t, d): sig_data["fired"] = true; sig_data["damage"] = d)
	var result := atk_resolver.execute_attack(attacker, target)
	assert(result.is_valid)
	assert(sig_data.fired)
	assert(sig_data.damage == 3)
