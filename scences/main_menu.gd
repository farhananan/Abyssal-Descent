extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options

func _ready():
	main_buttons.visible = true
	options.visible = false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scences/lvl_menu.tscn")


func _on_options_pressed() -> void:
	print ("Options pressed")
	main_buttons.visible = false
	options.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()
