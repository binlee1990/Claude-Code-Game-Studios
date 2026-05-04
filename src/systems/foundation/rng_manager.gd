class_name RNGManager
extends Node

enum CoreStream { COMBAT, LOOT, EVENT, AFFIX }

const CORE_STREAM_KEYS := {
	CoreStream.COMBAT: "combat",
	CoreStream.LOOT: "loot",
	CoreStream.EVENT: "event",
	CoreStream.AFFIX: "affix",
}

static var instance: RNGManager

var _master_seed: int = 0
var _initialized := false
var _streams := {}
var _call_counts := {}


func _ready() -> void:
	if instance == null:
		instance = self
	if not _initialized:
		set_master_seed(int(Time.get_unix_time_from_system()))


## Returns the active autoload instance when one has been registered by the scene tree.
static func get_instance() -> RNGManager:
	return instance


## Sets the master seed and recreates all core streams deterministically.
func set_master_seed(seed: int) -> void:
	_master_seed = abs(seed)
	_initialized = true
	_streams.clear()
	_call_counts.clear()
	for stream_id in CORE_STREAM_KEYS.keys():
		_create_stream(CORE_STREAM_KEYS[stream_id])


## Returns the current master seed.
func get_master_seed() -> int:
	return _master_seed


## Registers an extension stream by name. Repeated registration is idempotent.
func register_stream(stream_name: String) -> bool:
	var key := stream_name.strip_edges()
	if key.is_empty():
		push_error("Stream name cannot be empty")
		return false
	if _streams.has(key):
		return true
	if not _initialized:
		push_warning("RNG stream %s registered before initialization" % key)
	_create_stream(key)
	return true


## Returns a deterministic integer in the inclusive range.
func rand_int(stream_id: Variant, min_val: int, max_val: int) -> int:
	if not _initialized:
		push_warning("RNG stream %s not initialized, returning default" % str(stream_id))
		return min_val
	if min_val == max_val:
		return min_val
	if min_val > max_val:
		push_warning("min_val > max_val in stream %s, values swapped" % str(stream_id))
		var old_min := min_val
		min_val = max_val
		max_val = old_min
	var key := _stream_key(stream_id)
	var rng := _get_rng_by_key(key)
	_count_call(key)
	return rng.randi_range(min_val, max_val)


## Returns a deterministic float in the range [min_val, max_val].
func rand_float(stream_id: Variant, min_val: float = 0.0, max_val: float = 1.0) -> float:
	if not _initialized:
		push_warning("RNG stream %s not initialized, returning default" % str(stream_id))
		return min_val
	if min_val == max_val:
		return min_val
	if min_val > max_val:
		push_warning("min_val > max_val in stream %s, values swapped" % str(stream_id))
		var old_min := min_val
		min_val = max_val
		max_val = old_min
	var key := _stream_key(stream_id)
	var rng := _get_rng_by_key(key)
	_count_call(key)
	return rng.randf_range(min_val, max_val)


## Returns true with the given clamped probability.
func rand_bool(stream_id: Variant, probability: float = 0.5) -> bool:
	if probability <= 0.0:
		return false
	if probability >= 1.0:
		return true
	if not _initialized:
		push_warning("RNG stream %s not initialized, returning default" % str(stream_id))
		return false
	var key := _stream_key(stream_id)
	var rng := _get_rng_by_key(key)
	_count_call(key)
	return rng.randf() < probability


## Picks an index from weighted entries. Invalid or all-zero weights return -1.
func weighted_pick(stream_id: Variant, weights: Array) -> int:
	if weights.is_empty():
		return -1
	if weights.size() == 1:
		return 0 if float(weights[0]) > 0.0 else -1
	var cumulative := []
	var total := 0.0
	for i in range(weights.size()):
		var weight := float(weights[i])
		if weight < 0.0:
			push_warning("Negative weight at index %d in stream %s, clamped to 0.0" % [i, str(stream_id)])
			weight = 0.0
		total += weight
		cumulative.append(total)
	if total <= 0.0:
		return -1
	var target := rand_float(stream_id, 0.0, total)
	for i in range(cumulative.size()):
		if target <= float(cumulative[i]):
			return i
	return cumulative.size() - 1


