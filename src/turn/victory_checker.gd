class_name VictoryChecker extends RefCounted

func determine_winner(units, turn_number: int, turn_cap: int) -> Dictionary:
	assert(turn_number >= 1, "turn_number must be >= 1, got %d" % turn_number)
	assert(turn_cap >= 1, "turn_cap must be >= 1, got %d" % turn_cap)
	var player_alive := _count_alive(units, Faction.Type.PLAYER)
	var enemy_alive := _count_alive(units, Faction.Type.ENEMY)

	if player_alive == 0 or enemy_alive == 0:
		if player_alive == 0 and enemy_alive == 0:
			return {"winner": Faction.Type.PLAYER, "reason": "elimination"}
		if enemy_alive == 0:
			return {"winner": Faction.Type.PLAYER, "reason": "elimination"}
		if player_alive == 0:
			return {"winner": Faction.Type.ENEMY, "reason": "elimination"}

	if turn_number > turn_cap:
		if player_alive > enemy_alive:
			return {"winner": Faction.Type.PLAYER, "reason": "turn_cap"}
		elif enemy_alive > player_alive:
			return {"winner": Faction.Type.ENEMY, "reason": "turn_cap"}
		else:
			return {"winner": Faction.Type.NONE, "reason": "turn_cap"}

	return {"winner": Faction.Type.NONE, "reason": ""}

func _count_alive(units, faction: Faction.Type) -> int:
	var count := 0
	for u in units:
		if is_instance_valid(u) and u.faction == faction and u.is_alive():
			count += 1
	return count
