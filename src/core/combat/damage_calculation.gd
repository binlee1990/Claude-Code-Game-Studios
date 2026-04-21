class_name DamageCalculation

static func calculate_damage(attacker: Dictionary, defender: Dictionary, skill: Dictionary) -> int:
	var attack: float = attacker.get("attack", 10.0)
	var defense: float = defender.get("defense", 5.0)
	var skill_multiplier: float = skill.get("damage_multiplier", 1.0)
	var attribute_bonus: float = 1.0 + (attacker.get("strength", 0) * 0.01)

	var damage: int = int(attack * (1.0 - defense / 100.0) * skill_multiplier * attribute_bonus)
	return maxi(1, damage)