## Returns a shuffled copy of the provided array.
func shuffle(stream_id: Variant, source: Array) -> Array:
	var result := source.duplicate()
	if result.size() < 2:
		return result
	for i in range(result.size() - 1, 0, -1):
		var j := rand_int(stream_id, 0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


## Picks one item from an array, or null for an empty array.
func pick_random(stream_id: Variant, source: Array) -> Variant:
	if source.is_empty():
		push_warning("pick_random called on empty array in stream %s" % str(stream_id))
		return null
	return source[rand_int(stream_id, 0, source.size() - 1)]


## Serializes the master seed and every stream seed/state.
func save_states() -> Dictionary:
	var stream_data := {}
	for key in _streams.keys():
		var rng: RandomNumberGenerator = _streams[key]
		stream_data[key] = {
			"seed": rng.seed,
			"state": rng.state,
			"calls": _call_counts.get(key, 0),
		}
	return {
		"master_seed": _master_seed,
		"streams": stream_data,
	}


## Restores all stream states from serialized data.
func load_states(data: Dictionary) -> void:
	if not data.has("master_seed"):
		push_warning("RNG state incomplete: missing master_seed, using derived default")
		data["master_seed"] = _master_seed
	set_master_seed(int(data["master_seed"]))
	var stream_data: Dictionary = data.get("streams", {})
	for key in stream_data.keys():
		if not _streams.has(key):
			_create_stream(str(key))
		var rng: RandomNumberGenerator = _streams[key]
		var item: Dictionary = stream_data[key]
		if item.has("seed"):
			rng.seed = int(item["seed"])
		else:
			push_warning("RNG state incomplete: missing seed, using derived default")
		if item.has("state"):
			rng.state = int(item["state"])
		else:
			push_warning("RNG state incomplete: missing state, using derived default")
		_call_counts[key] = int(item.get("calls", 0))


## Returns debug metadata for one stream.
func get_stream_info(stream_id: Variant) -> Dictionary:
	var key := _stream_key(stream_id)
	if not _streams.has(key):
		return {}
	var rng: RandomNumberGenerator = _streams[key]
	return {
		"seed": rng.seed,
		"state": rng.state,
		"calls": _call_counts.get(key, 0),
	}


## Runs a callback against a temporary state copy and restores the online state.
func run_with_state_copy(state_data: Dictionary, callback: Callable) -> Variant:
	var online_state := save_states()
	load_states(state_data)
	var result = callback.call(self)
	load_states(online_state)
	return result


func _get_rng(stream_id: Variant) -> RandomNumberGenerator:
	return _get_rng_by_key(_stream_key(stream_id))


func _get_rng_by_key(key: String) -> RandomNumberGenerator:
	if not _streams.has(key):
		push_warning("RNG stream '%s' not registered, auto-created with derived seed" % key)
		_create_stream(key)
	return _streams[key]


func _create_stream(key: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(key)
	_streams[key] = rng
	_call_counts[key] = 0


func _stream_key(stream_id: Variant) -> String:
	if typeof(stream_id) == TYPE_INT:
		match int(stream_id):
			CoreStream.COMBAT:
				return "combat"
			CoreStream.LOOT:
				return "loot"
			CoreStream.EVENT:
				return "event"
			CoreStream.AFFIX:
				return "affix"
	return str(stream_id).strip_edges().to_lower()


func _derive_seed(key: String) -> int:
	var value := "%s:%s" % [str(_master_seed), key]
	var hash_value := value.hash()
	return abs(hash_value)


func _count_call(key: String) -> void:
	_call_counts[key] = int(_call_counts.get(key, 0)) + 1
