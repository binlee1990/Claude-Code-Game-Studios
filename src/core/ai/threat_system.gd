class_name ThreatSystem
extends RefCounted

## Tracks threat values between AI and potential targets.

var _threats: Dictionary = {}  # target_id -> threat_score

## Get threat value for a target
func get_threat(target_id: int) -> float:
	return _threats.get(target_id, 0.0)

## Add threat for dealing damage
func add_damage_threat(target_id: int, damage: int, attacker_id: int = -1) -> void:
	var threat: float = damage * AI.THREAT_DAMAGE_DEALT_RATE
	_threats[target_id] = get_threat(target_id) + threat

## Add threat for receiving damage (reduces own threat to that target)
func add_received_damage_threat(target_id: int, damage: int) -> void:
	var threat: float = damage * AI.THREAT_DAMAGE_RECEIVED_RATE
	_threats[target_id] = maxf(get_threat(target_id) - threat, 0.0)

## Add threat for healing an ally
func add_heal_threat(target_id: int, heal_amount: int) -> void:
	var threat: float = heal_amount * AI.THREAT_HEAL_RATE
	_threats[target_id] = get_threat(target_id) + threat

## Add threat for buffing (fixed amount)
func add_buff_threat(target_id: int) -> void:
	_threats[target_id] = get_threat(target_id) + AI.THREAT_BUFF_FIXED

## Calculate base threat from HP ratio: 100 / current_hp
func calculate_base_threat(current_hp: int) -> float:
	if current_hp <= 0:
		return 999.0
	return 100.0 / float(current_hp)

## Select highest-threat target from list
func select_target(target_ids: Array[int]) -> int:
	var best_id: int = -1
	var best_threat: float = -1.0
	for id in target_ids:
		var t: float = get_threat(id)
		if t > best_threat:
			best_threat = t
			best_id = id
	return best_id

## Select target among killable ones (lowest HP), fall back to highest threat
func select_target_with_priority(killable_ids: Array[int], hp_map: Dictionary) -> int:
	if killable_ids.is_empty():
		return -1
	# Among killable, pick lowest HP
	var best_id: int = killable_ids[0]
	var best_hp: int = hp_map.get(best_id, 9999)
	for id in killable_ids:
		var hp: int = hp_map.get(id, 9999)
		if hp < best_hp:
			best_hp = hp
			best_id = id
	return best_id

## Remove dead target, return next best
func on_target_death(dead_id: int, remaining_ids: Array[int]) -> int:
	_threats.erase(dead_id)
	return select_target(remaining_ids)

## Clear all threat
func clear() -> void:
	_threats.clear()

## Serialize threat data
func serialize() -> Dictionary:
	return _threats.duplicate()

## Load threat data
func deserialize(data: Dictionary) -> void:
	_threats = data.duplicate()
