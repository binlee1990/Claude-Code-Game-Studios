class_name FormulaEngine
extends RefCounted

const MAX_EXPRESSION_LENGTH := 4096

static var _formulas := {}
static var _cache := {}


## Registers or replaces a formula definition.
static func register_formula(formula_id: String, expression: String, variables: Array = []) -> void:
	_formulas[formula_id] = {
		"expression": expression,
		"variables": variables,
	}
	_cache.erase(formula_id)


## Evaluates a registered formula with the provided context.
static func evaluate(formula_id: String, context: Dictionary) -> float:
	if not _formulas.has(formula_id):
		push_warning("Formula not found: %s" % formula_id)
		return 0.0
	var definition: Dictionary = _formulas[formula_id]
	return _evaluate_expression(formula_id, definition["expression"], definition["variables"], context)


## Evaluates a raw expression using context keys as variables.
static func evaluate_raw(expression: String, context: Dictionary) -> float:
	var variables := context.keys()
	variables.sort()
	return _evaluate_expression("__raw__:%s" % expression, expression, variables, context)


## Removes one parsed expression from the cache.
static func invalidate(formula_id: String) -> void:
	_cache.erase(formula_id)


## Clears all registered parse cache entries.
static func invalidate_all() -> void:
	_cache.clear()


## Clears formula definitions and cache. Intended for isolated tests.
static func clear_all() -> void:
	_formulas.clear()
	_cache.clear()


static func _evaluate_expression(cache_key: String, expression: String, variables: Array, context: Dictionary) -> float:
	var clean_expression := expression.strip_edges()
	if clean_expression.is_empty():
		push_warning("Empty expression for formula: %s" % cache_key)
		return 0.0
	if clean_expression.length() > MAX_EXPRESSION_LENGTH:
		push_warning("Expression too long for formula: %s" % cache_key)
		clean_expression = clean_expression.substr(0, MAX_EXPRESSION_LENGTH)
	if _cache.has(cache_key) and _cache[cache_key].get("error", false):
		return 0.0
	var expression_object: Expression
	if _cache.has(cache_key):
		expression_object = _cache[cache_key]["expression"]
	else:
		expression_object = Expression.new()
		var parse_error := expression_object.parse(clean_expression, variables)
		if parse_error != OK:
			push_warning("Formula parse failed: %s" % cache_key)
			_cache[cache_key] = {"error": true}
			return 0.0
		_cache[cache_key] = {"error": false, "expression": expression_object}
	var inputs := []
	for variable in variables:
		if not context.has(variable):
			push_warning("Missing variable '%s' in context for formula '%s', defaulting to 0.0" % [str(variable), cache_key])
			inputs.append(0.0)
		else:
			inputs.append(_to_float(context[variable]))
	var result = expression_object.execute(inputs, FormulaHelper.new(), false)
	if expression_object.has_execute_failed():
		push_warning("Formula execution failed: %s" % cache_key)
		return 0.0
	return _to_float(result)


static func _to_float(value: Variant) -> float:
	match typeof(value):
		TYPE_BOOL:
			return 1.0 if bool(value) else 0.0
		TYPE_INT, TYPE_FLOAT:
			var numeric := float(value)
			if is_nan(numeric) or is_inf(numeric):
				return 0.0
			return numeric
		TYPE_STRING:
			if String(value).is_valid_float():
				return String(value).to_float()
			return 0.0
		_:
			return 0.0


class FormulaHelper:
	extends RefCounted

	## Clamps value to the given inclusive range.
	func clamp(value: float, low: float, high: float) -> float:
		return clampf(value, low, high)

	## Returns the base-10 logarithm, or 0.0 for non-positive values.
	func log10(value: float) -> float:
		if value <= 0.0:
			return 0.0
		return log(value) / log(10.0)

	## Applies a power softcap for values above the threshold.
	func softcap(value: float, threshold: float, power_value: float) -> float:
		if value <= 0.0:
			return 0.0
		if threshold <= 0.0:
			push_warning("softcap threshold clamped to 1.0")
			threshold = 1.0
		if power_value <= 0.0:
			push_warning("softcap power clamped to 0.01")
			power_value = 0.01
		if power_value > 1.0:
			push_warning("softcap power clamped to 1.0")
			power_value = 1.0
		if value <= threshold:
			return value
		return threshold + pow(value - threshold, power_value)

	## Applies a logarithmic softcap for values above the threshold.
	func log_softcap(value: float, threshold: float) -> float:
		if value <= 0.0:
			return 0.0
		if threshold <= 0.0:
			threshold = 1.0
		if value <= threshold:
			return value
		return threshold * (log(value / threshold + 1.0) / log(10.0))

	## Linearly interpolates between a and b.
	func lerp(a: float, b: float, weight: float) -> float:
		return a + (b - a) * weight

	## Returns -1, 0, or 1 for the sign of the value.
	func sign(value: float) -> float:
		if value > 0.0:
			return 1.0
		if value < 0.0:
			return -1.0
		return 0.0

	## Aligns a value to the nearest step.
	func stepify(value: float, step: float) -> float:
		if step == 0.0:
			return value
		return round(value / step) * step

