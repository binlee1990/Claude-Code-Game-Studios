# Story 001: AIController @abstract 基类 + NullAI

> **Epic**: AI | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/ai.md` | **Requirement**: `TR-ai-001`, `TR-ai-004`, `TR-ai-006`
**ADR**: ADR-0008: AI Controller | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] AIController 为 @abstract RefCounted 基类
- [ ] take_turn(units, world_state)→ActionList 虚方法
- [ ] NullAI extends AIController，take_turn 返回空 ActionList
- [ ] 接口容纳 NullAI+BasicAI 替换，不修改 Turn System
- [ ] @abstract 双重守卫：class-level + method assert(false) 作为 runtime fallback

## Implementation Notes
```gdscript
# src/ai/ai_controller.gd
@abstract
class_name AIController extends RefCounted
func take_turn(_units: Array[Unit], _world_state: WorldState) -> ActionList:
    assert(false, "AIController.take_turn() is abstract")
    return ActionList.new()

# src/ai/null_ai.gd
class_name NullAI extends AIController
func take_turn(_units: Array[Unit], _world_state: WorldState) -> ActionList:
    return ActionList.new()  # Empty — hotseat mode
```

## Test Evidence: `tests/unit/ai/ai_controller_test.gd`
## Dependencies: Turn Epic（take_turn 调用方）
