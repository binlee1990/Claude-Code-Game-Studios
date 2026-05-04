extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const DataConfigScript := preload("res://src/systems/core/data_config.gd")
const ItemRegistryScript := preload("res://src/systems/gameplay/item_registry.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const TimeManagerScript := preload("res://src/systems/foundation/time_manager.gd")
const ModifierEngineScript := preload("res://src/systems/core/modifier_engine.gd")
const OutputMultiplierSystemScript := preload("res://src/systems/gameplay/output_multiplier_system.gd")
const AutoProductionSystemScript := preload("res://src/systems/features/auto_production_system.gd")
const EnemyDatabaseScript := preload("res://src/systems/features/enemy_database.gd")
const LootSystemScript := preload("res://src/systems/features/loot_system.gd")
const CultivationSystemScript := preload("res://src/systems/features/cultivation_system.gd")
const CombatCalculatorScript := preload("res://src/systems/features/combat_calculator.gd")
const LevelSystemScript := preload("res://src/systems/features/level_system.gd")
const ZoneSystemScript := preload("res://src/systems/features/zone_system.gd")
const MapProgressionSystemScript := preload("res://src/systems/features/map_progression_system.gd")
const SemiAutoCombatSystemScript := preload("res://src/systems/features/semi_auto_combat_system.gd")
const OfflineSimulationCoreScript := preload("res://src/systems/features/offline_simulation_core.gd")
const IdleExplorationSystemScript := preload("res://src/systems/features/idle_exploration_system.gd")
const OfflineCombatSimulationSystemScript := preload("res://src/systems/features/offline_combat_simulation_system.gd")


func test_enemy_database_zone_and_loot_contracts() -> void:
	var deps: Dictionary = _deps()
	var enemies: EnemyDatabase = deps["enemies"]
	assert_int(enemies.get_count()).is_equal(3)
	var snapshot: Dictionary = enemies.create_combat_snapshot("training_dummy")
	for attr_id in EnemyDatabaseScript.REQUIRED_ATTRS:
		assert_bool(snapshot.has(attr_id)).is_true()
	var starter: Array = enemies.get_by_zone_tag("starter")
	assert_int(starter.size()).is_equal(2)
	for enemy in starter:
		assert_bool(enemy["zone_tags"].has("starter")).is_true()
	var first: Dictionary = deps["loot"].roll_drops({"loot_table_id": "starter_enemy", "enemy_id": "training_dummy", "zone_id": "starter_valley", "seed_context": "fixed"})
	var second: Dictionary = deps["loot"].roll_drops({"loot_table_id": "starter_enemy", "enemy_id": "training_dummy", "zone_id": "starter_valley", "seed_context": "fixed"})
	assert_str(JSON.stringify(first)).is_equal(JSON.stringify(second))
	assert_bool(_bundle_has(first, "exp")).is_true()


func test_cultivation_combat_zone_and_progression_contracts() -> void:
	var deps: Dictionary = _deps()
	var resources: ResourceSystem = deps["resources"]
	var cultivation: CultivationSystem = deps["cultivation"]
	assert_bool(cultivation.manual_cultivate()).is_true()
	assert_int(resources.get_value("lingqi").to_int()).is_equal(1)
	cultivation.set_stance(CultivationSystemScript.STANCE_CONDENSE)
	assert_bool(cultivation.tick_condense()).is_true()
	assert_int(resources.get_value("xiuwei").to_int()).is_equal(1)
	var calc: CombatCalculator = deps["calculator"]
	var player: Dictionary = {"hp_max": 1000.0, "atk": 100.0, "def": 20.0, "spd": 10.0, "crit_rate": 1.0, "crit_dmg": 2.0}
	var enemy: Dictionary = deps["enemies"].create_combat_snapshot("training_dummy")
	var a: Dictionary = calc.simulate_encounter(player, enemy, "same")
	var b: Dictionary = calc.simulate_encounter(player, enemy, "same")
	assert_str(JSON.stringify(a)).is_equal(JSON.stringify(b))
	assert_bool(calc.resolve_attack({"atk": 1.0, "crit_rate": 1.0, "crit_dmg": 2.0}, {"def": 999.0})["damage"] >= 1.0).is_true()
	var zones: ZoneSystem = deps["zones"]
	assert_int(zones.get_sorted_zones().size()).is_equal(3)
	assert_bool(zones.select_zone("starter_valley")["ok"]).is_true()
	assert_bool(zones.select_zone("pine_forest")["ok"]).is_false()
	deps["map"].cleared["starter_valley"] = true
	deps["level"].register_entity("player")
	deps["level"]._entries["player"]["level"] = 4
	assert_array(deps["map"].evaluate_unlocks("player")).contains(["pine_forest"])
	assert_bool(deps["map"].select_zone("pine_forest")["ok"]).is_true()


func test_auto_offline_idle_and_semi_auto_contracts() -> void:
	var deps: Dictionary = _deps()
	var time: TimeManager = deps["time"]
	var resources: ResourceSystem = deps["resources"]
	var auto: AutoProductionSystem = deps["auto"]
	auto.passive_resource_ids.append("exp")
	auto.passive_resource_ids.append("invalid")
	time.set_test_real_time(1.0)
	auto.tick()
	assert_int(resources.get_value("lingqi").to_int()).is_equal(1)
	assert_bool(resources.get_value("exp").is_zero()).is_true()
	var core: OfflineSimulationCore = OfflineSimulationCoreScript.new()
	assert_int(core.build_plan(7200.0).size()).is_equal(4)
	core.save_loaded = false
	assert_bool(core.run(3600.0).get("deferred", false)).is_true()
	assert_bool(core.run(0.0).get("emitted", true)).is_false()
	var idle: IdleExplorationSystem = IdleExplorationSystemScript.new(deps["zones"])
	idle.initialize()
	assert_str(idle.get_recommended_target()).is_equal("starter_valley")
	idle.apply_offline_summary({"capacity_factor": 0.1, "encounters": 10})
	assert_str(str(idle.last_session_summary["recommendation"])).is_equal("capacity_pressure")
	var offline: OfflineCombatSimulationSystem = OfflineCombatSimulationSystemScript.new(deps["zones"], deps["loot"])
	assert_int(offline.simulate(3600.0, "seed")["encounter_count"]).is_equal(360)
	var semi: SemiAutoCombatSystem = deps["semi"]
	var result: Dictionary = semi.resolve_encounter({"hp_max": 1000.0, "atk": 100.0, "def": 20.0, "spd": 10.0, "crit_rate": 0.0, "crit_dmg": 1.5}, "online")
	assert_bool(result["result"].has("victory")).is_true()


func _deps() -> Dictionary:
	var data := DataConfigScript.new()
	data.load_table_data("items", {
		"exp": {"name": "经验", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
		"lingshi": {"name": "灵石", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
		"herb": {"name": "药材", "item_class": "resource_material", "rarity": "fanpin", "tags": []},
	})
	data.load_table_data("enemies", {
		"training_dummy": {"name": "练功木偶", "level": 1, "base_attributes": {"hp_max": "80", "atk": "8", "def": "2", "spd": "8", "crit_rate": "0", "crit_dmg": "1.5"}, "loot_table_id": "starter_enemy", "zone_tags": ["starter"], "weight": 5},
		"wild_wolf": {"name": "野狼", "level": 3, "base_attributes": {"hp_max": "140", "atk": "16", "def": "4", "spd": "14", "crit_rate": "0.05", "crit_dmg": "1.5"}, "loot_table_id": "starter_enemy", "zone_tags": ["starter", "forest"], "weight": 3},
		"mountain_bandit": {"name": "山贼", "level": 6, "base_attributes": {"hp_max": "260", "atk": "28", "def": "10", "spd": "10", "crit_rate": "0.08", "crit_dmg": "1.6"}, "loot_table_id": "bandit_enemy", "zone_tags": ["forest"], "weight": 2},
	})
	data.load_table_data("loot_tables", {
		"starter_enemy": {"max_drops": 5, "entries": [{"item_id": "exp", "chance": 1.0, "min_qty": 8, "max_qty": 8}, {"item_id": "herb", "chance": 1.0, "min_qty": 1, "max_qty": 1}]},
		"bandit_enemy": {"max_drops": 5, "entries": [{"item_id": "exp", "chance": 1.0, "min_qty": 20, "max_qty": 20}]},
	})
	data.load_table_data("zones", {
		"starter_valley": {"name": "新手谷", "order": 1, "unlocked": true, "enemy_pool": [{"enemy_id": "training_dummy", "weight": 5}], "unlock": {"required_level": 1, "prerequisite": ""}},
		"pine_forest": {"name": "松林", "order": 2, "unlocked": false, "enemy_pool": [{"enemy_id": "wild_wolf", "weight": 4}], "unlock": {"required_level": 4, "prerequisite": "starter_valley"}},
		"mist_peak": {"name": "雾峰", "order": 3, "unlocked": false, "enemy_pool": [{"enemy_id": "mountain_bandit", "weight": 1}], "unlock": {"required_level": 8, "prerequisite": "pine_forest"}},
	})
	data.load_table_data("production_config", {
		"lingqi": {"base_rate_per_second": "1.0", "allows_passive": true, "passive_sources": []},
		"xiuwei": {"base_rate_per_second": "0", "allows_passive": true, "passive_sources": []},
		"lingshi": {"base_rate_per_second": "0", "allows_passive": true, "passive_sources": []},
		"herb": {"base_rate_per_second": "0", "allows_passive": true, "passive_sources": []},
		"exp": {"base_rate_per_second": "0", "allows_passive": false, "passive_sources": []},
	})
	var registry := ItemRegistryScript.new(data)
	registry._initialize()
	var enemies := EnemyDatabaseScript.new(data)
	enemies.load_all()
	var loot := LootSystemScript.new(data, registry)
	var zones := ZoneSystemScript.new(data, enemies)
	zones.load_all()
	var resources := ResourceSystemScript.new()
	for id in ["lingqi", "xiuwei", "lingshi", "herb", "exp"]:
		resources.register({"id": id, "category": "progress", "has_cap": false})
	var time := TimeManagerScript.new()
	time.reset_for_test(0.0)
	var output := OutputMultiplierSystemScript.new(ModifierEngineScript.new(), data)
	output.load_config()
	var auto := AutoProductionSystemScript.new(time, output, resources)
	var cultivation := CultivationSystemScript.new(resources, time)
	var calculator := CombatCalculatorScript.new()
	var level := LevelSystemScript.new(resources, null, output)
	var map := MapProgressionSystemScript.new(zones, level)
	var semi := SemiAutoCombatSystemScript.new(zones, enemies, calculator, loot)
	return {"data": data, "registry": registry, "enemies": enemies, "loot": loot, "zones": zones, "resources": resources, "time": time, "output": output, "auto": auto, "cultivation": cultivation, "calculator": calculator, "level": level, "map": map, "semi": semi}


func _bundle_has(bundle: Dictionary, item_id: String) -> bool:
	for reward in bundle.get("rewards", []):
		if str(reward.get("item_id", "")) == item_id:
			return true
	return false
