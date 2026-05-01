class_name BossActionPattern
extends Resource

enum TargetScope { SINGLE = 0, ROW = 1, CROSS = 2, AREA = 3 }
enum RangeIndicator { RECT = 0, CROSS = 1, DIAMOND = 2, FULLSCREEN = 3 }

@export var pattern_id: String = ""
@export var telegraph_duration: float = 0.7
@export var range_indicator: int = RangeIndicator.RECT
@export var element_type: int = 0
@export var cooldown_turns: int = 2
@export var targets: int = TargetScope.SINGLE
@export var damage_multiplier: float = 1.0
