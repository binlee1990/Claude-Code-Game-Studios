class_name AttributeNames
extends RefCounted

## Attribute type enumerations and constants

# Normal attributes (5 dimensions)
enum Attribute {
	STR,  # 力量
	AGI,  # 敏捷
	CON,  # 体力
	INT,  # 智力
	CHA,  # 魅力
}

# Hidden attributes (4 dimensions)
enum HiddenAttribute {
	LUK,  # 幸运
	WIL,  # 意志力
	RES,  # 异常抵抗
	SOU,  # 灵魂强度
}

# Potential grades (E=1 to S=6)
enum PotentialGrade {
	E = 1,
	D = 2,
	C = 3,
	B = 4,
	A = 5,
	S = 6,
}

# Barrier stages and their thresholds
enum BarrierStage {
	STAGE_1 = 50,
	STAGE_2 = 100,
	STAGE_3 = 150,
}

# All attributes combined for iteration
const ALL_ATTRIBUTES: Array[Attribute] = [
	Attribute.STR, Attribute.AGI, Attribute.CON, Attribute.INT, Attribute.CHA
]

const ALL_HIDDEN_ATTRIBUTES: Array[HiddenAttribute] = [
	HiddenAttribute.LUK, HiddenAttribute.WIL, HiddenAttribute.RES, HiddenAttribute.SOU
]

const ALL_POTENTIAL_GRADES: Array[int] = [
	PotentialGrade.E, PotentialGrade.D, PotentialGrade.C, PotentialGrade.B, PotentialGrade.A, PotentialGrade.S
]

## Constants
const MAX_ATTRIBUTE_VALUE: int = 999
const DEFAULT_ATTRIBUTE_VALUE: int = 10
const DEFAULT_POTENTIAL: int = PotentialGrade.E

const CRUSH_THRESHOLD: int = 30
const CRUSH_DAMAGE_MULTIPLIER: float = 1.5
const CRUSH_DEFENSE_MULTIPLIER: float = 0.8

const THRESHOLD_REWARDS: Array[int] = [50, 100, 150]

## Utility functions
static func get_attribute_name(attr: Attribute) -> String:
	match attr:
		Attribute.STR: return "力量"
		Attribute.AGI: return "敏捷"
		Attribute.CON: return "体力"
		Attribute.INT: return "智力"
		Attribute.CHA: return "魅力"
		_: return "未知"

static func get_hidden_attribute_name(attr: HiddenAttribute) -> String:
	match attr:
		HiddenAttribute.LUK: return "幸运"
		HiddenAttribute.WIL: return "意志力"
		HiddenAttribute.RES: return "异常抵抗"
		HiddenAttribute.SOU: return "灵魂强度"
		_: return "未知"

static func get_potential_name(grade: int) -> String:
	match grade:
		PotentialGrade.E: return "E"
		PotentialGrade.D: return "D"
		PotentialGrade.C: return "C"
		PotentialGrade.B: return "B"
		PotentialGrade.A: return "A"
		PotentialGrade.S: return "S"
		_: return "?"

static func get_barrier_threshold(stage: int) -> int:
	match stage:
		1: return BarrierStage.STAGE_1
		2: return BarrierStage.STAGE_2
		3: return BarrierStage.STAGE_3
		_: return 0

static func is_hidden_attribute(attr: Variant) -> bool:
	return attr in ALL_HIDDEN_ATTRIBUTES
