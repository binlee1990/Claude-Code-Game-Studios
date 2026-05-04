## ResourcesScreen — 资源/背包屏 (S11-011).
##
## 3-tab architecture: 资源 / 背包 / 图鉴 (locked).
## 资源 tab: 5 P-DAT-01-EXP expandable rows with current/cap/fill bar.
## 背包 tab: 4-column GridContainer with P-DAT-04 ItemCards.
## 图鉴 tab: locked placeholder.
class_name ResourcesScreen
extends BaseScreen


# Tab bar
@onready var tab_resources_btn: Button = %TabResourcesBtn
@onready var tab_backpack_btn: Button = %TabBackpackBtn
@onready var tab_encyclopedia_btn: Button = %TabEncyclopediaBtn

# Content containers
@onready var resources_content: Control = %ResourcesContent
@onready var backpack_content: Control = %BackpackContent
@onready var encyclopedia_content: Control = %EncyclopediaContent

# Resource tab — 5 expandable rows
@onready var res_lingqi_row: ResourceProductionRow = %ResLingqiRow
@onready var res_xiuwei_row: ResourceProductionRow = %ResXiuweiRow
@onready var res_lingshi_row: ResourceProductionRow = %ResLingshiRow
@onready var res_herb_row: ResourceProductionRow = %ResHerbRow
@onready var res_exp_row: ResourceProductionRow = %ResExpRow

# Backpack tab
@onready var item_grid: GridContainer = %ItemGrid
@onready var empty_placeholder: Label = %EmptyPlaceholder

# Encyclopedia tab
@onready var encyclopedia_placeholder: Label = %EncyclopediaPlaceholder

const RESOURCE_IDS := ["lingqi", "xiuwei", "lingshi", "herb", "exp"]
const RESOURCE_ICONS: Dictionary = {
	"lingqi": "res://assets/ui/icons/resources/lingqi.png",
	"xiuwei": "res://assets/ui/icons/resources/xiuwei.png",
	"lingshi": "res://assets/ui/icons/resources/lingshi.png",
	"herb": "res://assets/ui/icons/resources/herb.png",
	"exp": "res://assets/ui/icons/resources/exp.png",
}
const RESOURCE_NAMES: Dictionary = {
	"lingqi": "灵气", "xiuwei": "修为", "lingshi": "灵石", "herb": "药材", "exp": "经验",
}

var _resource_service: RefCounted = null
var _item_registry: RefCounted = null
var _active_tab: String = "resources"


func _ready() -> void:
	super._ready()
	_resolve_services()
	_connect_tabs()
	_switch_tab("resources")


func on_activated() -> void:
	for res_id in RESOURCE_IDS:
		_subscribe("resource.%s.changed" % res_id, _on_resource_changed)
	_subscribe("storage.cap_warning", _on_cap_warning)
	_refresh_resource_rows()
	_refresh_backpack()


func on_deactivated() -> void:
	for res_id in RESOURCE_IDS:
		_unsubscribe("resource.%s.changed" % res_id, _on_resource_changed)
	_unsubscribe("storage.cap_warning", _on_cap_warning)


func _resolve_services() -> void:
	var host := ResourceSystemHost.get_instance()
	if host != null: _resource_service = host.get_service()
	var item_host := ItemRegistryHost.get_instance()
	if item_host != null: _item_registry = item_host.get_service()


func _connect_tabs() -> void:
	tab_resources_btn.pressed.connect(_switch_tab.bind("resources"))
	tab_backpack_btn.pressed.connect(_switch_tab.bind("backpack"))
	tab_encyclopedia_btn.pressed.connect(_switch_tab.bind("encyclopedia"))


func _switch_tab(tab: String) -> void:
	_active_tab = tab
	resources_content.visible = (tab == "resources")
	backpack_content.visible = (tab == "backpack")
	encyclopedia_content.visible = (tab == "encyclopedia")
	# Highlight active tab button
	for btn in [tab_resources_btn, tab_backpack_btn, tab_encyclopedia_btn]:
		if btn != null:
			btn.remove_theme_stylebox_override("normal")
	var active_btn: Button
	match tab:
		"resources": active_btn = tab_resources_btn
		"backpack": active_btn = tab_backpack_btn
		"encyclopedia": active_btn = tab_encyclopedia_btn
	if active_btn != null:
		var style := StyleBoxFlat.new()
		style.border_width_bottom = 2
		style.border_color = Color(0.961, 0.784, 0.259)
		active_btn.add_theme_stylebox_override("normal", style)


# --- Resource tab ---
func _refresh_resource_rows() -> void:
	if _resource_service == null:
		return
	var rows := [res_lingqi_row, res_xiuwei_row, res_lingshi_row, res_herb_row, res_exp_row]
	for i in range(RESOURCE_IDS.size()):
		var res_id := RESOURCE_IDS[i]
		var row: ResourceProductionRow = rows[i]
		if row == null:
			continue
		var value := _resource_service.get_value(res_id)
		# Update rate via OMS
		var oms_host := OutputMultiplierSystemHost.get_instance()
		var rate: float = 0.0
		if oms_host != null and oms_host.get_service() != null:
			var oms := oms_host.get_service()
			if oms.has_method("get_production_rate"):
				rate = oms.get_production_rate(res_id)
		row.set_rate(rate)
		# Also show current value in the row if possible
		if row.has_method("set_value"):
			row.set_value(value)


func _on_resource_changed(payload: Dictionary) -> void:
	var res_id := str(payload.get("resource_id", ""))
	if res_id.is_empty():
		return
	var idx := RESOURCE_IDS.find(res_id)
	if idx < 0:
		return
	var rows := [res_lingqi_row, res_xiuwei_row, res_lingshi_row, res_herb_row, res_exp_row]
	var row: ResourceProductionRow = rows[idx]
	if row == null or _resource_service == null:
		return
	var value := _resource_service.get_value(res_id)
	if row.has_method("set_value"):
		row.set_value(value)


func _on_cap_warning(payload: Dictionary) -> void:
	# Flash the affected resource row red
	var res_id := str(payload.get("resource_id", ""))
	var fill_ratio: float = payload.get("fill_ratio", 0.0)
	if fill_ratio < 0.85:
		return
	# Visual flash handled via theme override or modulation


# --- Backpack tab ---
func _refresh_backpack() -> void:
	if item_grid == null:
		return
	for child in item_grid.get_children():
		child.queue_free()
	if _item_registry == null or _resource_service == null:
		empty_placeholder.visible = true
		return
	# Collect items with quantities from ResourceSystem
	var items_displayed := 0
	for item_id in ["herb", "lingshi"]:
		var qty := _resource_service.get_value(item_id)
		if qty.is_greater_than(BigNumber.from_int(0)):
			_add_item_card(item_id, qty)
			items_displayed += 1
	# TODO: extend with full inventory from item-material-system
	empty_placeholder.visible = (items_displayed == 0)


func _add_item_card(item_id: String, qty: BigNumber) -> void:
	var card := ItemCard.new()
	var metadata := {}
	if _item_registry != null and _item_registry.has_method("get"):
		metadata = _item_registry.get(item_id)
	if metadata.is_empty():
		metadata = {
			"name": RESOURCE_NAMES.get(item_id, item_id),
			"rarity": "common",
			"icon_path": RESOURCE_ICONS.get(item_id, ""),
		}
	var count: int = max(1, int(qty.to_float()))
	metadata["count"] = count
	card.set_item(metadata)
	item_grid.add_child(card)
