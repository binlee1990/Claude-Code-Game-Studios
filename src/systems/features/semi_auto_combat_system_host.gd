class_name SemiAutoCombatSystemHost
extends Node

static var instance: SemiAutoCombatSystemHost

var service := SemiAutoCombatSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var zone_host := ZoneSystemHost.get_instance()
	var enemy_host := EnemyDatabaseHost.get_instance()
	var calc_host := CombatCalculatorHost.get_instance()
	var loot_host := LootSystemHost.get_instance()
	service = SemiAutoCombatSystem.new(zone_host.get_service() if zone_host != null else null, enemy_host.get_service() if enemy_host != null else null, calc_host.get_service() if calc_host != null else null, loot_host.get_service() if loot_host != null else null)


static func get_instance() -> SemiAutoCombatSystemHost:
	return instance


func get_service() -> SemiAutoCombatSystem:
	return service
