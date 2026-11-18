extends Node

const CONTROLS_TEXT := "Move: A / D or Left / Right Arrow\nJump: W or Up Arrow (tap twice to double jump)\nAttack: J\nDash: C"

func _ready() -> void:
	# Short wait so the level is visible before the box appears
	await get_tree().create_timer(0.4).timeout
	Hints.show_once("controls", "Controls", CONTROLS_TEXT)
