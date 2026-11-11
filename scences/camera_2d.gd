extends Camera2D

# Extra room (in pixels) added beyond the painted tiles. Raise these if the camera
# stops before the player reaches the top or bottom of the level.
@export var extra_top := 0
@export var extra_bottom := 0

# Prints limits and positions to the Output tab once a second. Turn off when it works.
@export var debug := true

var player: Node2D
var fixed_x := 0.0
var _debug_timer := 0.0

func _ready() -> void:
	_set_limits_from_tilemap()

	# Lock the camera horizontally in the middle of the level
	fixed_x = (limit_left + limit_right) / 2.0

	# Find the player: normally the parent, otherwise look it up by group
	var parent := get_parent()
	if parent is CharacterBody2D:
		player = parent as Node2D
	else:
		await get_tree().process_frame  # the player joins the "player" group in its own _ready
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_warning("Camera: could not find the player (is the Camera2D a child of Test_Player?)")
		return

	top_level = true  # stop copying the player's movement; we set the position ourselves
	global_position = Vector2(fixed_x, player.global_position.y)

func _set_limits_from_tilemap() -> void:
	var tilemap := get_tree().current_scene.get_node_or_null("TileMapLayer") as TileMapLayer
	if tilemap == null:
		push_warning("Camera: no node named TileMapLayer found at the top of the scene")
		return

	var rect := tilemap.get_used_rect()
	var tile_size := Vector2(tilemap.tile_set.tile_size)

	# to_global respects the tilemap's position and scale
	var top_left := tilemap.to_global(Vector2(rect.position) * tile_size)
	var bottom_right := tilemap.to_global(Vector2(rect.end) * tile_size)

	limit_left = int(top_left.x)
	limit_right = int(bottom_right.x)
	limit_top = int(top_left.y) - extra_top
	limit_bottom = int(bottom_right.y) + extra_bottom

	if debug:
		print("Camera limits: left=", limit_left, " right=", limit_right, " top=", limit_top, " bottom=", limit_bottom)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Follow only the player's height; x never changes
	global_position = Vector2(fixed_x, player.global_position.y)

	if debug:
		_debug_timer += delta
		if _debug_timer >= 1.0:
			_debug_timer = 0.0
			print("player_y=", int(player.global_position.y), "  camera_y=", int(get_screen_center_position().y), "  top=", limit_top, " bottom=", limit_bottom)
