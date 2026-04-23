extends Gut

const CharacterRosterScript = preload("res://src/core/character/character_roster.gd")

var _roster

func before_each() -> void:
	_roster = CharacterRosterScript.new()
	_roster.name = "Roster"
	add_child(_roster)
	for unit_id in [&"a", &"b", &"c", &"d", &"e", &"f"]:
		var unit := Unit.new()
		unit.unit_id = unit_id
		unit.display_name = String(unit_id)
		_roster.add_character(unit)

func after_each() -> void:
	if is_instance_valid(_roster):
		_roster.queue_free()

func _build_state() -> void:
	var unit_e: Unit = _roster.get_character(&"e")
	unit_e.learn_skill(&"defend")
	unit_e.equipment_component.add_item(EquipmentItem.new({
		"item_id": "e_ring",
		"slot": EquipmentDefinitions.Slot.ACCESSORY,
		"quality": EquipmentDefinitions.Quality.PURPLE,
	}))
	assert_true(_roster.set_party([&"a", &"b", &"c", &"d"]))
	assert_true(_roster.mark_story_departed(&"f", "quest_lock"))

func test_full_roster_round_trip() -> void:
	_build_state()
	var data: Dictionary = _roster.get_data()
	var loaded = CharacterRosterScript.new()
	add_child(loaded)
	loaded.load_data(data)

	assert_eq(loaded.get_data()["characters"].size(), 6)
	assert_eq(loaded.get_status(&"a"), CharacterRosterScript.Status.DEPLOYED)
	assert_eq(loaded.get_status(&"f"), CharacterRosterScript.Status.DEPARTED)
	assert_true(loaded.get_character(&"e").get_skill(&"defend") != null)
	assert_true(loaded.get_character(&"e").equipment_component.get_item(&"e_ring") != null)
	loaded.queue_free()

func test_party_order_persists_exactly() -> void:
	_build_state()
	var data: Dictionary = _roster.get_data()
	var loaded = CharacterRosterScript.new()
	add_child(loaded)
	loaded.load_data(data)
	assert_eq(loaded.get_party(), [&"a", &"b", &"c", &"d"])
	loaded.queue_free()

func test_double_round_trip_stable() -> void:
	_build_state()
	var data1: Dictionary = _roster.get_data()
	var loaded1 = CharacterRosterScript.new()
	add_child(loaded1)
	loaded1.load_data(data1)
	var data2: Dictionary = loaded1.get_data()
	var loaded2 = CharacterRosterScript.new()
	add_child(loaded2)
	loaded2.load_data(data2)

	assert_eq(loaded2.get_party(), loaded1.get_party())
	assert_eq(loaded2.get_status(&"f"), loaded1.get_status(&"f"))
	assert_true(loaded2.get_character(&"e").equipment_component.get_item(&"e_ring") != null)
	loaded1.queue_free()
	loaded2.queue_free()
