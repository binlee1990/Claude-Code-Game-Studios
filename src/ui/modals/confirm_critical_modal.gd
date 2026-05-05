## ConfirmCriticalModal — P-INP-02 irreversible action confirmation.
##
## Extends BaseModal. Enforces 3 safety gates per P-INP-02 pattern:
##   1. Warning title with failure_red text + ⚠ icon
##   2. Consequence list with ↓/+ symbols
##   3. 2s cooldown + checkbox "我了解此操作不可逆" before main button activates
##
## ESC / Gamepad B = cancel. External click-to-close is disabled.
class_name ConfirmCriticalModal
extends BaseModal


@onready var title_label: Label = %TitleLabel
@onready var consequence_list: VBoxContainer = %ConsequenceList
@onready var confirm_checkbox: CheckBox = %ConfirmCheckbox
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton
@onready var cooldown_bar: ProgressBar = %CooldownBar

var _cooldown_elapsed: float = 0.0
var _cooldown_duration: float = 2.0
var _confirmed: bool = false


func _ready() -> void:
	super._ready()
	confirm_button.disabled = true
	cooldown_bar.max_value = _cooldown_duration
	cooldown_bar.value = 0.0
	cancel_button.pressed.connect(close)
	confirm_button.pressed.connect(_on_confirm)
	confirm_checkbox.toggled.connect(_on_checkbox_toggled)


func open(payload_data: Dictionary = {}) -> void:
	super.open(payload_data)
	title_label.text = tr(payload_data.get("title", "确认操作"))
	_build_consequences(payload_data.get("consequences", []))
	var confirm_label := tr(payload_data.get("confirm_label", "确认"))
	confirm_button.text = confirm_label
	# Reset state
	_cooldown_elapsed = 0.0
	_confirmed = false
	confirm_button.disabled = true
	confirm_checkbox.button_pressed = false
	cooldown_bar.value = 0.0


func _build_consequences(items: Array) -> void:
	for child in consequence_list.get_children():
		child.queue_free()
	for item in items:
		var label := Label.new()
		label.text = "  " + str(item)
		label.add_theme_font_size_override("font_size", 16)
		consequence_list.add_child(label)


func _on_checkbox_toggled(pressed: bool) -> void:
	_check_activation()


func _process(delta: float) -> void:
	if _confirmed:
		return
	if not visible:
		return
	_cooldown_elapsed += delta
	cooldown_bar.value = min(_cooldown_elapsed, _cooldown_duration)
	_check_activation()


func _check_activation() -> void:
	var cooldown_ready := _cooldown_elapsed >= _cooldown_duration
	var checkbox_checked := confirm_checkbox.button_pressed
	confirm_button.disabled = not (cooldown_ready and checkbox_checked)


func _on_confirm() -> void:
	_confirmed = true
	var callback: Callable = payload.get("on_confirm", Callable())
	if callback.is_valid():
		callback.call()
	close()
