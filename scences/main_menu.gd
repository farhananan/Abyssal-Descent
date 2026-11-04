extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options_menu = $OptionsMenu

func _ready() -> void:
	# Button2 is the options button
	$MainButtons/Button2.pressed.connect(options_menu.open_menu)

	# Hide the buttons while options is open, show them again when it closes
	options_menu.opened.connect(_set_buttons_visible.bind(false))
	options_menu.closed.connect(_set_buttons_visible.bind(true))

func _set_buttons_visible(show_buttons: bool) -> void:
	main_buttons.visible = show_buttons

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scences/lvl_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
