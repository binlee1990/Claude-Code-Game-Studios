class_name DebugConsole
extends Node

const SCROLLBACK_LIMIT := 500
const HISTORY_LIMIT := 50
const WATCH_COLOR := "[color=cyan]"

var canvas_layer: CanvasLayer
var root_control: Control
var line_edit: LineEdit
var output_label: RichTextLabel
var _commands := {}
var _output_buffer := []
var _history := []
var _history_index := -1
var _previous_focus: Control
var _paused_by_console := false
var _watching_prefixes := {}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_register_commands()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_QUOTELEFT:
			toggle()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if canvas_layer == null:
		return
	if canvas_layer.visible:
		close()
	else:
		open()


func open() -> void:
	if canvas_layer == null:
		return
	_previous_focus = get_viewport().gui_get_focus_owner()
	_paused_by_console = not get_tree().paused
	if _paused_by_console:
		get_tree().paused = true
	canvas_layer.visible = true
	line_edit.grab_focus()


func close() -> void:
	if canvas_layer == null:
		return
	_unwatch_all()
	canvas_layer.visible = false
	if _paused_by_console:
		get_tree().paused = false
	_paused_by_console = false
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	else:
		line_edit.release_focus()


func execute_line(command_line: String) -> Array:
	var line := command_line.strip_edges()
	if line.is_empty():
		return []
	_append_line("[color=gray]> %s[/color]" % line)
	var tokens := _split_command(line)
	if tokens.is_empty():
		return []
	var command := str(tokens[0])
	var args := tokens.slice(1)
	if not _commands.has(command):
		var unknown := "[color=red][ERROR] Unknown command: '%s'. Type 'help' for a list.[/color]" % command
		_append_line(unknown)
		return [unknown]
	var handler: Callable = _commands[command]["handler"]
	if not handler.is_valid():
		var invalid := "[color=red][ERROR] Command handler unavailable: %s[/color]" % command
		_append_line(invalid)
		return [invalid]
	_record_history(line)
	var lines: Array = handler.call(args)
	for output in lines:
		_append_line(str(output))
	return lines


func get_output_lines() -> Array:
	return _output_buffer.duplicate()


func _build_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	canvas_layer.visible = false
	add_child(canvas_layer)
	root_control = Control.new()
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(root_control)
	output_label = RichTextLabel.new()
	output_label.bbcode_enabled = true
	output_label.scroll_following = true
	output_label.selection_enabled = true
	output_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	output_label.offset_bottom = -36.0
	root_control.add_child(output_label)
	line_edit = LineEdit.new()
	line_edit.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	line_edit.offset_top = -32.0
	line_edit.placeholder_text = "command"
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.gui_input.connect(_on_line_edit_gui_input)
	root_control.add_child(line_edit)


func _register_commands() -> void:
	_commands = {
		"res": {"handler": Callable(self, "_cmd_res"), "help": "res list"},
		"event": {"handler": Callable(self, "_cmd_event"), "help": "event watch <prefix> | event unwatch <prefix>"},
		"config": {"handler": Callable(self, "_cmd_config"), "help": "config list | config show <table> | config get <table> <id> | config reload [<table>]"},
		"modifier": {"handler": Callable(self, "_cmd_modifier"), "help": "modifier list | modifier breakdown <target>"},
		"attr": {"handler": Callable(self, "_cmd_attr"), "help": "attr [<entity_id>]"},
		"prod": {"handler": Callable(self, "_cmd_prod"), "help": "prod breakdown <resource_id>"},
		"time": {"handler": Callable(self, "_cmd_time"), "help": "time status | time freeze | time unfreeze | time speed <N> | time speed reset"},
		"save": {"handler": Callable(self, "_cmd_save"), "help": "save now | save dump [<namespace>]"},
		"help": {"handler": Callable(self, "_cmd_help"), "help": "help [<command>]"},
		"clear": {"handler": Callable(self, "_cmd_clear"), "help": "clear"},
	}


func _cmd_res(args: Array) -> Array:
	if args.size() != 1 or str(args[0]) != "list":
		return [_usage("res list")]
	var host := ResourceSystemHost.get_instance()
	if host == null:
		return [_warn("System not available: ResourceSystem")]
	var system := host.get_service()
	var lines := []
	for id in system.get_all_ids():
		var def: Dictionary = system.get_definition(str(id))
		lines.append("%s  %s / %s  [%s]" % [id, system.get_value(str(id)).as_string(), system.get_max(str(id)).as_string(), str(def.get("category", ""))])
	return lines


