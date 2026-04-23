class_name BattleHistoryLog
extends RefCounted

## Append-only log of completed battles for achievement tracking and stats review.
## Story BS-005 AC-S2.
## Records are immutable once appended. Serializable for save/load integration.
##
## Example:
##   var log := BattleHistoryLog.new()
##   log.append_battle({"battle_id": "map_01", "result_type": SettlementResult.SettlementType.VICTORY, ...})
##   var data: Dictionary = log.serialize()
##   var log2 := BattleHistoryLog.new()
##   log2.deserialize(data)

const VERSION: int = 1

var _records: Array = []

## Append a completed battle record.
## [param record] Dictionary with keys:
##   "battle_id": String
##   "result_type": int (SettlementResult.SettlementType)
##   "rating": int (BattleEvaluation.Rating)
##   "rewards_enabled": bool
##   "exp_awarded": int (optional, 0 default)
##   "gold_awarded": int (optional, 0 default)
##   "materials_awarded": int (optional, 0 default)
##   "equipment_count": int (optional, 0 default)
##   "timestamp": int (optional, 0 default — Unix seconds)
## Missing optional keys default to 0.
func append_battle(record: Dictionary) -> void:
	var normalized: Dictionary = {
		"battle_id":         record.get("battle_id", ""),
		"result_type":       record.get("result_type", 0),
		"rating":            record.get("rating", 0),
		"rewards_enabled":   record.get("rewards_enabled", false),
		"exp_awarded":       record.get("exp_awarded", 0),
		"gold_awarded":      record.get("gold_awarded", 0),
		"materials_awarded": record.get("materials_awarded", 0),
		"equipment_count":   record.get("equipment_count", 0),
		"timestamp":         record.get("timestamp", 0),
	}
	_records.append(normalized)

## Get all battle records as an Array of Dictionaries (defensive copy).
func get_records() -> Array:
	var out: Array = []
	for r in _records:
		out.append(r.duplicate())
	return out

## Count total records.
func count() -> int:
	return _records.size()

## Count records matching a specific SettlementType.
func count_by_result(result_type: int) -> int:
	var c: int = 0
	for r in _records:
		if r["result_type"] == result_type:
			c += 1
	return c

## Clear all records (used for new-game / new-save-slot init only).
func clear() -> void:
	_records.clear()

## Serialize the log to a Dictionary for the save system.
## Returns: { "version": int, "records": Array[Dictionary] }
##
## Example:
##   var data: Dictionary = log.serialize()
##   log2.deserialize(data)
func serialize() -> Dictionary:
	var records_copy: Array = []
	for r in _records:
		records_copy.append(r.duplicate())
	return {
		"version": VERSION,
		"records": records_copy,
	}

## Restore from serialized data. Overwrites any existing records.
## Unknown or missing versions result in an empty log.
##
## Example:
##   log.deserialize({"version": 1, "records": [...]})
func deserialize(data: Dictionary) -> void:
	_records.clear()
	var version: int = data.get("version", 0)
	if version != VERSION:
		return  # Unsupported version — start with empty log
	var records: Array = data.get("records", [])
	for r in records:
		if typeof(r) == TYPE_DICTIONARY:
			_records.append(r.duplicate())
