extends Control

const GAME_TITLE := "ABYSSAL DESCENT"
const SCROLL_SPEED := 90.0        
const FAST_MULTIPLIER := 4.0     
const FOCAL := 600.0              
const HORIZON := 0.12             
const CRAWL_COLOR := Color(1.0, 0.91, 0.12)  
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

var lines: Array = []   
var stars: Array = []
var scroll := 0.0
var started := false
var leaving := false
var _next_z := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_make_stars()
	_build_lines()

	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	back.pressed.connect(_go_back)

	await get_tree().process_frame
	for entry in lines:
		var l: Label = entry["label"]
		l.size = l.get_minimum_size()
		l.pivot_offset = l.size / 2.0
	started = true
	_update_lines()

func _make_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345  # same stars every time
	for i in 160:
		stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"r": rng.randf_range(0.5, 1.6),
			"a": rng.randf_range(0.3, 1.0),
		})

func _build_lines() -> void:
	_add_line(GAME_TITLE, 56, 20)
	_add_line("CREDITS", 34, 70)

	for entry in CREDITS:
		_add_line(entry[0].to_upper(), 22, 8)
		_add_line(entry[1], 40, 52)

	_add_line("THANKS FOR PLAYING!", 36, 90)
	_add_line("SPECIAL THANKS", 22, 8)
	_add_line("Brackeys", 40, 8)
	_add_line("for the assets we used to build our levels", 24, 0)

func _add_line(text: String, font_size: int, gap_after: float) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", CRAWL_COLOR)
	l.add_theme_color_override("font_outline_color", CRAWL_COLOR)
	l.add_theme_constant_override("outline_size", 2)
	l.visible = false
	add_child(l)
	lines.append({"label": l, "z": _next_z})
	_next_z -= font_size * 1.3 + gap_after

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	for s in stars:
		draw_circle(s["pos"] * size, s["r"], Color(1, 1, 1, s["a"]))

func _process(delta: float) -> void:
	if not started:
		return

	var speed := SCROLL_SPEED
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_down"):
		speed *= FAST_MULTIPLIER
	scroll += speed * delta
	_update_lines()

	if lines.back()["z"] + scroll > FOCAL * 4.0:
		_go_back()

func _update_lines() -> void:
	var horizon_y := size.y * HORIZON
	var bottom_y := size.y
	var center_x := size.x / 2.0

	for entry in lines:
		var l: Label = entry["label"]
		var z: float = entry["z"] + scroll  

		if z < -FOCAL * 0.3:
			l.visible = false  
			continue

		var p := FOCAL / (FOCAL + z)  
		var y := horizon_y + (bottom_y - horizon_y) * p

		l.scale = Vector2(p, p)
		l.position = Vector2(center_x, y) - l.pivot_offset
		l.modulate.a = clampf((p - 0.2) / 0.2, 0.0, 1.0)  
		l.visible = l.modulate.a > 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _go_back() -> void:
	if leaving:
		return
	leaving = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