func _cmd_event(args: Array) -> Array:
	if args.size() == 1 and str(args[0]) == "watch":
		return [_error("Prefix must not be empty. Usage: event watch <prefix>")]
	if args.size() < 2:
		return [_usage("event watch <prefix> | event unwatch <prefix>")]
	var action := str(args[0])
	var prefix := str(args[1]).strip_edges()
	if prefix.is_empty():
		return [_error("Prefix must not be empty. Usage: event watch <prefix>")]
	var bus := EventBus.get_instance()
	if bus == null:
		return [_warn("System not available: EventBus")]
	if action == "watch":
		if _watching_prefixes.has(prefix):
			return ["[color=yellow][WARN] Already watching '%s'. No-op.[/color]" % prefix]
		var callable := Callable(self, "_on_watched_event")
		_watching_prefixes[prefix] = callable
		bus.subscribe_pattern(prefix, callable)
		return ["Watching '%s'." % prefix]
	if action == "unwatch":
		if _watching_prefixes.has(prefix):
			bus.unsubscribe_pattern(prefix, _watching_prefixes[prefix])
			_watching_prefixes.erase(prefix)
		return ["Stopped watching '%s'." % prefix]
	return [_usage("event watch <prefix> | event unwatch <prefix>")]


func _cmd_config(args: Array) -> Array:
	var data_config := _get_data_config()
	if data_config == null:
		return [_warn("System not available: DataConfigHost")]
	if args.size() == 1 and str(args[0]) == "list":
		if data_config.has_method("get_table_names"):
			return data_config.call("get_table_names")
		return [_warn("DataConfig does not expose get_table_names")]
	if args.size() == 2 and str(args[0]) == "show":
		var table: Dictionary = data_config.call("get_all", str(args[1]))
		var lines := []
		for id in table.keys():
			lines.append(JSON.stringify(table[id]))
		return lines
	if args.size() == 3 and str(args[0]) == "get":
		var record = data_config.call("get_record", str(args[1]), str(args[2]))
		return [JSON.stringify(record)]
	if args.size() >= 1 and str(args[0]) == "reload":
		if args.size() == 2:
			data_config.call("reload_table", str(args[1]))
			return ["Reloaded table: %s" % str(args[1])]
		data_config.call("reload_all")
		return ["Reloaded all tables."]
	return [_usage("config list | config show <table> | config get <table> <id> | config reload [<table>]")]


func _cmd_modifier(args: Array) -> Array:
	var engine := _get_modifier_engine()
	if engine == null:
		return [_warn("System not available: ModifierEngine")]
	if args.size() == 1 and str(args[0]) == "list":
		return engine.get_all_targets()
	if args.size() == 2 and str(args[0]) == "breakdown":
		var breakdown: Dictionary = engine.get_breakdown(str(args[1]))
		var lines := ["add_sum: %s" % str(breakdown.get("add_sum", 0.0))]
		var pools: Dictionary = breakdown.get("pools", {})
		for pool in pools.keys():
			lines.append("pool[%s]: x%s" % [pool, str(pools[pool])])
		lines.append("final_mult: %s" % str(breakdown.get("final_mult", 1.0)))
		return lines
	return [_usage("modifier list | modifier breakdown <target>")]


func _cmd_attr(args: Array) -> Array:
	var host := AttributeSystemHost.get_instance()
	if host == null:
		return [_warn("System not available: AttributeSystemHost")]
	var attrs := host.get_service()
	if args.is_empty():
		return attrs.get_all_entity_ids()
	var entity_id := str(args[0])
	var base: Dictionary = attrs.get_attribute_set(entity_id)
	var final: Dictionary = attrs.get_final_set(entity_id)
	var lines := []
	for attr_id in base.keys():
		var suffix := ""
		if not base[attr_id].equals(final[attr_id]) and not base[attr_id].is_zero():
			var pct: float = (final[attr_id].to_float() / base[attr_id].to_float() - 1.0) * 100.0
			suffix = " (+%.2f%%)" % pct
		lines.append("%s  base=%s  final=%s%s" % [attr_id, base[attr_id].as_string(), final[attr_id].as_string(), suffix])
	return lines


func _cmd_prod(args: Array) -> Array:
	if args.size() != 2 or str(args[0]) != "breakdown":
		return [_usage("prod breakdown <resource_id>")]
	var host := OutputMultiplierSystemHost.get_instance()
	if host == null:
		return [_warn("System not available: OutputMultiplierSystemHost")]
	var breakdown := host.get_service().get_breakdown(str(args[1]))
	var lines := [
		"base_rate: %s" % str(breakdown.get("base_rate", 0.0)),
		"add_sum: %s" % str(breakdown.get("add_sum", 0.0)),
	]
	var pools: Dictionary = breakdown.get("pools", {})
	for pool in pools.keys():
		lines.append("pool[%s]: x%s" % [pool, str(pools[pool])])
	lines.append("final_mult: %s" % str(breakdown.get("final_multiplier", 0.0)))
	lines.append("rate_per_second: %s" % str(breakdown.get("rate_per_second", 0.0)))
	lines.append("fractional_carry: %s" % str(breakdown.get("fractional_carry", 0.0)))
	return lines


