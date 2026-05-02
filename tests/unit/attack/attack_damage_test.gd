extends RefCounted

const AttackResult = preload("res://src/attack/attack_result.gd")

func test_resolve_damage_standard() -> void:
	assert(AttackResult.resolve_damage(5, 2) == 3)

func test_resolve_damage_floor_value_atk_le_def() -> void:
	assert(AttackResult.resolve_damage(3, 5) == 1)
	assert(AttackResult.resolve_damage(3, 3) == 1)
	assert(AttackResult.resolve_damage(4, 4) == 1)

func test_resolve_damage_max_damage() -> void:
	assert(AttackResult.resolve_damage(8, 0) == 8)

func test_resolve_damage_all_combinations_nonzero() -> void:
	for atk in range(3, 9):
		for def_val in range(0, 6):
			assert(AttackResult.resolve_damage(atk, def_val) >= 1, "ATK=%d DEF=%d" % [atk, def_val])

func test_resolve_damage_pure_function() -> void:
	var r1 := AttackResult.resolve_damage(5, 2)
	var r2 := AttackResult.resolve_damage(5, 2)
	assert(r1 == r2)

func test_resolve_damage_out_of_range() -> void:
	assert(AttackResult.resolve_damage(999, -5) == 1004)

func test_attack_result_fields() -> void:
	var u1 := _make_unit(10, 5, 2, 1)
	var u2 := _make_unit(10, 3, 1, 1)
	var result := AttackResult.new(u1, u2, 3, false)
	assert(result.damage == 3)
	assert(not result.lethal)
	assert(result.attacker == u1)
	assert(result.target == u2)

func test_attack_result_lethal_true() -> void:
	var u1 := _make_unit(10, 5, 2, 1)
	var u2 := _make_unit(3, 3, 1, 1)
	var result := AttackResult.new(u1, u2, 5, true)
	assert(result.lethal)

func test_invalid_sentinel() -> void:
	var inv := AttackResult.new()
	assert(not inv.is_valid)

func _make_unit(hp_val: int, atk_val: int, def_val: int, rng_val: int) -> Unit:
	var u := Unit.new()
	var stats := UnitStats.new()
	stats.max_hp = hp_val
	stats.atk = atk_val
	stats.def = def_val
	stats.rng = rng_val
	u.initialize(stats, Faction.Type.PLAYER)
	u.hp = hp_val
	return u
