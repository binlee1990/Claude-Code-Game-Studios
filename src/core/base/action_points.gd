class_name ActionPoints
extends RefCounted

const DEFAULT_MAX_POINTS: int = 5

var current_points: int = DEFAULT_MAX_POINTS
var max_points: int = DEFAULT_MAX_POINTS
var chapter_id: int = 1

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		reset_for_chapter(1)
	else:
		deserialize(data)

func reset_for_chapter(next_chapter_id: int, next_max_points: int = DEFAULT_MAX_POINTS) -> void:
	chapter_id = maxi(1, next_chapter_id)
	max_points = maxi(1, next_max_points)
	current_points = max_points

func ensure_chapter(next_chapter_id: int) -> void:
	var resolved_chapter := maxi(1, next_chapter_id)
	if resolved_chapter != chapter_id:
		reset_for_chapter(resolved_chapter, max_points)
	else:
		current_points = clampi(current_points, 0, max_points)

func can_spend(amount: int = 1) -> bool:
	return amount <= 0 or current_points >= amount

func spend(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if not can_spend(amount):
		return false
	current_points -= amount
	return true

func serialize() -> Dictionary:
	return {
		"current_points": current_points,
		"max_points": max_points,
		"chapter_id": chapter_id,
	}

func deserialize(data: Dictionary) -> void:
	max_points = maxi(1, int(data.get("max_points", DEFAULT_MAX_POINTS)))
	chapter_id = maxi(1, int(data.get("chapter_id", 1)))
	current_points = clampi(int(data.get("current_points", max_points)), 0, max_points)
