class_name OfflineRewardSettlementSystem
extends RefCounted

var resource_system: ResourceSystem
var storage_limits: StorageLimitSystem
var settled_drafts := {}


func _init(resources: ResourceSystem = null, storage: StorageLimitSystem = null) -> void:
	resource_system = resources
	storage_limits = storage


func settle(draft: Dictionary) -> Dictionary:
	var draft_id := str(draft.get("id", ""))
	if draft_id.is_empty():
		draft_id = str(draft.hash())
	if settled_drafts.has(draft_id):
		return {"ok": false, "reason": "duplicate_draft", "id": draft_id}
	settled_drafts[draft_id] = true
	var gross := _merge_rewards(draft)
	var claimable := {}
	var lost := {}
	for resource_id in gross.keys():
		var generated: BigNumber = gross[resource_id]
		var remaining := _remaining_capacity(str(resource_id))
		var accepted := BigNumber.min_value(generated, remaining)
		claimable[resource_id] = accepted
		lost[resource_id] = generated.subtract(accepted)
	var actual := resource_system.batch_add(claimable) if resource_system != null else {}
	for resource_id in gross.keys():
		var actual_added: BigNumber = actual.get(resource_id, BigNumber.zero())
		lost[resource_id] = gross[resource_id].subtract(actual_added)
	var warnings: Array = draft.get("warnings", []).duplicate()
	for failure in draft.get("failures", []):
		warnings.append("simulator_failed:%s" % str(failure.get("id", "")))
	var summary := {"ok": true, "id": draft_id, "gross": _serialize_bn_map(gross), "claimed": _serialize_bn_map(actual), "lost": _serialize_bn_map(lost), "warnings": warnings}
	_emit("offline.settled", {"id": draft_id, "claimed": summary["claimed"], "lost": summary["lost"], "warnings": warnings})
	return summary


func _merge_rewards(draft: Dictionary) -> Dictionary:
	var gross := {}
	for reward in draft.get("rewards", []):
		var id := str(reward.get("resource_id", reward.get("item_id", "")))
		var amount := _to_big_number(reward.get("amount", 0))
		gross[id] = gross.get(id, BigNumber.zero()).add(amount)
	for output in draft.get("outputs", {}).values():
		for reward in output.get("rewards", []):
			var id := str(reward.get("resource_id", reward.get("item_id", "")))
			var amount := _to_big_number(reward.get("amount", 0))
			gross[id] = gross.get(id, BigNumber.zero()).add(amount)
	return gross


func _remaining_capacity(resource_id: String) -> BigNumber:
	if storage_limits != null:
		return storage_limits.get_remaining_capacity(resource_id)
	if resource_system == null:
		return BigNumber.zero()
	var max_value := resource_system.get_max(resource_id)
	if max_value.is_max():
		return max_value
	return max_value.subtract(resource_system.get_value(resource_id))


func _to_big_number(value: Variant) -> BigNumber:
	if value is BigNumber:
		return value
	if typeof(value) == TYPE_INT:
		return BigNumber.from_int(value)
	if typeof(value) == TYPE_FLOAT:
		return BigNumber.from_float(value)
	if typeof(value) == TYPE_DICTIONARY:
		return BigNumber.from_dict(value)
	return BigNumber.from_string(str(value))


func _serialize_bn_map(values: Dictionary) -> Dictionary:
	var result := {}
	for id in values.keys():
		var amount: BigNumber = values[id]
		result[id] = amount.to_dict()
	return result


func _emit(event_name: String, payload: Dictionary) -> void:
	var bus := EventBus.get_instance()
	if bus != null:
		bus.emit(event_name, payload)
