extends CharacterBody2D

## Individual villager AI agent.
## State machine: IDLE → DECIDING → MOVING → ACTING → IDLE (loop)
## At each decision point the villager sends its context to AIQueue,
## which calls Ollama (Qwen3.5-4B) and returns a JSON action choice.

signal action_started(villager: Node, action_id: String, speech: String)
signal thought_updated(villager: Node, thought: String)

# ---------------------------------------------------------------------------
# Action vocabulary
# Each entry: duration (sim hours), location key, optional resource_gain /
# resource_cost dicts, and a human-readable desc for the LLM prompt.
# ---------------------------------------------------------------------------
const ACTIONS: Dictionary = {
	"gather_grain": {
		"duration": 2.0, "location": "fields",
		"resource_gain": {"grain": 3},
		"desc": "Gather grain from the fields"
	},
	"fetch_water": {
		"duration": 1.0, "location": "river",
		"resource_gain": {"water": 5},
		"desc": "Fetch water from the river"
	},
	"hunt": {
		"duration": 3.0, "location": "forest",
		"resource_gain": {"meat": 2},
		"desc": "Hunt for game in the forest"
	},
	"gather_herbs": {
		"duration": 2.0, "location": "forest",
		"resource_gain": {"herbs": 2},
		"desc": "Gather medicinal herbs in the forest"
	},
	"gather_clay": {
		"duration": 2.0, "location": "riverbank",
		"resource_gain": {"clay": 3},
		"desc": "Gather clay from the riverbank"
	},
	"gather_wood": {
		"duration": 2.0, "location": "forest",
		"resource_gain": {"wood": 3},
		"desc": "Collect firewood from the forest"
	},
	"craft_pot": {
		"duration": 4.0, "location": "workshop",
		"resource_cost": {"clay": 3},
		"desc": "Craft a clay storage pot"
	},
	"eat": {
		"duration": 0.5, "location": "hearth",
		"resource_cost": {"grain": 1},
		"desc": "Eat a meal at the hearth"
	},
	"drink": {
		"duration": 0.25, "location": "river",
		"resource_cost": {"water": 1},
		"desc": "Drink from the river"
	},
	"rest": {
		"duration": 2.0, "location": "shelter",
		"desc": "Rest and recover energy in the shelter"
	},
	"sleep": {
		"duration": 6.0, "location": "shelter",
		"desc": "Sleep for the night"
	},
	"talk_to": {
		"duration": 0.5, "location": "hearth",
		"desc": "Talk with a fellow villager at the hearth"
	},
	"tend_hearth": {
		"duration": 1.0, "location": "hearth",
		"resource_cost": {"wood": 1},
		"desc": "Tend the communal fire"
	},
	"perform_ritual": {
		"duration": 2.0, "location": "shrine",
		"desc": "Perform a spiritual ritual at the shrine"
	},
	"teach": {
		"duration": 2.0, "location": "hearth",
		"desc": "Teach a skill to another villager"
	},
	"idle": {
		"duration": 1.0, "location": "hearth",
		"desc": "Wander and observe village life"
	},
}

enum State { IDLE, DECIDING, MOVING, ACTING }

# ---------------------------------------------------------------------------
# Exported identity (set by World.gd when spawning)
# ---------------------------------------------------------------------------
@export var villager_name: String = "Villager"
@export var role:          String = "Farmer"
@export var personality:   String = "Hardworking, cautious"
@export var skills:        String = "Farming, basic tool use"
## Tint color shown on the villager polygon — set per-role by World.gd
@export var body_color:    Color  = Color(0.6, 0.4, 0.2)

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var _body:         Polygon2D = $Body
@onready var _name_label:   Label     = $NameLabel
@onready var _action_label: Label     = $ActionLabel

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var _state:                  State  = State.IDLE
var _current_action:         String = "idle"
var _action_hours_remaining: float  = 0.0
var _mood:                   String = "neutral"
var _last_thought:           String = ""
var _last_speech:            String = ""

