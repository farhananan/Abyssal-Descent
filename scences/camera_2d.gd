extends Camera2D

var player: Node2D
var fixed_x: float

func _ready() -> void:
	var tilemap: TileMapLayer = get_tree().current_scene.get_node("TileMapLayer")
	var rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	limit_left = rect.position.x * tile_size.x
	limit_top = rect.position.y * tile_size.y
	limit_right = rect.end.x * tile_size.x
	limit_bottom = rect.end.y * tile_size.y

	# Lock the camera horizontally in the middle of the level
	player = get_parent()
	top_level = true  # stop copying the player's movement; we set the position ourselves
	fixed_x = (limit_left + limit_right) / 2.0
	global_position = Vector2(fixed_x, player.global_position.y)

func _physics_process(_delta: float) -> void:
	# Follow only the player's height; x never changes
	global_position = Vector2(fixed_x, player.global_position.y)
