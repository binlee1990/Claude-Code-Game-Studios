# tests/unit/ai/threat_system_test.gd
# Story 001: Threat/Hate System
# Validates AC.2.1-2.4

extends Gut

var _threat: ThreatSystem

func before_each() -> void:
	_threat = ThreatSystem.new()

# AC.2.1: Damage threat update

func test_damage_threat_50() -> void:
	_threat.add_damage_threat(1, 50)
	assert_eq(_threat.get_threat(1), 5.0, "50 × 0.1 = 5.0")

func test_damage_threat_100() -> void:
	_threat.add_damage_threat(1, 100)
	assert_eq(_threat.get_threat(1), 10.0)

func test_multiple_damage_accumulates() -> void:
	_threat.add_damage_threat(1, 50)
	_threat.add_damage_threat(1, 30)
	assert_eq(_threat.get_threat(1), 8.0, "5.0 + 3.0 = 8.0")

func test_received_damage_reduces_threat() -> void:
	_threat.add_damage_threat(1, 100)
	_threat.add_received_damage_threat(1, 60)
	assert_eq(_threat.get_threat(1), 7.0, "10.0 - 3.0 = 7.0")

func test_threat_floor_zero() -> void:
	_threat.add_damage_threat(1, 10)
	_threat.add_received_damage_threat(1, 999)
	assert_eq(_threat.get_threat(1), 0.0, "Threat cannot go below 0")


# AC.2.2: Healing threat

func test_heal_threat_30() -> void:
	_threat.add_heal_threat(1, 30)
	assert_eq(_threat.get_threat(1), 6.0, "30 × 0.2 = 6.0")

func test_buff_threat_fixed() -> void:
	_threat.add_buff_threat(1)
	assert_eq(_threat.get_threat(1), 10.0, "Buff = +10 fixed")

func test_base_threat_from_hp() -> void:
	assert_eq(_threat.calculate_base_threat(100), 1.0)
	assert_eq(_threat.calculate_base_threat(50), 2.0)
	assert_eq(_threat.calculate_base_threat(10), 10.0)

func test_base_threat_zero_hp() -> void:
	assert_eq(_threat.calculate_base_threat(0), 999.0)


# AC.2.3: Highest threat targeting

func test_select_highest_threat() -> void:
	_threat.add_damage_threat(1, 100)  # 10.0
	_threat.add_damage_threat(2, 50)   # 5.0
	_threat.add_damage_threat(3, 20)   # 2.0
	assert_eq(_threat.select_target([1, 2, 3]), 1)

func test_select_single_target() -> void:
	_threat.add_damage_threat(5, 30)
	assert_eq(_threat.select_target([5]), 5)

func test_select_no_targets() -> void:
	assert_eq(_threat.select_target([]), -1)


# AC.2.4: Target death switching

func test_target_death_switch() -> void:
	_threat.add_damage_threat(1, 100)  # 10.0
	_threat.add_damage_threat(2, 80)   # 8.0
	_threat.add_damage_threat(3, 30)   # 3.0
	var next: int = _threat.on_target_death(1, [2, 3])
	assert_eq(next, 2, "Switches to next highest threat")

func test_all_targets_dead() -> void:
	_threat.add_damage_threat(1, 50)
	var next: int = _threat.on_target_death(1, [])
	assert_eq(next, -1, "No targets remaining")


# Serialization

func test_threat_round_trip() -> void:
	_threat.add_damage_threat(1, 100)
	_threat.add_heal_threat(2, 50)
	var data: Dictionary = _threat.serialize()
	var loaded := ThreatSystem.new()
	loaded.deserialize(data)
	assert_eq(loaded.get_threat(1), 10.0)
	assert_eq(loaded.get_threat(2), 10.0)
