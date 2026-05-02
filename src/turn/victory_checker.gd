class_name VictoryChecker extends RefCounted

func determine_winner(units, turn_number: int, turn_cap: int) -> Dictionary:
	assert(are_turn_bounds_valid(turn_number, turn_cap), "turn_number and turn_cap must be >= 1, got turn_number=%d turn_cap=%d" % [turn_number, turn_cap])
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

func are_turn_bounds_valid(turn_number: int, turn_cap: int) -> bool:
	return turn_number >= 1 and turn_cap >= 1

func _count_alive(units, faction: Faction.Type) -> int:
	var count := 0
	for u in units:
		if is_instance_valid(u) and u.faction == faction and u.is_alive():
			count += 1
	return count
