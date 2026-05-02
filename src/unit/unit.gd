class_name Unit extends Node2D

const COLOR_PLAYER := Color("#3B82F6")
const COLOR_ENEMY := Color("#EF4444")
const UnitState = preload("res://src/core/unit_state.gd")

static var _id_counter: int = 0
static var _test_instances: Array = []

var unit_id: String
var max_hp: int
var atk: int
var def: int
var mov: int
var rng: int
var faction: Faction.Type
var hp: int = 0:
	set(v):
		var clamped := clampi(v, 0, max_hp)
		if hp == clamped:
			return
		var was_alive := hp > 0
		hp = clamped
		_update_visual()
		if was_alive and clamped <= 0:
			unit_died.emit(self)
var grid_position: Vector2i
var action_state = UnitState.IDLE:
	set(v):
		action_state = v
		_update_visual()
var has_acted_this_turn: bool = false:
	set(v):
		has_acted_this_turn = v
		_update_visual()

signal unit_died(unit: Unit)

func _init() -> void:
	_test_instances.append(weakref(self))

static func free_test_instances() -> void:
	for ref in _test_instances:
		var unit = ref.get_ref()
		if is_instance_valid(unit):
			unit.free()
	_test_instances.clear()

func initialize(stats: UnitStats, p_faction: Faction.Type) -> void:
	assert(stats.validate(), "UnitStats validation failed")
	unit_id = "unit_%d" % _id_counter
	_id_counter += 1
	max_hp = stats.max_hp
	atk = stats.atk
	def = stats.def
	mov = stats.mov
	rng = stats.rng
	faction = p_faction
	hp = max_hp

func _ready() -> void:
	_update_visual()

func is_alive() -> bool:
	return hp > 0

func is_dead() -> bool:
	return hp <= 0

func can_be_selected() -> bool:
	return is_alive() and not has_acted_this_turn and action_state == UnitState.IDLE

func can_move() -> bool:
	return action_state == UnitState.SELECTED

func can_attack() -> bool:
	return action_state in [UnitState.SELECTED, UnitState.MOVED]

func take_damage(amount: int) -> void:
	assert(amount > 0, "take_damage: amount must be > 0")
	if not is_alive():
		return
	hp = hp - amount

func heal(amount: int) -> void:
	assert(amount > 0, "heal: amount must be > 0")
	if not is_alive():
		return
	hp = hp + amount

func reset_action_state() -> void:
	has_acted_this_turn = false
	action_state = UnitState.IDLE
	_update_visual()

func _update_visual() -> void:
	var color_rect: ColorRect = get_node_or_null("ColorRect")
	if color_rect:
		if has_acted_this_turn:
			color_rect.modulate = Color.GRAY
			color_rect.modulate.a = 0.5
		else:
			color_rect.modulate = COLOR_PLAYER if faction == Faction.Type.PLAYER else COLOR_ENEMY
	var label: Label = get_node_or_null("Label")
	if label:
		label.text = "HP: %d/%d" % [hp, max_hp]
