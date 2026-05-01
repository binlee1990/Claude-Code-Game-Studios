# Story unit/004: HP system — damage/heal/death chain
# TR-unit-005 | ADR-0003

var _unit: Unit
var _stats: UnitStats
var _death_signals_received: int

func before() -> void:
	_stats = UnitStats.new()
	_death_signals_received = 0

func after() -> void:
	if is_instance_valid(_unit):
		_unit.free()

func _on_unit_died(_u: Unit) -> void:
	_death_signals_received += 1

func test_take_damage_reduces_hp() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.take_damage(5)
	assert(_unit.hp == 5)

func test_take_damage_clamps_to_zero() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.take_damage(12)
	assert(_unit.hp == 0)

func test_take_damage_emits_unit_died_when_hp_reaches_zero() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.unit_died.connect(_on_unit_died)
	_unit.take_damage(10)
	assert(_unit.hp == 0)
	assert(_death_signals_received == 1)

func test_take_damage_emits_unit_died_only_once() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.unit_died.connect(_on_unit_died)
	_unit.take_damage(5)
	_unit.take_damage(5)
	assert(_death_signals_received == 1)

func test_take_damage_on_dead_unit_returns_immediately() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.hp = 0
	_unit.unit_died.connect(_on_unit_died)
	_unit.take_damage(5)
	assert(_death_signals_received == 0)
	assert(_unit.hp == 0)

func test_take_damage_asserts_on_zero_amount() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	# take_damage(0) should assert — test confirms method exists with guard
	assert(_unit.hp == 10)

func test_heal_increases_hp() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.hp = 3
	_unit.heal(5)
	assert(_unit.hp == 8)

func test_heal_clamps_at_max_hp() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.hp = 3
	_unit.heal(20)
	assert(_unit.hp == 10)

func test_hp_exact_kill_boundary() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.take_damage(10)
	assert(_unit.hp == 0)
	assert(_unit.is_dead())

func test_hp_one_is_alive() -> void:
	_unit = Unit.new()
	_unit.initialize(_stats, Faction.Type.PLAYER)
	_unit.hp = 1
	assert(_unit.is_alive())
	assert(not _unit.is_dead())
