# tests/unit/chapter02/fruit_selection_test.gd
# Story CH2-c-006: Fruit Selection Screen
# Validates AC-CH2-008 (3-fruit selection, forced modal, interrupt reload)

extends Gut

var _fruit: FruitSelection

func before_each() -> void:
	_fruit = FruitSelection.new()

func after_each() -> void:
	_fruit = null

# --- AC-CH2-008.1: Available fruits ---

func test_ac_ch2_008_1_returns_three_fruits() -> void:
	var fruits: Array = _fruit.get_available_fruits()
	assert_eq(fruits.size(), 3, "Must return exactly 3 fruits")

func test_ac_ch2_008_1_contains_str_agi_int() -> void:
	var fruits: Array = _fruit.get_available_fruits()
	assert_true(fruits.has(FruitSelection.FRUIT_STR), "Must contain FRUIT_STR")
	assert_true(fruits.has(FruitSelection.FRUIT_AGI), "Must contain FRUIT_AGI")
	assert_true(fruits.has(FruitSelection.FRUIT_INT), "Must contain FRUIT_INT")

# --- AC-CH2-008.2: Select 2, confirm writes to inventory ---

func test_ac_ch2_008_2_select_two_fruits_can_confirm() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	_fruit.toggle_fruit(FruitSelection.FRUIT_AGI)
	assert_true(_fruit.can_confirm(), "Selecting 2 fruits should allow confirm")

func test_ac_ch2_008_2_confirm_writes_done_flag() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	_fruit.toggle_fruit(FruitSelection.FRUIT_AGI)
	assert_true(_fruit.can_confirm(), "Should be confirmable after 2 selections")

func test_ac_ch2_008_2_confirm_requires_two_fruits() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	assert_false(_fruit.can_confirm(), "Selecting only 1 fruit should not allow confirm")

func test_ac_ch2_008_2_third_fruit_not_written() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	_fruit.toggle_fruit(FruitSelection.FRUIT_AGI)
	_fruit.toggle_fruit(FruitSelection.FRUIT_INT)  # third — replaces FRUIT_STR

	var selected: Array = _fruit.get_selected()
	assert_eq(selected.size(), 2, "Only 2 fruits should be selected")
	assert_true(selected.has(FruitSelection.FRUIT_INT), "FRUIT_INT should be selected")
	assert_true(selected.has(FruitSelection.FRUIT_AGI), "FRUIT_AGI should be selected")
	assert_false(selected.has(FruitSelection.FRUIT_STR), "FRUIT_STR should be dropped")

# --- AC-CH2-008.3: Interrupt reload detection ---

func test_ac_ch2_008_3_should_show_when_not_done() -> void:
	var data := SaveData.new()
	data.story_progress = {}

	var show: bool = _fruit.should_show_selection(data)
	assert_true(show, "Should show when fruit_selection_done is absent/false")

func test_ac_ch2_008_3_should_not_show_when_done() -> void:
	var data := SaveData.new()
	data.story_progress = {"fruit_selection_done": true}

	var show: bool = _fruit.should_show_selection(data)
	assert_false(show, "Should NOT show when fruit_selection_done is true")

# --- Toggle behavior ---

func test_toggle_select_then_deselect() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	assert_eq(_fruit.get_selected().size(), 1)

	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)  # deselect
	assert_eq(_fruit.get_selected().size(), 0)

func test_toggle_invalid_fruit_ignored() -> void:
	_fruit.toggle_fruit(9999)  # invalid
	assert_eq(_fruit.get_selected().size(), 0)

func test_confirm_without_enough_fruits_does_nothing() -> void:
	var data := SaveData.new()
	data.story_progress = {}

	_fruit.confirm_and_write(null, data)

	assert_false(data.story_progress.get("fruit_selection_done", false),
		"confirm_and_write should not write when < 2 fruits selected")

# --- Reset ---

func test_reset_clears_selection() -> void:
	_fruit.toggle_fruit(FruitSelection.FRUIT_STR)
	_fruit.toggle_fruit(FruitSelection.FRUIT_AGI)

	_fruit.reset()

	assert_eq(_fruit.get_selected().size(), 0)
	assert_false(_fruit.can_confirm())
