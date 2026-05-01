class_name BossCheckpoint
extends Resource

@export var phase_index: int = 0
@export var boss_hp_at_checkpoint: int = 0
@export var retained_hp_ratio: float = 0.15
@export var free_retries: int = 2
@export var pattern_hints_revealed: bool = false


func get_retained_hp(boss_max_hp: int) -> int:
	return int(ceil(float(boss_max_hp) * retained_hp_ratio))
