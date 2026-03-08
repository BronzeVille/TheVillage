extends CharacterBody2D

## Base NPC controller.
## Override dialogue and behaviour in derived scenes.

@export var npc_name: String = "Villager"
@export var dialogue: Array[String] = ["Hello, traveller!"]

var _dialogue_index: int = 0


func interact() -> void:
	HUD.show_dialogue(npc_name, dialogue[_dialogue_index])
	_dialogue_index = (_dialogue_index + 1) % dialogue.size()
