extends Gut

var _model: BaseUpgradeModel

func before_each() -> void:
	_model = BaseUpgradeModel.new()
	assert_true(_model.load_config(), "Base upgrade costs should load from the Sprint-006 data table")
	Inventory.reset()

func after_each() -> void:
	Inventory.reset()

func test_reads_level_one_upgrade_cost_and_unlocks() -> void:
	var entry := _model.get_entry_for_level(1)
	var cost := _model.get_cost_for_level(1)

	assert_eq(int(entry.get("to_level", 0)), 2)
	assert_eq(int(cost.get("gold", 0)), 500)
	assert_eq(int(cost.get("basic_material", 0)), 20)
	assert_true(entry.get("unlocks", []).has("tavern"))

func test_apply_upgrade_spends_resources_and_round_trips_state() -> void:
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 500)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 20)

	var result := _model.apply_upgrade(BaseUpgradeModel.default_state(), Inventory)

	assert_true(result.get("success", false))
	assert_eq(int(result.get("to_level", 0)), 2)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.GOLD), 0)
	assert_eq(Inventory.get_amount(ResourceTypes.ResourceId.BASIC_MATERIAL), 0)
	var state: Dictionary = result.get("state", {})
	assert_true(_model.is_unlocked(state, "tavern"))
	var restored := _model.normalize_state(state)
	assert_eq(int(restored.get("level", 0)), 2)
	assert_true(restored.get("unlocks", []).has("market_expansion"))

func test_shortage_reports_exact_missing_resources() -> void:
	Inventory.add_resource(ResourceTypes.ResourceId.GOLD, 125)
	Inventory.add_resource(ResourceTypes.ResourceId.BASIC_MATERIAL, 7)

	var shortage := _model.get_shortage(1, Inventory)

	assert_eq(int(shortage.get("gold", 0)), 375)
	assert_eq(int(shortage.get("basic_material", 0)), 13)
