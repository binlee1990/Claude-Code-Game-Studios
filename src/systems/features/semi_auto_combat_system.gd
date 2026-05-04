class_name SemiAutoCombatSystem
extends RefCounted

var zone_system: ZoneSystem
var enemy_database: EnemyDatabase
var calculator: CombatCalculator
var loot_system: LootSystem
var failure_count := 0
var recommendation_state := {}


func _init(zones: ZoneSystem = null, enemies: EnemyDatabase = null, calc: CombatCalculator = null, loot: LootSystem = null) -> void:
	zone_system = zones
	enemy_database = enemies
	calculator = calc if calc != null else CombatCalculator.new()
	loot_system = loot


func resolve_encounter(player_snapshot: Dictionary, seed: Variant = "combat") -> Dictionary:
	var pool := zone_system.get_enemy_pool() if zone_system != null else []
	if pool.is_empty():
		recommendation_state = {"state": "blocked", "reason": "empty_enemy_pool"}
		return {"ok": false, "reason": "empty_enemy_pool"}
	var enemy_id := str(pool[0]["enemy_id"])
	var enemy_snapshot := enemy_database.create_combat_snapshot(enemy_id, "online") if enemy_database != null else {}
	var result := calculator.simulate_encounter(player_snapshot, enemy_snapshot, seed)
	var bundle := {"rewards": []}
	if bool(result.get("victory", false)) and loot_system != null:
		bundle = loot_system.roll_drops({"enemy_id": enemy_id, "zone_id": zone_system.current_zone_id, "loot_table_id": enemy_database.get_enemy(enemy_id).get("loot_table_id", ""), "seed_context": str(seed)})
		failure_count = 0
	else:
		failure_count += 1
		if failure_count >= 5:
			recommendation_state = {"state": "blocked", "reason": "too_many_failures"}
	_emit("combat.finished", {"victory": bool(result.get("victory", false)), "zone_id": zone_system.current_zone_id if zone_system != null else "", "enemy_id": enemy_id, "loot": bundle})
	return {"result": result, "loot": bundle}


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
