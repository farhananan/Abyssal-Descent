extends CanvasLayer

const SHOW_TIME := 6.0   # seconds the box stays on screen

# Which hints have already been shown this session (survives scene changes)
var shown := {}

var panel: PanelContainer
var title_label: Label
var body_label: Label
var _tween: Tween

func _ready() -> void:
	layer = 80  # above the game, below the pause menu
	_build_ui()
	panel.hide()

func _build_ui() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 40

	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	body_label = Label.new()
	body_label.add_theme_font_size_override("font_size", 22)
	body_label.custom_minimum_size = Vector2(520, 0)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body_label)

func has_shown(id: String) -> bool:
	return shown.has(id)

# Shows the box the first time this id is used, and does nothing afterwards
func show_once(id: String, title: String, text: String) -> void:
	if shown.has(id):
		return
	shown[id] = true

	title_label.text = title
	body_label.text = text
	panel.show()
	panel.modulate.a = 0.0

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	_tween.tween_callback(panel.hide)
