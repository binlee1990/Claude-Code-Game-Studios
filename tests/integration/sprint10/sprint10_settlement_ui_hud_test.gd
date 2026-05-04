extends GdUnitTestSuite

const BigNumberScript := preload("res://src/systems/foundation/big_number.gd")
const ResourceSystemScript := preload("res://src/systems/gameplay/resource_system.gd")
const StorageLimitSystemScript := preload("res://src/systems/features/storage_limit_system.gd")
const OfflineRewardSettlementSystemScript := preload("res://src/systems/features/offline_reward_settlement_system.gd")
const OfflineCombatSimulationSystemScript := preload("res://src/systems/features/offline_combat_simulation_system.gd")
const ZoneSystemScript := preload("res://src/systems/features/zone_system.gd")
const UIManagerScript := preload("res://src/systems/presentation/ui_manager.gd")
const HUDSystemScript := preload("res://src/systems/presentation/hud_system.gd")
const LevelSystemScript := preload("res://src/systems/features/level_system.gd")
const EventBusScript := preload("res://src/systems/foundation/event_bus.gd")

var _offline_events := []


func before_test() -> void:
	_offline_events.clear()
	EventBusScript.instance = EventBusScript.new()
	EventBusScript.instance.clear_all()
	EventBusScript.instance.subscribe("offline.settled", _on_offline_settled)


func after_test() -> void:
	if EventBusScript.instance != null:
		EventBusScript.instance.clear_all()
	EventBusScript.instance = null


func test_offline_combat_degrades_without_resource_writes() -> void:
	var offline := OfflineCombatSimulationSystemScript.new()
	offline.zone_system = _fake_zone("starter_valley")
	offline.cpu_budget_encounters = 10
	var result: Dictionary = offline.simulate(3600.0, "seed")
	assert_int(int(result["encounter_count"])).is_equal(360)
	assert_str(str(result["mode"])).is_equal("expected")
	assert_array(result["degradations"]).contains(["cpu_budget_exceeded"])


func test_offline_settlement_applies_capacity_loss_and_dedupes() -> void:
	var resources := _resources()
	resources.add("herb", BigNumberScript.from_int(380))
	var storage := StorageLimitSystemScript.new(resources)
	storage.initialize()
	var settlement := OfflineRewardSettlementSystemScript.new(resources, storage)
	var summary: Dictionary = settlement.settle({
		"id": "draft_001",
		"rewards": [
			{"resource_id": "lingqi", "amount": 100},
			{"resource_id": "herb", "amount": 500},
		],
		"failures": [{"id": "combat"}],
	})
	assert_bool(summary["ok"]).is_true()
	assert_int(resources.get_value("lingqi").to_int()).is_equal(100)
	assert_int(resources.get_value("herb").to_int()).is_equal(500)
	assert_int(BigNumberScript.from_dict(summary["lost"]["herb"]).to_int()).is_equal(380)
	assert_bool(str(summary["warnings"][0]).contains("simulator_failed")).is_true()
	assert_int(_offline_events.size()).is_equal(1)
	assert_bool(settlement.settle({"id": "draft_001", "rewards": []})["ok"]).is_false()


func test_ui_manager_and_hud_view_model_contracts() -> void:
	var ui := UIManagerScript.new()
	ui.register_screen("hud", "res://src/ui/hud/hud.tscn", true)
	assert_bool(ui.open_screen("hud")["ok"]).is_true()
	ui.register_screen("missing", "missing://screen.tscn", true)
	assert_bool(ui.open_screen("missing")["ok"]).is_false()
	var rows := []
	for i in range(1000):
		rows.append(i)
	assert_bool(ui.render_virtual_list(rows, 320, 32).size() < 1000).is_true()
	ui.open_modal("confirm", false)
	assert_bool(ui.can_execute_background_command()).is_false()
	var resources := _resources()
	var storage := StorageLimitSystemScript.new(resources)
	storage.initialize()
	resources.add("lingqi", BigNumberScript.from_int(900))
	var level := LevelSystemScript.new(resources, null, null)
	level.register_entity("player")
	var hud := HUDSystemScript.new(resources, storage, level, ui)
	hud.handle_resource_changed({"resource_id": "lingqi"})
	assert_str(str(hud.resource_rows["lingqi"]["text"])).is_equal("900")
	assert_str(str(hud.resource_rows["lingqi"]["state"])).is_equal("warning")
	hud.handle_offline_settled({"id": "draft_001"})
	assert_bool(hud.offline_summary_visible).is_true()
	level._entries["player"]["level"] = 4
	hud.handle_level_changed({"entity_id": "player"})
	assert_bool(hud.level_badge.contains("Lv.4")).is_true()
	for i in range(50):
		hud.handle_resource_changed({"resource_id": "lingqi"})
	hud.flush_refresh()
	assert_int(hud.layout_refresh_count).is_equal(1)
	assert_int(ui.layout_rebuild_count).is_equal(1)


func _resources() -> ResourceSystem:
	var resources := ResourceSystemScript.new()
	resources.register({"id": "lingqi", "category": "regenerative", "has_cap": true, "cap": BigNumberScript.from_int(1000)})
	resources.register({"id": "herb", "category": "material", "has_cap": true, "cap": BigNumberScript.from_int(500)})
	return resources


func _fake_zone(active_id: String) -> ZoneSystem:
	var zone := ZoneSystemScript.new()
	zone.current_zone_id = active_id
	return zone


func _on_offline_settled(payload: Dictionary) -> void:
	_offline_events.append(payload)
