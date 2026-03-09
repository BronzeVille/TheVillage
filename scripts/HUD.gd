extends Control

## Observer HUD — built entirely in code.
## Layout (1280 × 720):
##   Top bar   : full width, 40 px    — time, queue depth
##   Left panel: 220 × 680, y=40      — tribe resources
##   Right panel: 220 × 680, y=40     — event log (scrolling)
##   Bottom panel: 840 × 160, centred — inner monologue (thought + speech)
##   Centre area is left clear for the world view.

# ---------------------------------------------------------------------------
# Node references (created in _ready)
# ---------------------------------------------------------------------------
var _time_label:     Label
var _queue_label:    Label
var _resource_box:   VBoxContainer
var _event_log:      VBoxContainer
var _event_scroll:   ScrollContainer
var _thinker_label:  Label
var _thought_text:   RichTextLabel
var _speech_label:   RichTextLabel

const MAX_EVENT_ROWS: int = 30
const PANEL_BG: Color = Color(0.08, 0.06, 0.04, 0.82)
const TEXT_COLOR: Color = Color(0.92, 0.86, 0.72)
const ACCENT: Color = Color(0.85, 0.72, 0.35)
const THOUGHT_COLOR: Color = Color(0.72, 0.86, 0.92)


func _ready() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0
	_build_ui()

	WorldState.world_event_occurred.connect(_on_world_event)
	refresh_resources()


# ---------------------------------------------------------------------------
# Public API (called by World.gd)
# ---------------------------------------------------------------------------

## Show a villager's speech in the bottom panel.
func show_speech(speaker: String, text: String) -> void:
	_speech_label.text = '[color=#%s]%s[/color] says: "%s"' % [
		ACCENT.to_html(false), speaker, text
	]


## Show a villager's inner thought in the bottom panel.
func show_thought(thinker: String, thought: String) -> void:
	_thinker_label.text = "%s is thinking…" % thinker
	# Truncate very long thinking chains for display
	var display: String = thought if thought.length() <= 800 else thought.substr(0, 800) + "…"
	_thought_text.text  = display


## Refresh the resource panel (called each sim hour).
func refresh_resources() -> void:
	for child in _resource_box.get_children():
		child.queue_free()

	var header: Label = _make_label("RESOURCES", ACCENT, true)
	_resource_box.add_child(header)
	_add_separator(_resource_box)

	for key in WorldState.resources:
		var amount: int = WorldState.resources[key]
		var row: Label  = _make_label("%s  %d" % [key.capitalize(), amount], TEXT_COLOR)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_resource_box.add_child(row)

	_add_separator(_resource_box)
	var time_row: Label = _make_label(WorldState.time_string(), ACCENT)
	_resource_box.add_child(time_row)


# ---------------------------------------------------------------------------
# Private — signal handlers
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _time_label:
		_time_label.text = WorldState.time_string()
	if _queue_label:
		var depth: int = AIQueue.queue_depth
		_queue_label.text = (
			"AI queue: %d waiting" % depth if depth > 0 else "AI queue: idle"
		)


func _on_world_event(event: Dictionary) -> void:
	var actor:  String = event.get("actor",  "?")
	var action: String = event.get("action", "?")
	var detail: String = event.get("detail", "")

	var line: String = "[color=#%s]%s[/color] → %s" % [
		ACCENT.to_html(false), actor, action.replace("_", " ")
	]
	if not detail.is_empty():
		line += "  [color=#aaaaaa]%s[/color]" % detail

	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content    = true
	label.text           = line
	label.add_theme_color_override("default_color", TEXT_COLOR)
	label.add_theme_font_size_override("normal_font_size", 11)
	_event_log.add_child(label)

	# Trim old entries — use free() not queue_free() so child count updates immediately
	while _event_log.get_child_count() > MAX_EVENT_ROWS:
		_event_log.get_child(0).free()

	# Auto-scroll to bottom
	await get_tree().process_frame
	_event_scroll.scroll_vertical = _event_scroll.get_v_scroll_bar().max_value


# ---------------------------------------------------------------------------
# UI construction helpers
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_build_top_bar()
	_build_left_panel()
	_build_right_panel()
	_build_bottom_panel()


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	_style_panel(bar)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 40)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	var title: Label = _make_label("THE VILLAGE", ACCENT, true)
	title.custom_minimum_size = Vector2(300, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(title)

	_time_label = _make_label("", TEXT_COLOR)
	_time_label.custom_minimum_size = Vector2(300, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_time_label)

	_queue_label = _make_label("AI queue: idle", TEXT_COLOR)
	_queue_label.custom_minimum_size = Vector2(300, 0)
	_queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(_queue_label)


func _build_left_panel() -> void:
	var panel := PanelContainer.new()
	_style_panel(panel)
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 1.0
	panel.anchor_left   = 0.0
	panel.anchor_right  = 0.0
	panel.offset_top    = 40
	panel.offset_right  = 210
	panel.offset_bottom = 0
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	_resource_box = VBoxContainer.new()
	_resource_box.custom_minimum_size = Vector2(190, 0)
	scroll.add_child(_resource_box)


func _build_right_panel() -> void:
	var panel := PanelContainer.new()
	_style_panel(panel)
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 1.0
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.offset_top    = 40
	panel.offset_left   = -210
	panel.offset_right  = 0
	panel.offset_bottom = 0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var header: Label = _make_label("EVENT LOG", ACCENT, true)
	vbox.add_child(header)
	_add_separator(vbox)

	_event_scroll = ScrollContainer.new()
	_event_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_event_scroll)

	_event_log = VBoxContainer.new()
	_event_log.custom_minimum_size = Vector2(185, 0)
	_event_scroll.add_child(_event_log)


func _build_bottom_panel() -> void:
	var panel := PanelContainer.new()
	_style_panel(panel)
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.anchor_left   = 0.0
	panel.anchor_right  = 1.0
	panel.offset_top    = -160
	panel.offset_bottom = 0
	panel.offset_left   = 210
	panel.offset_right  = -210
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_thinker_label = _make_label("Waiting for first thought…", ACCENT, true)
	vbox.add_child(_thinker_label)

	_add_separator(vbox)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_thought_text              = RichTextLabel.new()
	_thought_text.bbcode_enabled = false
	_thought_text.fit_content    = false
	_thought_text.custom_minimum_size = Vector2(0, 80)
	_thought_text.add_theme_color_override("default_color", THOUGHT_COLOR)
	_thought_text.add_theme_font_size_override("normal_font_size", 12)
	scroll.add_child(_thought_text)

	_add_separator(vbox)

	_speech_label              = RichTextLabel.new()
	_speech_label.bbcode_enabled = true
	_speech_label.fit_content    = true
	_speech_label.custom_minimum_size = Vector2(0, 28)
	_speech_label.add_theme_color_override("default_color", TEXT_COLOR)
	_speech_label.add_theme_font_size_override("normal_font_size", 13)
	_speech_label.text = "(silence)"
	vbox.add_child(_speech_label)


# ---------------------------------------------------------------------------
# Micro-helpers
# ---------------------------------------------------------------------------

func _make_label(text: String, color: Color, bold: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 13 if bold else 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.4, 0.35, 0.2, 0.6))
	parent.add_child(sep)


func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color            = PANEL_BG
	style.border_color        = Color(0.4, 0.35, 0.2, 0.5)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
