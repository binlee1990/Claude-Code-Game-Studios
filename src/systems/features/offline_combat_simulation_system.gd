class_name OfflineCombatSimulationSystem
extends RefCounted

var zone_system: ZoneSystem
var loot_system: LootSystem
var average_cycle_seconds := 10.0
var cpu_budget_encounters := 1000000


func _init(zones: ZoneSystem = null, loot: LootSystem = null) -> void:
	zone_system = zones
	loot_system = loot


func simulate(delta_seconds: float, seed: Variant = "offline_combat") -> Dictionary:
	if zone_system == null or zone_system.current_zone_id.is_empty():
		return {"encounter_count": 0, "rewards": [], "warnings": ["no_active_zone"]}
	var count := int(floor(delta_seconds / average_cycle_seconds))
	var mode := "deterministic"
	var degradations := []
	var simulated_count := count
	if count > cpu_budget_encounters:
		mode = "expected"
		degradations.append("cpu_budget_exceeded")
		simulated_count = cpu_budget_encounters
	var rewards := []
	for i in range(simulated_count):
		if loot_system != null:
			var bundle := loot_system.roll_drops({"loot_table_id": "starter_enemy", "enemy_id": "offline", "zone_id": zone_system.current_zone_id, "seed_context": "%s:%d" % [str(seed), i]})
			rewards.append_array(bundle.get("rewards", []))
	return {"encounter_count": count, "rewards": rewards, "mode": mode, "degradations": degradations}
