class_name BeliefGate
extends RefCounted

## B2-GATE: Evaluates the chapter 2 branch decision after Ch.2-1.
## Formula: if (yi - max(ren, zhi)) >= 5 → suppression; else → mercy.
## Writes the result to SaveData.story_progress["belief_branch"].
##
## Belongs to: Story CH2-c-001
## GDD: design/gdd/chapter-02.md §3.8, §4.5 / design/narrative/belief-branching.md §4.1

const BRANCH_THRESHOLD: int = 5

enum BranchVariant {
	MERCY,       # 仁/智路线 — Ch.2-2A 护送战
	SUPPRESSION, # 义路线 — Ch.2-2B 镇压战
}

## Evaluates B2-GATE and returns the branch variant.
## If margin == 0, returns MERCY and sets is_default=true (not actively chosen).
func evaluate(belief_values: Dictionary) -> Dictionary:
	var ren: int = belief_values.get("ren", 0)
	var yi:  int = belief_values.get("yi",  0)
	var zhi: int = belief_values.get("zhi", 0)
	var margin: int = yi - maxf(ren, zhi)

	var variant: BranchVariant
	var branch_key: String

	if margin >= BRANCH_THRESHOLD:
		variant = BranchVariant.SUPPRESSION
		branch_key = "suppression"
	else:
		# Double tie (yi == max && margin == 0) also routes to mercy_default
		variant = BranchVariant.MERCY
		branch_key = "mercy_default"

	return {
		"variant": variant,
		"branch_key": branch_key,
		"margin": margin,
		"yi": yi,
		"ren": ren,
		"zhi": zhi,
	}

## Convenience wrapper: evaluates and writes result to SaveData in one call.
func evaluate_and_persist(belief_system: BeliefSystem, data: SaveData) -> Dictionary:
	var result: Dictionary = evaluate(belief_system.get_values())
	data.story_progress["belief_branch"] = result["branch_key"]
	belief_system.save_to_save_data(data)
	return result

## Returns the branch_variant string for a given BattleDef JSON key.
## chapter_02_act_b uses branch_variant field to select mercy/suppression unit sets.
func get_json_branch_key(variant: BranchVariant) -> String:
	match variant:
		BranchVariant.SUPPRESSION: return "suppression"
		_: return "mercy"
