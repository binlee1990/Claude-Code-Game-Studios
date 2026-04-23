class_name CharacterRoster
extends Node

signal party_composition_changed(old_party: Array, new_party: Array)
signal character_departed(unit_id: StringName, departure_type: String, reason: String)
signal character_recalled(unit_id: StringName)

const MAX_DEPLOYED: int = 4
const MAX_ROSTER_SIZE: int = 6

enum Status {
	AVAILABLE,
	DEPLOYED,
	DEPARTED,
	DEFEATED,
}

var _units: Dictionary = {}
var _status_by_unit: Dictionary = {}
var _departure_meta: Dictionary = {}
var _party: Array = []
var _battle_active: bool = false

func add_character(unit: Unit, status: int = Status.AVAILABLE, register_party: bool = true) -> bool:
	if unit == null or unit.unit_id == &"":
		return false
	if not _units.has(unit.unit_id) and _units.size() >= MAX_ROSTER_SIZE:
		return false
	if unit.get_parent() == null:
		add_child(unit)
	_units[unit.unit_id] = unit
	_status_by_unit[unit.unit_id] = status
	if register_party and status == Status.DEPLOYED and not _party.has(unit.unit_id):
		_party.append(unit.unit_id)
	return true

func get_character(unit_id: StringName) -> Unit:
	return _units.get(unit_id)

func get_status(unit_id: StringName) -> int:
	return _status_by_unit.get(unit_id, Status.AVAILABLE)

func get_party() -> Array:
	return _party.duplicate()

func get_roster_size() -> int:
	return _units.size()

func get_reserve_ids() -> Array:
	var out: Array = []
	for unit_id in _units:
		if get_status(unit_id) == Status.AVAILABLE:
			out.append(unit_id)
	return out

func get_deployable_ids() -> Array:
	var out: Array = []
	for unit_id in _units:
		if [Status.AVAILABLE, Status.DEPLOYED].has(get_status(unit_id)):
			out.append(unit_id)
	return out

func get_departed_ids() -> Array:
	var out: Array = []
	for unit_id in _units:
		if get_status(unit_id) == Status.DEPARTED:
			out.append(unit_id)
	return out

func set_battle_active(active: bool) -> void:
	_battle_active = active

func set_party(unit_ids: Array) -> bool:
	if _battle_active:
		return false
	if unit_ids.size() > MAX_DEPLOYED:
		return false
	var seen: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: StringName = StringName(unit_id_variant)
		if seen.has(unit_id):
			return false
		if not _units.has(unit_id):
			return false
		if not [Status.AVAILABLE, Status.DEPLOYED].has(get_status(unit_id)):
			return false
		seen[unit_id] = true
	var old_party: Array = _party.duplicate()
	for existing_id in _party:
		if get_status(existing_id) == Status.DEPLOYED:
			_status_by_unit[existing_id] = Status.AVAILABLE
	_party.clear()
	for unit_id_variant in unit_ids:
		var unit_id: StringName = StringName(unit_id_variant)
		_party.append(unit_id)
		_status_by_unit[unit_id] = Status.DEPLOYED
	party_composition_changed.emit(old_party, _party.duplicate())
	GameEvents.party_composition_changed.emit(old_party, _party.duplicate())
	return true

func mark_story_departed(unit_id: StringName, reason: String = "") -> bool:
	if not _units.has(unit_id):
		return false
	if _battle_active and _party.has(unit_id):
		return false
	_party.erase(unit_id)
	_status_by_unit[unit_id] = Status.DEPARTED
	_departure_meta[unit_id] = {"departure_type": "story", "departure_reason": reason}
	character_departed.emit(unit_id, "story", reason)
	GameEvents.character_departed.emit(String(unit_id), "story", reason)
	return true

func mark_defeated(unit_id: StringName) -> bool:
	if not _units.has(unit_id):
		return false
	_status_by_unit[unit_id] = Status.DEFEATED
	_departure_meta[unit_id] = {"departure_type": "defeat", "departure_reason": ""}
	return true

func resolve_battle_end() -> void:
	for unit_id in _status_by_unit:
		if _status_by_unit[unit_id] != Status.DEFEATED:
			continue
		_status_by_unit[unit_id] = Status.DEPLOYED if _party.has(unit_id) else Status.AVAILABLE
		_departure_meta.erase(unit_id)

func recall_character(unit_id: StringName, quest_id: String = "") -> bool:
	if get_status(unit_id) != Status.DEPARTED:
		return false
	_status_by_unit[unit_id] = Status.AVAILABLE
	_departure_meta[unit_id] = {"departure_type": "recalled", "departure_reason": quest_id}
	character_recalled.emit(unit_id)
	GameEvents.character_recalled.emit(String(unit_id))
	return true

func get_data() -> Dictionary:
	var characters: Array = []
	for unit_id in _units:
		var party_index: int = _party.find(unit_id)
		var entry: Dictionary = {
			"unit": (_units[unit_id] as Unit).serialize(),
			"status": get_status(unit_id),
			"party_index": party_index,
		}
		if _departure_meta.has(unit_id):
			entry.merge(_departure_meta[unit_id], true)
		characters.append(entry)
	return {
		"characters": characters,
		"party": _party.duplicate(),
		"battle_active": _battle_active,
	}

func load_data(data: Dictionary, existing_units: Dictionary = {}) -> void:
	_clear_roster()
	_battle_active = bool(data.get("battle_active", false))
	var party_ids: Array = []
	var indexed_party: Array = []
	for entry in data.get("characters", []):
		var unit_payload: Dictionary = entry.get("unit", {})
		var payload_id: StringName = StringName(unit_payload.get("unit_id", ""))
		var unit: Unit = existing_units.get(payload_id)
		if unit == null:
			unit = Unit.new()
			add_child(unit)
		unit.deserialize(unit_payload)
		var unit_id: StringName = unit.unit_id
		add_character(unit, int(entry.get("status", Status.AVAILABLE)), false)
		if entry.has("departure_type") or entry.has("departure_reason"):
			_departure_meta[unit_id] = {
				"departure_type": String(entry.get("departure_type", "")),
				"departure_reason": String(entry.get("departure_reason", "")),
			}
		var party_index: int = int(entry.get("party_index", -1))
		if party_index >= 0:
			indexed_party.append({"index": party_index, "unit_id": unit_id})
	if data.has("party"):
		party_ids = data.get("party", [])
	else:
		indexed_party.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["index"]) < int(b["index"])
		)
		for row in indexed_party:
			party_ids.append(row["unit_id"])
	_party.clear()
	for unit_id_variant in party_ids:
		var unit_id: StringName = StringName(unit_id_variant)
		if not _units.has(unit_id):
			continue
		_party.append(unit_id)
		_status_by_unit[unit_id] = Status.DEPLOYED

func _clear_roster() -> void:
	for unit_id in _units:
		var unit: Unit = _units[unit_id]
		if is_instance_valid(unit):
			remove_child(unit)
			unit.queue_free()
	_units.clear()
	_status_by_unit.clear()
	_departure_meta.clear()
	_party.clear()
