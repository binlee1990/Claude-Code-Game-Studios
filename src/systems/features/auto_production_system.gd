class_name AutoProductionSystem
extends RefCounted

const MAX_ONLINE_DELTA_SECONDS := 10.0

var time_manager: TimeManager
var output_system: OutputMultiplierSystem
var resource_system: ResourceSystem
var passive_resource_ids := ["lingqi", "xiuwei", "lingshi", "herb"]
var tick_interval_seconds := 1.0
var enabled := true
var last_tick_game_time := 0.0


func _init(time: TimeManager = null, output: OutputMultiplierSystem = null, resources: ResourceSystem = null) -> void:
	time_manager = time
	output_system = output
	resource_system = resources
	if time_manager != null:
		last_tick_game_time = time_manager.get_game_time()


func tick() -> Dictionary:
	if not enabled or time_manager == null or output_system == null or resource_system == null:
		return {}
	if bool(time_manager.collect_save_data().get("frozen", false)):
		last_tick_game_time = time_manager.get_game_time()
		return {}
	var delta := time_manager.get_game_delta_since(last_tick_game_time)
	if delta < tick_interval_seconds:
		return {}
	if delta > MAX_ONLINE_DELTA_SECONDS:
		push_warning("AutoProductionSystem: online delta clamped")
		delta = MAX_ONLINE_DELTA_SECONDS
	last_tick_game_time = time_manager.get_game_time()
	var batch := {}
	for resource_id in passive_resource_ids:
		if str(resource_id) == "exp":
			continue
		var amount := output_system.get_tick_amount(str(resource_id), delta)
		if amount == null or amount.is_zero():
			continue
		batch[resource_id] = amount
	if not batch.is_empty():
		resource_system.batch_add(batch)
	return batch


func set_enabled(value: bool) -> void:
	enabled = value
	if time_manager != null:
		last_tick_game_time = time_manager.get_game_time()
