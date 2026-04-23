extends Gut

const CharacterRosterScript = preload("res://src/core/character/character_roster.gd")

var _roster

func before_each() -> void:
	_roster = CharacterRosterScript.new()
	_roster.name = "Roster"
	add_child(_roster)
	for i in range(6):
		_roster.add_character(_make_unit("char_%d" % i))

func after_each() -> void:
	if is_instance_valid(_roster):
		_roster.queue_free()

func _make_unit(unit_id: String) -> Unit:
	var unit := Unit.new()
	unit.unit_id = StringName(unit_id)
	unit.display_name = unit_id
	return unit

func test_party_limit_enforced_at_four() -> void:
	assert_true(_roster.set_party([&"char_0", &"char_1", &"char_2", &"char_3"]))
	assert_eq(_roster.get_party().size(), 4)
	assert_false(_roster.set_party([&"char_0", &"char_1", &"char_2", &"char_3", &"char_4"]))

func test_reserve_characters_keep_progression_data() -> void:
	var reserve: Unit = _roster.get_character(&"char_5")
	reserve.learn_skill(&"defend")
	reserve.equipment_component.add_item(EquipmentItem.new({
		"item_id": "reserve_ring",
		"slot": EquipmentDefinitions.Slot.ACCESSORY,
		"quality": EquipmentDefinitions.Quality.BLUE,
	}))
	assert_true(_roster.set_party([&"char_0", &"char_1", &"char_2", &"char_3"]))
	assert_eq(_roster.get_status(&"char_5"), CharacterRosterScript.Status.AVAILABLE)
	assert_true(reserve.get_skill(&"defend") != null)
	assert_true(reserve.equipment_component.get_item(&"reserve_ring") != null)

func test_party_adjustment_blocked_during_battle_only() -> void:
	assert_true(_roster.set_party([&"char_0", &"char_1", &"char_2", &"char_3"]))
	assert_true(_roster.set_party([&"char_0", &"char_4", &"char_2", &"char_3"]))
	assert_eq(_roster.get_party()[1], &"char_4")
	_roster.set_battle_active(true)
	assert_false(_roster.set_party([&"char_0", &"char_1"]))
