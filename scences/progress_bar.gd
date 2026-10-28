extends ProgressBar

func _ready() -> void:
	# Red fill
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d62828")
	add_theme_stylebox_override("fill", fill)

	# Dark background for the empty part of the bar
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2b0a0a")
	add_theme_stylebox_override("background", bg)

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("HealthBar: no node in group 'player' found")
		return
	max_value = player.max_health
	value = player.health
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int) -> void:
	value = new_health
