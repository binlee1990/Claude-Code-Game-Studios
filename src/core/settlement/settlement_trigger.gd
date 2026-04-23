class_name SettlementTrigger
extends RefCounted

## Determines and produces the SettlementResult from a battle end condition.
## Consumed by downstream settlement systems (exp, evaluation, drops).
##
## Implements: Story BS-001 (Settlement Trigger & Flow)
## GDD Reference: design/gdd/battle-settlement.md — Section C.1, E.1, E.2, E.5
##
## Precedence when both sides die in the same action (GDD E.2 edge case):
## victory is declared first — enemies checked before allies.


## Build a VICTORY result. Caller provides the surviving player units.
## Use when the combat flow confirms all enemies have HP=0.
##
## Example:
##   var result := trigger.trigger_victory(alive_players)
##   # result.rewards_enabled == true
func trigger_victory(surviving_players: Array, surviving_enemies: Array = []) -> SettlementResult:
	var r := SettlementResult.new()
	r.type = SettlementResult.SettlementType.VICTORY
	r.surviving_players = surviving_players.duplicate()
	r.surviving_enemies = surviving_enemies.duplicate()
	r.rewards_enabled = true
	_emit(r)
	return r


## Build a DEFEAT result. Caller provides any surviving enemies.
## Use when the combat flow confirms all player units have HP=0.
## rewards_enabled is false — GDD C.1: no EXP, no gold on defeat.
##
## Example:
##   var result := trigger.trigger_defeat(alive_enemies)
##   # result.rewards_enabled == false
func trigger_defeat(surviving_enemies: Array) -> SettlementResult:
	var r := SettlementResult.new()
	r.type = SettlementResult.SettlementType.DEFEAT
	r.surviving_players = []
	r.surviving_enemies = surviving_enemies.duplicate()
	r.rewards_enabled = false
	_emit(r)
	return r


## Build a RETREAT result. Treated as defeat by downstream systems
## (rewards_enabled = false) but tagged RETREAT so UI / achievements
## can distinguish a manual retreat from a combat loss.
##
## Returns null if `can_retreat` is false — GDD E.5: no retreat skill/item
## means the option is unavailable and must not trigger settlement.
##
## Example:
##   var result := trigger.trigger_retreat(has_retreat_skill, alive_players, alive_enemies)
##   if result == null: pass  # retreat was blocked — caller handles UI feedback
func trigger_retreat(can_retreat: bool, surviving_players: Array, surviving_enemies: Array) -> SettlementResult:
	if not can_retreat:
		return null
	var r := SettlementResult.new()
	r.type = SettlementResult.SettlementType.RETREAT
	r.surviving_players = surviving_players.duplicate()
	r.surviving_enemies = surviving_enemies.duplicate()
	r.rewards_enabled = false
	_emit(r)
	return r


## Resolve a settlement from raw team-alive flags. Implements precedence
## rule GDD E.2: when all enemies AND all players die the same action,
## victory takes precedence (enemies checked first).
##
## Returns null if neither side is fully defeated (combat still in progress).
##
## Example:
##   var result := trigger.resolve(any_enemy_alive, any_player_alive, players, enemies)
##   if result != null: _enter_settlement_phase(result)
func resolve(any_enemy_alive: bool, any_player_alive: bool,
		surviving_players: Array, surviving_enemies: Array) -> SettlementResult:
	if not any_enemy_alive:
		return trigger_victory(surviving_players, surviving_enemies)
	if not any_player_alive:
		return trigger_defeat(surviving_enemies)
	return null


func _emit(result: SettlementResult) -> void:
	GameEvents.settlement_triggered.emit(result)
