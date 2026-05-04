class_name OfflineCombatSimulationSystemHost
extends Node

static var instance: OfflineCombatSimulationSystemHost

var service := OfflineCombatSimulationSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var zone_host := ZoneSystemHost.get_instance()
	var loot_host := LootSystemHost.get_instance()
	service = OfflineCombatSimulationSystem.new(zone_host.get_service() if zone_host != null else null, loot_host.get_service() if loot_host != null else null)


static func get_instance() -> OfflineCombatSimulationSystemHost:
	return instance


func get_service() -> OfflineCombatSimulationSystem:
	return service
