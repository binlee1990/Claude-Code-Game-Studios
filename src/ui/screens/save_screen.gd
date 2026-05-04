## SaveScreen — 存档屏 (S11-012).
##
## Layout: auto-save indicator + 3 save slot cards + action bar.
## Uses ADR-0018 SaveManager multi-slot APIs.
## P-INP-02 confirm-critical modal for delete.
class_name SaveScreen
extends BaseScreen


@onready var autosave_label: Label = %AutosaveLabel
@onready var slot_container: VBoxContainer = %SlotContainer
@onready var save_btn: Button = %SaveBtn
@onready var load_btn: Button = %LoadBtn
@onready var delete_btn: Button = %DeleteBtn
@onready var return_btn: Button = %ReturnBtn

var _save_manager: RefCounted = null
var _selected_slot: int = 0
var _slot_cards: Array[PanelContainer] = []


func _ready() -> void:
	super._ready()
	_resolve_services()
	_build_slots()
	_connect_buttons()
	_refresh_all()


func on_activated() -> void:
	_refresh_all()


func on_deactivated() -> void:
	pass


func _resolve_services() -> void:
	var host := SaveManagerAutoload.get_instance()
	if host == null:
		return
	_save_manager = host


func _connect_buttons() -> void:
	if save_btn != null:
		save_btn.pressed.connect(_on_save)
	if load_btn != null:
		load_btn.pressed.connect(_on_load)
	if delete_btn != null:
		delete_btn.pressed.connect(_on_delete)
	if return_btn != null:
		return_btn.pressed.connect(_on_return)


func _build_slots() -> void:
	if slot_container == null:
		return
	for child in slot_container.get_children():
		child.queue_free()
	_slot_cards.clear()
	for i in range(3):
		var card := PanelContainer.new()
		card.name = "SlotCard_%d" % i
		card.custom_minimum_size = Vector2(0, 200)
		card.focus_mode = Control.FOCUS_ALL
		card.gui_input.connect(_on_slot_clicked.bind(i))
		card.focus_entered.connect(_on_slot_focus.bind(i, true))
		card.focus_exited.connect(_on_slot_focus.bind(i, false))

		var vbox := VBoxContainer.new()
		vbox.name = "SlotVBox"
		vbox.theme_override_constants_separation = 4
		vbox.add_theme_constant_override("margin_left", 12)
		vbox.add_theme_constant_override("margin_top", 8)

		var title := Label.new()
		title.name = "SlotTitle"
		title.text = "%s %d" % [tr("存档"), i + 1]
		title.add_theme_font_size_override("font_size", 20)
		vbox.add_child(title)

		var detail := Label.new()
		detail.name = "SlotDetail"
		detail.text = tr("空存档位")
		detail.add_theme_font_size_override("font_size", 14)
		detail.add_theme_color_override("font_color", Color(0.604, 0.580, 0.533))
		vbox.add_child(detail)

		card.add_child(vbox)
		slot_container.add_child(card)
		_slot_cards.append(card)
	_refresh_slot_cards()


# --- Refresh ---
func _refresh_all() -> void:
	_refresh_autosave_indicator()
	_refresh_slot_cards()
	_update_action_buttons()


func _refresh_autosave_indicator() -> void:
	if autosave_label == null:
		return
	if _save_manager != null and _save_manager.has_method("get_last_autosave_time"):
		var last_time: float = _save_manager.get_last_autosave_time()
		if last_time <= 0.0:
			autosave_label.text = tr("尚未自动保存")
		else:
			var now := Time.get_unix_time_from_system()
			var diff := now - last_time
			if diff < 60:
				autosave_label.text = "%s %d %s" % [tr("上次自动保存:"), int(diff), tr("秒前")]
			elif diff < 3600:
				autosave_label.text = "%s %d %s" % [tr("上次自动保存:"), int(diff / 60), tr("分钟前")]
			else:
				autosave_label.text = "%s %d %s" % [tr("上次自动保存:"), int(diff / 3600), tr("小时前")]
	else:
		autosave_label.text = ""


func _refresh_slot_cards() -> void:
	if _save_manager == null:
		return
	var saves: Array = []
	if _save_manager.has_method("list_saves"):
		saves = _save_manager.list_saves()
	for i in range(_slot_cards.size()):
		var card := _slot_cards[i]
		var detail: Label = _find_child_label(card, "SlotDetail")
		if detail == null:
			continue
		if saves.size() > i and not saves[i].is_empty():
			var save: Dictionary = saves[i]
			var lv := int(save.get("level", 1))
			var realm := str(save.get("realm", "凡人"))
			var play_time := int(save.get("meta", {}).get("play_time_seconds", 0))
			var saved_at := str(save.get("meta", {}).get("saved_at", ""))
			detail.text = "Lv.%d %s | %s | %s" % [lv, tr(realm), _format_time(play_time), saved_at]
		else:
			detail.text = tr("空存档位 — 点击创建新存档")
	_refresh_slot_highlight()


func _find_child_label(parent: PanelContainer, child_name: String) -> Label:
	for child in parent.get_children():
		if child is VBoxContainer:
			for sub in (child as VBoxContainer).get_children():
				if sub is Label and sub.name == child_name:
					return sub as Label
	return null


func _refresh_slot_highlight() -> void:
	for i in range(_slot_cards.size()):
		var card := _slot_cards[i]
		var style := StyleBoxFlat.new()
		if i == _selected_slot:
			style.border_width_left = 4
			style.border_color = Color(0.961, 0.784, 0.259)
			style.bg_color = Color(0.18, 0.18, 0.235)
		card.add_theme_stylebox_override("panel", style)


func _update_action_buttons() -> void:
	if load_btn != null:
		load_btn.disabled = (_save_manager == null)
	if delete_btn != null:
		delete_btn.disabled = (_save_manager == null)


# --- Callbacks ---
func _on_slot_clicked(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_selected_slot = slot
		_refresh_slot_highlight()


func _on_slot_focus(slot: int, focused: bool) -> void:
	if focused:
		_selected_slot = slot
		_refresh_slot_highlight()


func _on_save() -> void:
	if _save_manager == null:
		return
	if _save_manager.has_method("save_game"):
		_save_manager.save_game(_selected_slot)
		_refresh_all()
		_show_toast(tr("保存成功"))


func _on_load() -> void:
	if _save_manager == null:
		return
	if _save_manager.has_method("load_game"):
		_save_manager.load_game(_selected_slot)


func _on_delete() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_modal("confirm_critical", {
			"title": tr("删除存档 %d") % (_selected_slot + 1),
			"consequences": [
				tr("存档将被永久删除，此操作不可逆"),
				tr("将丢失该存档的全部进度"),
			],
			"confirm_label": tr("删除此存档"),
			"on_confirm": func(): _do_delete(),
		})


func _do_delete() -> void:
	if _save_manager != null and _save_manager.has_method("delete_save"):
		_save_manager.delete_save(_selected_slot)
		_refresh_all()
		_show_toast(tr("存档已删除"))


func _on_return() -> void:
	var host := UIManagerHost.get_instance()
	if host != null:
		host.open_screen("cultivation")


func _show_toast(msg: String) -> void:
	var rv := UIManagerHost.find_root_viewport()
	if rv != null and rv.has_method("show_toast"):
		rv.show_toast(msg)


func _format_time(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	return "%dh %dm" % [h, m]
