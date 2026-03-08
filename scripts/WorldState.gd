extends Node

## Global simulation state — autoloaded as "WorldState".
## Single source of truth for tribe resources, time, locations, and events.

signal resource_changed(resource_name: String, new_amount: int)
signal world_event_occurred(event: Dictionary)

# Simulation time
var sim_hour: float = 6.0  # Start at 6am
var sim_day: int = 1

## Real seconds per simulated hour. Adjust to speed up/slow down the sim.
var seconds_per_sim_hour: float = 20.0

# Tribal resource pool
var resources: Dictionary = {
	"grain": 20,
	"meat":  5,
	"water": 30,
	"clay":  10,
	"wood":  15,
	"herbs": 8,
}

## Named world locations mapped to 2D positions.
## Populated by World.gd on _ready.
var locations: Dictionary = {}

# Shared event log (tribal memory — visible to all villagers)
var event_log: Array[Dictionary] = []
const MAX_LOG_SIZE: int = 200

# Registered villager nodes
var villagers: Array[Node] = []


func register_villager(v: Node) -> void:
	villagers.append(v)


## Record an event into the shared log and emit world_event_occurred.
func log_event(actor: String, action: String, detail: String = "") -> void:
	var entry := {
		"day":    sim_day,
		"hour":   sim_hour,
		"actor":  actor,
		"action": action,
		"detail": detail,
	}
	event_log.append(entry)
	if event_log.size() > MAX_LOG_SIZE:
		event_log.pop_front()
	world_event_occurred.emit(entry)


## Modify a resource by delta (clamped to >= 0).
func change_resource(res_name: String, delta: int) -> void:
	resources[res_name] = max(0, resources.get(res_name, 0) + delta)
	resource_changed.emit(res_name, resources[res_name])


## Return the last `count` events from the log.
func get_recent_events(count: int = 10) -> Array[Dictionary]:
	var start := max(0, event_log.size() - count)
	return event_log.slice(start)


## Human-readable resource summary for LLM prompts.
func resource_summary() -> String:
	var parts: Array[String] = []
	for key in resources:
		parts.append("%s: %d" % [key.capitalize(), resources[key]])
	return ", ".join(parts)


## Human-readable time string.
func time_string() -> String:
	var h: int = int(sim_hour) % 24
	return "Day %d, %02d:00" % [sim_day, h]
