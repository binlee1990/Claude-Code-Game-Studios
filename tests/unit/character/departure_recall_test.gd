extends Gut

const CharacterRosterScript = preload("res://src/core/character/character_roster.gd")

var _roster

func before_each() -> void:
	_roster = CharacterRosterScript.new()
	_roster.name = "Roster"
	add_child(_roster)
	for unit_id in [&"alpha", &"beta", &"gamma", &"delta", &"epsilon", &"zeta"]:
		var unit := Unit.new()
		unit.unit_id = unit_id
		unit.display_name = String(unit_id)
		_roster.add_character(unit)

func after_each() -> void:
	if is_instance_valid(_roster):
		_roster.queue_free()

func test_story_departure_marks_character_departed() -> void:
	assert_true(_roster.mark_story_departed(&"epsilon", "chapter_3_exit"))
	assert_eq(_roster.get_status(&"epsilon"), CharacterRosterScript.Status.DEPARTED)
	assert_false(_roster.get_deployable_ids().has(&"epsilon"))

func test_story_departure_blocked_for_deployed_unit_mid_battle() -> void:
	assert_true(_roster.set_party([&"alpha", &"beta", &"gamma", &"delta"]))
	_roster.set_battle_active(true)
	assert_false(_roster.mark_story_departed(&"alpha", "blocked"))
	assert_eq(_roster.get_status(&"alpha"), CharacterRosterScript.Status.DEPLOYED)

func test_defeat_departure_auto_recovers_after_battle() -> void:
	assert_true(_roster.set_party([&"alpha", &"beta", &"gamma", &"delta"]))
	assert_true(_roster.mark_defeated(&"beta"))
	assert_eq(_roster.get_status(&"beta"), CharacterRosterScript.Status.DEFEATED)
	_roster.resolve_battle_end()
	assert_eq(_roster.get_status(&"beta"), CharacterRosterScript.Status.DEPLOYED)

func test_recall_preserves_equipment_skills_and_progression() -> void:
	var unit: Unit = _roster.get_character(&"zeta")
	unit.class_component.add_class_exp(220)
	unit.learn_skill(&"defend")
	unit.equipment_component.add_item(EquipmentItem.new({
		"item_id": "zeta_blade",
		"slot": EquipmentDefinitions.Slot.WEAPON,
		"quality": EquipmentDefinitions.Quality.BLUE,
	}))
	assert_true(_roster.mark_story_departed(&"zeta", "chapter_5_exit"))
	assert_true(_roster.recall_character(&"zeta", "quest_recall_zeta"))
	assert_eq(_roster.get_status(&"zeta"), CharacterRosterScript.Status.AVAILABLE)
	assert_eq(unit.class_component.get_current_class_exp(), 220)
	assert_true(unit.get_skill(&"defend") != null)
	assert_true(unit.equipment_component.get_item(&"zeta_blade") != null)
