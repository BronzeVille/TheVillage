extends CharacterBody2D

## Player character controller.
## Handles input, movement, and interaction.

const SPEED: float = 100.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
