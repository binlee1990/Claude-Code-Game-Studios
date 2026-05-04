class_name CombatCalculator
extends RefCounted

const MIN_DAMAGE := 1.0
const MAX_COMBAT_SECONDS := 120.0


func resolve_attack(attacker: Dictionary, defender: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var crit_rate: float = clamp(_num(attacker.get("crit_rate", 0.0)), 0.0, 1.0)
	var crit: bool = crit_rate >= 1.0
	if rng != null and crit_rate < 1.0:
		crit = rng.randf() < crit_rate
	var crit_mult: float = _num(attacker.get("crit_dmg", 1.0)) if crit else 1.0
	var raw: float = (_num(attacker.get("atk", 0.0)) - _num(defender.get("def", 0.0)) * 0.5) * crit_mult
	return {"damage": max(MIN_DAMAGE, raw), "crit": crit}


func simulate_encounter(attacker: Dictionary, defender: Dictionary, seed: Variant, options: Dictionary = {}) -> Dictionary:
	for field in ["hp_max", "atk", "def", "spd", "crit_rate", "crit_dmg"]:
		if not attacker.has(field) or not defender.has(field):
			return {"status": "invalid", "victory": false, "missing": field}
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(str(seed).hash())
	var player_hp := _num(attacker["hp_max"])
	var enemy_hp := _num(defender["hp_max"])
	var max_seconds := float(options.get("max_seconds", MAX_COMBAT_SECONDS))
	var rounds := 0
	var elapsed := 0.0
	while player_hp > 0.0 and enemy_hp > 0.0 and elapsed < max_seconds:
		var player_hit := resolve_attack(attacker, defender, rng)
		enemy_hp -= float(player_hit["damage"])
		if enemy_hp <= 0.0:
			break
		var enemy_hit := resolve_attack(defender, attacker, rng)
		player_hp -= float(enemy_hit["damage"])
		rounds += 1
		elapsed += max(0.1, 2.0 / sqrt(max(_num(attacker.get("spd", 10.0)), 1.0) / 10.0))
	if elapsed >= max_seconds and enemy_hp > 0.0 and player_hp > 0.0:
		return {"status": "timeout", "victory": false, "rounds": rounds, "duration": elapsed}
	var victory := enemy_hp <= 0.0 and player_hp > 0.0
	return {"status": "victory" if victory else "failure", "victory": victory, "rounds": rounds, "duration": elapsed, "player_hp": player_hp, "enemy_hp": enemy_hp}


func _num(value: Variant) -> float:
	if value is BigNumber:
		return value.to_float()
	return float(value)