# Memory
var _short_term: Array[String] = []  # Rolling log of personal experiences
var _long_term:  Array[String] = []  # Stable beliefs (populated over time)
const SHORT_TERM_MAX: int = 12

# Unique ID for AIQueue tracking
var _uid: int = 0
static var _next_uid: int = 0


func _ready() -> void:
	_uid = _next_uid
	_next_uid += 1

	_body.color       = body_color
	_name_label.text  = villager_name
	_action_label.text = "waking up..."

	WorldState.register_villager(self)

	# Stagger first decision so all 12 villagers don't pile into the queue
	# simultaneously on frame 1.  Spread over 0–5 real seconds.
	var delay := randf_range(0.0, 5.0)
	await get_tree().create_timer(delay).timeout
	_request_decision()


func _process(delta: float) -> void:
	if _state != State.ACTING:
		return
	var sim_delta: float = delta / WorldState.seconds_per_sim_hour
	_action_hours_remaining -= sim_delta
	if _action_hours_remaining <= 0.0:
		_finish_action()


## One-line summary used by WorldState and HUD.
func get_status_summary() -> String:
	return "%s (%s) — %s [%s]" % [
		villager_name, role,
		_current_action.replace("_", " "),
		_mood
	]


func get_last_thought() -> String:
	return _last_thought


func get_last_speech() -> String:
	return _last_speech


# ---------------------------------------------------------------------------
# Decision cycle
# ---------------------------------------------------------------------------

func _request_decision() -> void:
	_state = State.DECIDING
	_action_label.text = "thinking…"
	AIQueue.enqueue(_uid, _build_messages(), _on_ai_response)


func _build_messages() -> Array:
	# Build action list for the prompt
	var action_lines: Array[String] = []
	for id in ACTIONS:
		action_lines.append('  "%s": %s' % [id, ACTIONS[id]["desc"]])

	var system_prompt: String = (
		"You are %s, a %s in a small Bronze Age tribe of about 12 people.\n" +
		"Personality: %s\n" +
		"Skills: %s\n\n" +
		"Choose your next action. Respond with ONLY a JSON object — " +
		"no markdown fences, no text outside the JSON.\n\n" +
		"Available actions:\n%s\n\n" +
		"Response format (strict JSON, no extra keys):\n" +
		"{\n" +
		'  "action": "<one of the action ids above>",\n' +
		'  "target": "<optional: another villager name, resource, or empty>",\n' +
		'  "speech": "<what you say aloud right now — 1 sentence or empty>",\n' +
		'  "mood": "<one word emotional state>",\n' +
		'  "reason": "<one sentence explaining your choice>"\n' +
		"}"
	) % [villager_name, role, personality, skills, "\n".join(action_lines)]

	# Recent tribal events
	var recent: Array[Dictionary] = WorldState.get_recent_events(8)
	var event_lines: Array[String] = []
	for e in recent:
		var line: String = "- %s: %s" % [e["actor"], e["action"]]
		if not e["detail"].is_empty():
			line += " (%s)" % e["detail"]
		event_lines.append(line)

	var mem_text: String = (
		"\n".join(_short_term) if not _short_term.is_empty()
		else "Nothing notable yet."
	)

	var user_message: String = (
		"Current time: %s\n" +
		"Tribe resources: %s\n\n" +
		"Recent tribal events:\n%s\n\n" +
		"Your recent memories:\n%s\n\n" +
		"Current mood: %s\n\n" +
		"What do you do next?"
	) % [
		WorldState.time_string(),
		WorldState.resource_summary(),
		"\n".join(event_lines) if not event_lines.is_empty() else "None yet.",
		mem_text,
		_mood,
	]

	return [
		{"role": "system", "content": system_prompt},
		{"role": "user",   "content": user_message},
	]


