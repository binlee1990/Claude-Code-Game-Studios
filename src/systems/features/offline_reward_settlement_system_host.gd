class_name OfflineRewardSettlementSystemHost
extends Node

static var instance: OfflineRewardSettlementSystemHost

var service := OfflineRewardSettlementSystem.new()


func _ready() -> void:
	if instance == null:
		instance = self
	var resource_host := ResourceSystemHost.get_instance()
	var storage_host := StorageLimitSystemHost.get_instance()
	service = OfflineRewardSettlementSystem.new(resource_host.get_service() if resource_host != null else null, storage_host.get_service() if storage_host != null else null)


static func get_instance() -> OfflineRewardSettlementSystemHost:
	return instance


func get_service() -> OfflineRewardSettlementSystem:
	return service
