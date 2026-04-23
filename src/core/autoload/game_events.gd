extends Node

## Global event bus for decoupled cross-system communication.
## All gameplay events are emitted here so systems never hold direct references.

signal unit_spawned(unit: Node)                           ## A Unit entered the scene tree
signal unit_despawned(unit: Node)                         ## A Unit left the scene tree
signal turn_started(actor: Node)                          ## A new turn began
signal turn_ended(actor: Node)                            ## A turn ended
signal combat_started()                                   ## Combat encounter began
signal combat_ended(winner: Node)                         ## Combat encounter ended
signal health_changed(unit: Node, old_value: int, new_value: int)  ## Unit HP changed
signal damage_dealt(target: Node, amount: int, source: Node)       ## Damage was applied
signal unit_died(unit: Node, killer: Node)                          ## Unit reached 0 HP
signal buff_added(unit: Node, buff_id: String)                      ## Status effect applied
signal buff_removed(unit: Node, buff_id: String)                    ## Status effect expired
signal skill_used(user: Node, skill_id: String, targets: Array)      ## Skill activated
signal skill_cooldown_ready(user: Node, skill_id: String)            ## Skill off cooldown
signal game_saved(slot: int, timestamp: int)                          ## Game was saved
signal game_loaded(slot: int)                                         ## Game was loaded
signal attribute_changed(unit: Node, attr_type: int, old_value: int, new_value: int)  ## Attribute V changed
signal threshold_unlocked(unit: Node, attr_type: int, threshold: int)  ## Normal attribute reached threshold for first time
signal class_changed(unit: Node, old_class: int, new_class: int)       ## Unit changed class
signal class_level_up(unit: Node, class_id: int, new_level: int)       ## Unit class level increased
signal resource_changed(resource_type: int, old_amount: int, new_amount: int)  ## Resource amount changed
signal resource_overflow(resource_type: int, discarded: int)                    ## Resource hit stack limit
signal auto_battle_toggled(enabled: bool)             ## Auto-battle mode was turned on or off
signal manual_override_activated(unit: Node)           ## Player took manual control of a unit for this turn
signal speed_tier_changed(old_tier: int, new_tier: int)  ## Combat speed tier (SpeedController.SpeedTier) changed
signal settlement_triggered(result: SettlementResult)  ## Battle settlement was triggered (Story BS-001)


func _init() -> void:
	## Ensure this autoload persists across scenes
	process_mode = Node.PROCESS_MODE_ALWAYS
