extends Control

## HUD controller.
## Manages on-screen UI elements such as the dialogue box.

@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var dialogue_text: RichTextLabel = $DialogueBox/DialogueText


func show_dialogue(speaker: String, text: String) -> void:
	dialogue_text.text = "[b]%s[/b]\n%s" % [speaker, text]
	dialogue_box.show()


func hide_dialogue() -> void:
	dialogue_box.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and dialogue_box.visible:
		hide_dialogue()
