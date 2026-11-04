extends CanvasLayer

# Remembered for the whole play session, even across levels
static var brightness := 1.0

var dim: ColorRect
var overlay: Control
var icon_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep working while the game is paused
	layer = 100
	_build_ui()
	overlay.hide()

func _build_ui() -> void:
	# Brightness dimmer: above the game, below the menu
	var dim_layer := CanvasLayer.new()
	dim_layer.layer = 90
	add_child(dim_layer)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 1.0 - brightness)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Small button in the top-right corner
	icon_button = Button.new()
	icon_button.text = "II"
	icon_button.tooltip_text = "Pause"
	icon_button.focus_mode = Control.FOCUS_NONE
	icon_button.custom_minimum_size = Vector2(32, 32)
	icon_button.pressed.connect(open_menu)
	add_child(icon_button)
	icon_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 8)

	# Pause screen
	overlay = Control.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(280, 0)
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_make_button("Resume", close_menu))
	box.add_child(_make_slider_row("Volume", 0.0, 1.0, _current_volume(), _on_volume_changed))
	box.add_child(_make_slider_row("Brightness", 0.3, 1.0, brightness, _on_brightness_changed))
	box.add_child(_make_button("Main Menu", _on_main_menu))
	box.add_child(_make_button("Quit Game", _on_quit))

func _make_button(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(callback)
	return b

func _make_slider_row(label: String, min_v: float, max_v: float, start: float, callback: Callable) -> VBoxContainer:
	var row := VBoxContainer.new()
	var l := Label.new()
	l.text = label
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = 0.01
	s.value = start
	s.value_changed.connect(callback)
	row.add_child(s)
	return row

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	get_tree().paused = true
	overlay.show()
	icon_button.hide()

func close_menu() -> void:
	get_tree().paused = false
	overlay.hide()
	icon_button.show()

func _current_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(0))

func _on_volume_changed(v: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))
	AudioServer.set_bus_mute(0, v <= 0.001)

func _on_brightness_changed(v: float) -> void:
	brightness = v
	dim.color = Color(0, 0, 0, 1.0 - v)

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scences/main_menu.tscn")

func _on_quit() -> void:
	get_tree().quit()
