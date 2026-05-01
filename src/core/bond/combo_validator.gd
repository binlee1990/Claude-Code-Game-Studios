class_name ComboValidator
extends RefCounted

enum FailReason {
	NONE = 0,
	NOT_ENOUGH_AP = 1,
	ON_COOLDOWN = 2,
	DISTANCE_TOO_FAR = 3,
	UNIT_NOT_AVAILABLE = 4,
	BOND_RANK_TOO_LOW = 5,
	NOT_PLAYER_TRIGGERED = 6,
	INVALID_PAIR = 7,
}

const FAIL_MESSAGES: Dictionary = {
	FailReason.NONE: "",
	FailReason.NOT_ENOUGH_AP: "行动点不足",
	FailReason.ON_COOLDOWN: "冷却中",
	FailReason.DISTANCE_TOO_FAR: "距离过远（需要 ≤3 格）",
	FailReason.UNIT_NOT_AVAILABLE: "单位不可用（阵亡/撤退/被控制）",
	FailReason.BOND_RANK_TOO_LOW: "羁绊等级不足（需要 A 级）",
	FailReason.NOT_PLAYER_TRIGGERED: "仅玩家可触发组合技",
	FailReason.INVALID_PAIR: "无效的羁绊配对",
}


func validate(pair_key: String, skill_data: ComboSkillData, pos_a: Vector2i, pos_b: Vector2i, current_ap_a: int, current_ap_b: int, bond_rank: String, unit_a_available: bool, unit_b_available: bool, cooldowns: Dictionary, is_player: bool) -> int:
	if pair_key == "" or skill_data == null:
		return FailReason.INVALID_PAIR
	if not is_player:
		return FailReason.NOT_PLAYER_TRIGGERED
	if not unit_a_available or not unit_b_available:
		return FailReason.UNIT_NOT_AVAILABLE
	if bond_rank != "A" and bond_rank != "S":
		return FailReason.BOND_RANK_TOO_LOW
	if current_ap_a < skill_data.ap_cost or current_ap_b < skill_data.ap_cost:
		return FailReason.NOT_ENOUGH_AP
	var dist: int = absi(pos_a.x - pos_b.x) + absi(pos_a.y - pos_b.y)
	if dist > skill_data.range_max:
		return FailReason.DISTANCE_TOO_FAR
	var cooldown_key: String = _make_cooldown_key(pair_key, skill_data.skill_id)
	if cooldowns.get(cooldown_key, 0) > 0:
		return FailReason.ON_COOLDOWN
	return FailReason.NONE


func get_fail_message(reason: int) -> String:
	return FAIL_MESSAGES.get(reason, "未知错误")


func _make_cooldown_key(pair_key: String, skill_id: String) -> String:
	return "%s::%s" % [pair_key, skill_id]
