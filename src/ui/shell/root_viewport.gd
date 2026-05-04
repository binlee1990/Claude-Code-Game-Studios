## RootViewport — top-level UI container with 3 CanvasLayers.
##
## Layer 0 (UILayer): Shell (MarginContainer with theme) containing
##   TOP_STRIP, LEFT_NAV, CENTER_CONTENT/ScreenContainer, RIGHT_PANEL,
##   and BOTTOM_ACTION_BAR.
## Layer 1 (ToastLayer): P-FBK-01 toast stack.
## Layer 2 (ModalLayer): semi-transparent input blocker + modal container.
##
## UIManagerHost holds a reference to this node and uses its containers
## to manage screen instantiation and modal display.
class_name RootViewport
extends Control


# --- Layer 0: UILayer children ---
@onready var shell: MarginContainer = %Shell
@onready var top_strip: PanelContainer = %TopStrip
@onready var left_nav: PanelContainer = %LeftNav
@onready var center_content: Control = %CenterContent
@onready var screen_container: Control = %ScreenContainer
@onready var right_panel: PanelContainer = %RightPanel
@onready var bottom_action_bar: PanelContainer = %BottomActionBar

# --- Layer 1: ToastLayer children ---
@onready var toast_stack: VBoxContainer = %ToastStack

# --- Layer 2: ModalLayer children ---
@onready var modal_blocker: ColorRect = %ModalBlocker
@onready var modal_container: Control = %ModalContainer


func _ready() -> void:
	_configure_modal_blocker()
	_bind_phone_resolution()


## Configure the modal blocker ColorRect: semi-transparent black
## that captures all input when a modal is open.
func _configure_modal_blocker() -> void:
	modal_blocker.color = Color(0, 0, 0, 0.35)
	modal_blocker.hide()
	modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_blocker.gui_input.connect(_on_modal_blocker_input)


## When the modal blocker is clicked (not on a modal child), do nothing.
## The ESC/B keybinding in BaseModal handles dismiss — clicking the
## backdrop is intentionally a no-op per P-INP-02 spec.
func _on_modal_blocker_input(event: InputEvent) -> void:
	# Accept the event to prevent it reaching lower layers,
	# but do NOT close the modal — only ESC/B dismisses.
	pass


## Toggle the LEFT NAV collapse/expand via F key or Gamepad RT.
## Listens for ui_toggle_nav action and delegates to left_nav.gd.
func _bind_phone_resolution() -> void:
	# Apply responsive layout adjustments based on initial window size.
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x < 1400:
		# Steam Deck / 720p: collapse LEFT NAV by default.
		_try_collapse_nav()


func _try_collapse_nav() -> void:
	if left_nav != null and left_nav.has_method("collapse"):
		left_nav.collapse()


## --- Public API for UIManagerHost ---

## Returns the ScreenContainer where screen scenes are added.
func get_screen_container() -> Control:
	return screen_container


## Returns the ModalContainer where modal popups are added.
func get_modal_container() -> Control:
	return modal_container


## Show the modal blocker overlay.
func show_modal_blocker() -> void:
	modal_blocker.show()


## Hide the modal blocker overlay.
func hide_modal_blocker() -> void:
	modal_blocker.hide()


## Returns the ToastStack container for toast messages.
func get_toast_stack() -> VBoxContainer:
	return toast_stack


## Show a toast message via P-FBK-01 toast stack.
func show_toast(message: String, duration: float = 4.0) -> void:
	if toast_stack != null and toast_stack.has_method("push_toast"):
		toast_stack.push_toast(message, duration)


## Returns the LEFT NAV panel for width toggling.
func get_left_nav() -> PanelContainer:
	return left_nav


## Returns the TOP STRIP for resource display.
func get_top_strip() -> PanelContainer:
	return top_strip


## Returns the RIGHT PANEL for battle log.
func get_right_panel() -> PanelContainer:
	return right_panel


## Toggle LEFT NAV expanded/collapsed state.
func toggle_nav() -> void:
	if left_nav != null and left_nav.has_method("toggle"):
		left_nav.toggle()
