extends Gut

const ActionPoints := preload("res://src/core/base/action_points.gd")

func test_action_points_spend_and_round_trip() -> void:
	var ap := ActionPoints.new()
	ap.reset_for_chapter(2)

	assert_true(ap.spend(1))
	assert_eq(ap.current_points, 4)

	var loaded := ActionPoints.new(ap.serialize())
	assert_eq(loaded.chapter_id, 2)
	assert_eq(loaded.current_points, 4)
	assert_eq(loaded.max_points, 5)

func test_action_points_reset_when_chapter_changes() -> void:
	var ap := ActionPoints.new({"chapter_id": 1, "current_points": 0, "max_points": 5})
	ap.ensure_chapter(2)

	assert_eq(ap.chapter_id, 2)
	assert_eq(ap.current_points, 5)

func test_action_points_refuse_training_when_empty() -> void:
	var ap := ActionPoints.new({"chapter_id": 1, "current_points": 0, "max_points": 5})

	assert_false(ap.can_spend(1))
	assert_false(ap.spend(1))
	assert_eq(ap.current_points, 0)