func _on_ai_response(response: Dictionary) -> void:
	var content:  String = ""
	var thinking: String = ""

	if response.has("message"):
		var msg: Dictionary = response["message"]
		content  = msg.get("content",  "")
		thinking = msg.get("thinking", "")

		# Fallback: some Ollama builds embed thinking inside <think> tags
		if thinking.is_empty() and "<think>" in content:
			var ts: int = content.find("<think>") + 7
			var te: int = content.find("</think>")
			if te > ts:
				thinking = content.substr(ts, te - ts).strip_edges()
				content  = content.substr(te + 8).strip_edges()

	_last_thought = thinking

	var action_data := _parse_action(content)
	_start_action(action_data)

	# Show thinking chain if available, otherwise show the reason from the action
	var thought_display: String = thinking if not thinking.is_empty() \
		else action_data.get("reason", "")
	if not thought_display.is_empty():
		thought_updated.emit(self, thought_display)


func _parse_action(content: String) -> Dictionary:
	var clean := content.strip_edges()

	# Strip markdown fences if the model ignored instructions
	if clean.begins_with("```"):
		var first_nl := clean.find("\n")
		var last_fence := clean.rfind("```")
		if first_nl != -1 and last_fence > first_nl:
			clean = clean.substr(first_nl + 1, last_fence - first_nl - 1).strip_edges()

	var json := JSON.new()
	if json.parse(clean) == OK:
		var data = json.get_data()
		if data is Dictionary and ACTIONS.has(data.get("action", "")):
			return data

	push_warning(
		"Villager %s: could not parse AI response — falling back to idle.\nContent: %s"
		% [villager_name, content]
	)
	return {"action": "idle", "speech": "", "mood": "confused", "reason": "Could not decide."}


# ---------------------------------------------------------------------------
# Action execution
# ---------------------------------------------------------------------------

func _start_action(data: Dictionary) -> void:
	var chosen: String      = data.get("action", "idle")
	_last_speech             = data.get("speech", "")
	_mood                    = data.get("mood", "neutral")
	var reason: String       = data.get("reason", "")

	var action_def: Dictionary = ACTIONS[chosen]

	# Check resource cost; fall back to idle if insufficient
	var cost: Dictionary = action_def.get("resource_cost", {})
	for res in cost:
		if WorldState.resources.get(res, 0) < cost[res]:
			chosen     = "idle"
			action_def = ACTIONS["idle"]
			cost       = {}
			break

	_current_action = chosen
	_action_hours_remaining = action_def.get("duration", 1.0)

	# Deduct costs
	for res in cost:
		WorldState.change_resource(res, -cost[res])

	# Update label
	_action_label.text = _current_action.replace("_", " ")

	# Log to world
	var log_detail := '"%s"' % _last_speech if not _last_speech.is_empty() else ""
	WorldState.log_event(villager_name, _current_action, log_detail)

	# Emit signals for HUD
	if not _last_speech.is_empty():
		action_started.emit(self, _current_action, _last_speech)

	# Commit to short-term memory
	_add_memory(
		"Chose to %s. %s" % [_current_action.replace("_", " "), reason]
	)

	# Move to the action location
	var loc_name: String   = action_def.get("location", "hearth")
	var target: Vector2    = WorldState.locations.get(loc_name, global_position)
	# Add a small random offset so villagers at the same location don't stack
	target += Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	_move_to(target)


func _move_to(target: Vector2) -> void:
	_state = State.MOVING
	var dist: float     = global_position.distance_to(target)
	var travel: float   = clampf(dist / 80.0, 0.3, 6.0)  # seconds
	var tween           = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target, travel)
	tween.tween_callback(func() -> void: _state = State.ACTING)


func _finish_action() -> void:
	var action_def: Dictionary = ACTIONS.get(_current_action, {})

	# Apply resource gains
	var gain: Dictionary = action_def.get("resource_gain", {})
	for res in gain:
		WorldState.change_resource(res, gain[res])
		_add_memory("Gathered %d %s." % [gain[res], res])

	_state = State.IDLE
	_request_decision()


func _add_memory(text: String) -> void:
	var entry: String = "[%s] %s" % [WorldState.time_string(), text]
	_short_term.append(entry)
	if _short_term.size() > SHORT_TERM_MAX:
		_short_term.pop_front()
