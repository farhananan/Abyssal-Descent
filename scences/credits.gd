extends Control

const GAME_TITLE := "Abyssal Descent"
const SCROLL_SPEED := 60.0        # pixels per second; raise it to scroll faster
const FAST_MULTIPLIER := 4.0      # hold Space/Enter or Down to speed up
const MAIN_MENU_SCENE := "res://scences/main_menu.tscn"

# [what, who]
const CREDITS := [
	["Art", "Jiwan"],
	["Level 1", "Ayham"],
	["Level 2", "Fahan"],
	["Level 3", "Kosta"],
	["Home Menu", "Kosta"],
	["Level Menu", "Kosta"],
	["Escape Menu", "Ayham"],
	["Final Screen", "Jiwan"],
	["Code", "Everyone"],
]

var content: VBoxContainer
var started := false
var leaving := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	# Wait one frame so the layout has a size, then start the text just below the screen
	await get_tree().process_frame
	content.position.y = size.y
	started = true

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.07)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Clips the scrolling text to the screen
	var clip := Control.new()
	clip.clip_contents = true
	add_child(clip)
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	clip.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	content.add_child(_label(GAME_TITLE, 56))
	content.add_child(_label("Credits", 36, Color(0.7, 0.7, 0.8)))
	content.add_child(_spacer(40))

	for entry in CREDITS:
		content.add_child(_credit_row(entry[0], entry[1]))

	content.add_child(_spacer(40))
	content.add_child(_label("Thanks for playing!", 36))

	# Shoutout
	content.add_child(_spacer(60))
	content.add_child(_label("Special Thanks", 24, Color(0.65, 0.7, 0.8)))
	content.add_child(_label("Brackeys", 40))
	content.add_child(_label("for the assets we used to build our levels", 24, Color(0.65, 0.7, 0.8)))

	# Back button, drawn on top of the credits
	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	back.pressed.connect(_go_back)

func _credit_row(what: String, who: String) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_label(what, 24, Color(0.65, 0.7, 0.8)))
	row.add_child(_label(who, 40))
	return row

func _label(text: String, font_size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func _process(delta: float) -> void:
	if not started:
		return

	var speed := SCROLL_SPEED
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_down"):
		speed *= FAST_MULTIPLIER
	content.position.y -= speed * delta

	# Once the last line has scrolled off the top, go back to the main menu
	if content.position.y + content.size.y < 0.0:
		_go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _go_back() -> void:
	if leaving:
		return
	leaving = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
