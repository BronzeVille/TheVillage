extends Node

## Simulation clock — drives time forward continuously.
## Added as a child of World. Reads speed from WorldState.seconds_per_sim_hour.

signal hour_passed(hour: float)
signal day_passed(day: int)

var _accumulator: float = 0.0


func _process(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= WorldState.seconds_per_sim_hour:
		_accumulator -= WorldState.seconds_per_sim_hour
		_advance_hour()


func _advance_hour() -> void:
	WorldState.sim_hour += 1.0
	if WorldState.sim_hour >= 24.0:
		WorldState.sim_hour -= 24.0
		WorldState.sim_day += 1
		WorldState.log_event("World", "new_day", "Day %d begins" % WorldState.sim_day)
		day_passed.emit(WorldState.sim_day)
	hour_passed.emit(WorldState.sim_hour)
