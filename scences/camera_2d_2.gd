extends Camera2D

func _ready() -> void:
	var tilemap: TileMapLayer = get_tree().current_scene.get_node("TileMapLayer")
	var rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	limit_left = rect.position.x * tile_size.x
	limit_top = rect.position.y * tile_size.y
	limit_right = rect.end.x * tile_size.x
	limit_bottom = rect.end.y * tile_size.y