func _cmd_time(args: Array) -> Array:
	var time := TimeManager.get_instance()
	if time == null:
		return [_warn("System not available: TimeManager")]
	if args.size() == 1 and str(args[0]) == "status":
		return [
			"real_time: %s" % str(time.get_real_time()),
			"game_time: %s" % str(time.get_game_time()),
			"effective_speed: %s" % str(time.get_effective_speed()),
			"frozen: %s" % str(time.collect_save_data().get("frozen", false)),
		]
	if args.size() == 1 and str(args[0]) == "freeze":
		time.freeze()
		return ["Time frozen."]
	if args.size() == 1 and str(args[0]) == "unfreeze":
		time.unfreeze()
		return ["Time unfrozen."]
	if args.size() == 2 and str(args[0]) == "speed":
		if str(args[1]) == "reset":
			time.remove_speed_source("debug_console")
			return ["Time speed reset."]
		var value := str(args[1]).to_float()
		if value < 0.1 or value > 100.0:
			return [_error("Speed must be in range [0.1, 100.0]. Got: %s." % str(args[1]))]
		time.add_speed_source("debug_console", value)
		return ["Time speed set: %s" % str(value)]
	return [_usage("time status | time freeze | time unfreeze | time speed <N> | time speed reset")]


func _cmd_save(args: Array) -> Array:
	var manager: SaveManager = SaveManager.get_instance()
	if manager == null:
		return [_warn("System not available: SaveManager")]
	if args.size() == 1 and str(args[0]) == "now":
		manager.save_game()
		return ["Save triggered."]
	if args.size() >= 1 and str(args[0]) == "dump":
		var data: Dictionary = manager.collect_save_data()
		if args.size() == 2:
			return [JSON.stringify(data.get("systems", {}).get(str(args[1]), {}), "\t")]
		return [JSON.stringify(data, "\t")]
	return [_usage("save now | save dump [<namespace>]")]


func _cmd_help(args: Array) -> Array:
	if args.size() == 1:
		var name := str(args[0])
		if _commands.has(name):
			return [str(_commands[name]["help"])]
		return [_error("Unknown command: '%s'." % name)]
	var names := _commands.keys()
	names.sort()
	var lines := []
	for name in names:
		lines.append("%s - %s" % [name, str(_commands[name]["help"])])
	return lines


func _cmd_clear(_args: Array) -> Array:
	_output_buffer.clear()
	if output_label != null:
		output_label.clear()
	return []


func _on_text_submitted(text: String) -> void:
	line_edit.clear()
	execute_line(text)


func _on_line_edit_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed:
		return
	if key_event.keycode == KEY_UP:
		_step_history(-1)
		line_edit.accept_event()
	elif key_event.keycode == KEY_DOWN:
		_step_history(1)
		line_edit.accept_event()


func _step_history(direction: int) -> void:
	if _history.is_empty():
		return
	_history_index = clamp(_history_index + direction, 0, _history.size() - 1)
	line_edit.text = str(_history[_history_index])
	line_edit.caret_column = line_edit.text.length()


func _record_history(line: String) -> void:
	_history.append(line)
	if _history.size() > HISTORY_LIMIT:
		_history.pop_front()
	_history_index = _history.size()


func _on_watched_event(event_name: String, payload: Dictionary) -> void:
	_append_line("%s[WATCH] %s -> %s[/color]" % [WATCH_COLOR, event_name, str(payload)])


func _unwatch_all() -> void:
	var bus := EventBus.get_instance()
	if bus == null:
		_watching_prefixes.clear()
		return
	for prefix in _watching_prefixes.keys():
		bus.unsubscribe_pattern(str(prefix), _watching_prefixes[prefix])
	_watching_prefixes.clear()


func _append_line(line: String) -> void:
	_output_buffer.append(line)
	if _output_buffer.size() > SCROLLBACK_LIMIT:
		_output_buffer.pop_front()
	if output_label != null:
		output_label.clear()
		for entry in _output_buffer:
			output_label.append_text("[%s] %s\n" % [Time.get_time_string_from_system(), str(entry)])


func _split_command(line: String) -> Array:
	var result := []
	var current := ""
	var in_quote := false
	for i in range(line.length()):
		var ch := line.substr(i, 1)
		if ch == "\"":
			in_quote = not in_quote
			continue
		if ch == " " and not in_quote:
			if not current.is_empty():
				result.append(current)
				current = ""
			continue
		current += ch
	if not current.is_empty():
		result.append(current)
	return result


func _get_data_config() -> Object:
	var host := DataConfigHost.get_instance()
	if host == null:
		return null
	return host.get_service()


func _get_modifier_engine() -> ModifierEngine:
	var output_host := OutputMultiplierSystemHost.get_instance()
	if output_host != null:
		return output_host.get_service().modifier_engine
	var attr_host := AttributeSystemHost.get_instance()
	if attr_host != null:
		return attr_host.get_service().modifier_engine
	return null


func _usage(text: String) -> String:
	return "[color=red][ERROR] Usage: %s[/color]" % text


func _error(text: String) -> String:
	return "[color=red][ERROR] %s[/color]" % text


func _warn(text: String) -> String:
	return "[color=yellow][WARN] %s[/color]" % text
