extends Node

const CREDITS_SCENE := "res://scences/credits.tscn"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Escape
		get_tree().paused = false
		get_tree().change_scene_to_file(CREDITS_SCENE)
