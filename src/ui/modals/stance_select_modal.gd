class_name StanceSelectModal
extends BaseModal

const Sprint11AssetCatalog := preload("res://src/ui/sprint11_asset_catalog.gd")

const STANCES := [
	{"id": "meditate", "label": "打坐", "enabled": true},
	{"id": "condense", "label": "凝练", "enabled": true},
	{"id": "closed_door", "label": "闭关", "enabled": false},
	{"id": "idle", "label": "挂机", "enabled": false},
]


func _ready() -> void:
	super._ready()
	_build_content()


func _build_content() -> void:
	var vbox := _content_vbox()
	if vbox == null:
		return
	for child in vbox.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = tr("修炼姿态")
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for stance in STANCES:
		var row := Button.new()
		var stance_id := str(stance["id"])
		row.text = tr(str(stance["label"])) if bool(stance["enabled"]) else "%s  %s" % [tr(str(stance["label"])), tr("未解锁")]
		row.icon = Sprint11AssetCatalog.get_texture(Sprint11AssetCatalog.STANCE_ICONS, stance_id)
		row.disabled = not bool(stance["enabled"])
		row.focus_mode = Control.FOCUS_ALL
		if bool(stance["enabled"]):
			row.pressed.connect(_select_stance.bind(stance_id))
		vbox.add_child(row)


func _select_stance(stance_id: String) -> void:
	var host := CultivationSystemHost.get_instance()
	if host != null and host.get_service() != null and host.get_service().has_method("set_stance"):
		host.get_service().set_stance(stance_id)
	_close_modal()


func _content_vbox() -> VBoxContainer:
	for child in get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null
