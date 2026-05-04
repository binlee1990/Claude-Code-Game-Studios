class_name OfflineSimulationCore
extends RefCounted

var chunk_size_seconds := 1800.0
var save_loaded := true
var _simulators := []


func build_plan(delta_seconds: float) -> Array:
	var chunks := []
	var remaining: float = max(0.0, delta_seconds)
	while remaining > 0.0:
		var size: float = min(chunk_size_seconds, remaining)
		chunks.append({"duration": size})
		remaining -= size
	return chunks


func register_simulator(id: String, priority: int, callback: Callable, critical: bool = false) -> void:
	_simulators.append({"id": id, "priority": priority, "callback": callback, "critical": critical})
	_simulators.sort_custom(func(a, b): return int(a["priority"]) < int(b["priority"]))


func run(delta_seconds: float) -> Dictionary:
	if delta_seconds <= 0.0:
		return {"emitted": false}
	if not save_loaded:
		return {"deferred": true}
	var draft := {"chunks": build_plan(delta_seconds), "outputs": {}, "failures": []}
	for simulator in _simulators:
		var callback: Callable = simulator["callback"]
		if not callback.is_valid():
			draft["failures"].append({"id": simulator["id"], "reason": "invalid_callback"})
			continue
		var output = callback.call(delta_seconds)
		if typeof(output) == TYPE_DICTIONARY and bool(output.get("ok", true)):
			draft["outputs"][simulator["id"]] = output
		else:
			draft["failures"].append({"id": simulator["id"], "reason": "failed"})
	return draft
