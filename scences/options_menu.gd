extends CanvasLayer

signal opened
signal closed

const MUSIC_BUS := "Music"

# Size settings: raise these to make the options screen bigger
const PANEL_WIDTH := 520
const MARGIN := 40
const SPACING := 20
const FONT_SIZE := 28
const BUTTON_HEIGHT := 52

# Where the panel area starts, as a fraction of screen height.
# 0.0 = top of the screen, 0.3 = 30% down. Raise it to move the panel lower.
const TOP_START := 0.23

var overlay: Control
var mode_option: OptionButton

func _ready() -> void:
	layer = 100
	_build_ui()
	overlay.hide()

func _build_ui() -> void:
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
	# Start the centering area lower so the panel stays below the title
	center.anchor_top = TOP_START
	center.offset_top = 0

	var panel := PanelContainer.new()
	# One theme on the panel makes the text bigger for everything inside it
	var big_theme := Theme.new()
	big_theme.default_font_size = FONT_SIZE
	panel.theme = big_theme
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	box.add_theme_constant_override("separation", SPACING)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_make_slider_row("Volume", 0.0, 1.0, _current_volume(), _on_volume_changed))
	box.add_child(_make_mode_row())
	box.add_child(_make_button("Back", close_menu))

func _make_button(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
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
	s.custom_minimum_size = Vector2(0, 32)
	s.value_changed.connect(callback)
	row.add_child(s)
	return row

func _make_mode_row() -> VBoxContainer:
	var row := VBoxContainer.new()
	var l := Label.new()
	l.text = "Display Mode"
	row.add_child(l)
	mode_option = OptionButton.new()
	mode_option.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	mode_option.add_item("Windowed")
	mode_option.add_item("Fullscreen")
	mode_option.item_selected.connect(_on_mode_selected)
	row.add_child(mode_option)
	return row

func _input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	_sync_mode_option()
	overlay.show()
	opened.emit()

func close_menu() -> void:
	overlay.hide()
	closed.emit()

func _sync_mode_option() -> void:
	# Match the dropdown to the real window state (e.g. if it was changed another way)
	var m := DisplayServer.window_get_mode()
	var is_full := m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	mode_option.select(1 if is_full else 0)

func _on_mode_selected(index: int) -> void:
	if index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _current_volume() -> float:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	return db_to_linear(AudioServer.get_bus_volume_db(bus))

func _on_volume_changed(v: float) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(v, 0.0001)))
	AudioServer.set_bus_mute(bus, v <= 0.001)
