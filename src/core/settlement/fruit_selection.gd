class_name FruitSelection
extends RefCounted

## Fruit selection logic for chapter settlement (Ch.2-3 victory).
## Presents 3 fruits, player must select 2. Selection is persisted.
## Supports reload-and-retry via fruit_selection_done flag.
##
## Belongs to: Story CH2-c-006
## GDD: design/gdd/chapter-02.md §3.7, §5.8

## Fruit resource types (using ResourceTypes enum).
const FRUIT_STR: int = ResourceTypes.ResourceId.FRUIT_STR
const FRUIT_AGI: int = ResourceTypes.ResourceId.FRUIT_AGI
const FRUIT_INT: int = ResourceTypes.ResourceId.FRUIT_INT

const ALL_FRUITS: Array[int] = [FRUIT_STR, FRUIT_AGI, FRUIT_INT]
const MAX_SELECTION: int = 2

var _selected: Array[int] = []

## Returns all 3 available fruits.
func get_available_fruits() -> Array[int]:
	return ALL_FRUITS.duplicate()

## Returns current player selection.
func get_selected() -> Array[int]:
	return _selected.duplicate()

## Toggles fruit selection (select or deselect).
func toggle_fruit(fruit_id: int) -> void:
	if fruit_id not in ALL_FRUITS:
		return
	if fruit_id in _selected:
		_selected.erase(fruit_id)
	else:
		if _selected.size() >= MAX_SELECTION:
			_selected.pop_front()  # drop oldest
		_selected.append(fruit_id)

## Returns true if player has made enough selections to confirm.
func can_confirm() -> bool:
	return _selected.size() >= MAX_SELECTION

## Writes selected fruits to inventory and persists completion flag.
func confirm_and_write(inventory, data: SaveData) -> void:
	if not can_confirm():
		return
	for fruit_id in _selected:
		inventory.add_resource(fruit_id, 1)
	data.story_progress["fruit_selection_done"] = true

## Returns true if selection screen should be shown.
## False means player already completed selection for this chapter.
func should_show_selection(data: SaveData) -> bool:
	return not data.story_progress.get("fruit_selection_done", false)

## Clears current selection (used when reloading/interrupting).
func reset() -> void:
	_selected.clear()
